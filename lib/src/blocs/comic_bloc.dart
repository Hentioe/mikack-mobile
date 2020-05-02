import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:mikack/models.dart' as models;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';

import 'comic_event.dart';
import 'comic_state.dart';
import '../../store.dart';
import '../values.dart';
import '../ext.dart';

class ComicBloc extends Bloc<ComicEvent, ComicState> {
  final models.Platform platform;
  final models.Comic comic;

  ComicBloc({@required this.platform, @required this.comic});

  @override
  ComicState get initialState => ComicLoadedState(
        tabIndex: 0,
        comic: comic,
        isFavorite: false,
        layoutColumns: defaultChaptersLayoutColumns,
        isShowToolBar: false,
        isShowFavoriteButton: true,
        isShowAppBarTitle: false,
        appBarColor: Colors.white,
      );

  @override
  Stream<ComicState> mapEventToState(ComicEvent event) async* {
    switch (event.runtimeType) {
      case ComicRequestEvent: // 请求漫画信息
        // 读取：是否收藏
        var favorite = await getFavorite(address: comic.url);
        var isFavorite = favorite != null;
        if (favorite != null) // 更新最后阅读时间
          await updateFavorite(favorite..lastReadTime = DateTime.now());
        var reversed = favorite?.isReverseOrder;
        var castedState = state as ComicLoadedState;
        // 读取：是否反转排序
        if (reversed == null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          reversed = prefs.getBool(kChaptersReversed) ?? false;
        }
        // 读取：章节布局（列数）
        var layoutColumns = favorite?.layoutColumns;
        // 读取：已读历史记录
        var readHistories = await findHistories(
            forceDisplayed: false, homeUrl: castedState.comic.url);
        var readHistoryAddresses = readHistories.map((h) => h.address).toList();
        // 读取：上次阅读位置
        var lastReadHistory = await getLastHistory(comic.url);
        var lastReadChapterAddress = lastReadHistory?.address;
        var lastReadAt = lastReadChapterAddress;
        // 响应及时数据（来自本地）
        yield castedState.copyWith(
          isFavorite: isFavorite,
          reversed: reversed,
          readHistoryAddresses: readHistoryAddresses,
          lastReadAt: lastReadAt,
          layoutColumns: layoutColumns,
        );
        // 通过事件响应状态延迟数据（来自远程）
        fetchComic().then((fetchedComic) {
          add(ComicLoadedEvent(comic: fetchedComic));
        }).catchError((_) {
          add(ComicFetchErrorEvent());
        });
        break;
      case ComicLoadedEvent: // 接收装载数据
        var castedEvent = event as ComicLoadedEvent;
        var chaptersCount = castedEvent.comic?.chapters?.length ?? 0;
        yield (state as ComicLoadedState).copyWith(
            comic: castedEvent.comic,
            isShowToolBar: true,
            layoutColumns:
                chaptersCount < 3 && chaptersCount > 0 ? chaptersCount : null);
        break;
      case ComicRetryEvent: // 重试（重新请求远程数据）
        yield (state as ComicLoadedState).copyWith(error: false);
        fetchComic().then((fetchedComic) {
          add(ComicLoadedEvent(comic: fetchedComic));
        }).catchError((_) {
          add(ComicFetchErrorEvent());
        });
        break;
      case ComicFetchErrorEvent: // 加载错误
        yield (state as ComicLoadedState).copyWith(error: true);
        break;
      case ComicTabChangedEvent: // 标签页切换
        var castedEvent = event as ComicTabChangedEvent;
        yield (state as ComicLoadedState).copyWith(tabIndex: castedEvent.index);
        break;
      case ComicReverseEvent: // 反转章节列表排序
        var castedState = state as ComicLoadedState;
        var favorite = await getFavorite(address: castedState.comic.url);
        if (favorite != null) // 如果已收藏，持久化存储设置
          await updateFavorite(
              favorite..isReverseOrder = !castedState.reversed);
        yield castedState.copyWith(reversed: !castedState.reversed);
        break;
      case ComicReadingMarkCleanRequestEvent: // 清空阅读标记
        var castedState = state as ComicLoadedState;
        await deleteHistories(homeUrl: castedState.comic.url);
        add(ComicReadHistoriesUpdateEvent());
        break;
      case ComicFavoriteEvent: // 收藏/取消收藏
        var castedEvent = event as ComicFavoriteEvent;
        var source = await platform.toSavedSource();
        var castedState = state as ComicLoadedState;
        if (!castedEvent.isCancel) {
          // 收藏
          await insertFavorite(Favorite(
            sourceId: source.id,
            name: castedState.comic.title,
            address: castedState.comic.url,
            cover: castedState.comic.cover,
            latestChaptersCount: castedState.comic.chapters?.length ?? 0,
            lastReadTime: DateTime.now(),
          ));
        } else {
          // 取消收藏
          await deleteFavorite(address: castedState.comic.url);
        }
        yield castedState.copyWith(isFavorite: !castedEvent.isCancel);
        break;
      case ComicReadHistoriesUpdateEvent: // 阅读历史更新
        var castedState = state as ComicLoadedState;
        // 读取：已读历史记录
        var readHistories = await findHistories(
            forceDisplayed: false, homeUrl: castedState.comic.url);
        var readHistoryAddresses = readHistories.map((h) => h.address).toList();
        // 读取：上次阅读位置
        var lastReadHistory = await getLastHistory(comic.url);
        var lastReadAt = lastReadHistory?.address ?? '#none#';
        yield (state as ComicLoadedState).copyWith(
            readHistoryAddresses: readHistoryAddresses, lastReadAt: lastReadAt);
        break;
      case ComicReadingMarkUpdateEvent: // 已读标记更新
        var castedEvent = event as ComicReadingMarkUpdateEvent;
        var castedState = state as ComicLoadedState;
        switch (castedEvent.markType) {
          case ComicReadingMarkType.readOne: // 标记已读
            var source = await platform.toSavedSource();
            var history = await getHistory(address: castedEvent.chapter.url);
            if (history == null) {
              await insertHistory(History(
                sourceId: source.id,
                title: castedEvent.chapter.title,
                homeUrl: castedState.comic.url,
                address: castedEvent.chapter.url,
                cover: castedState.comic.cover,
                displayed: false,
              ));
            }
            yield castedState.copyWith(readHistoryAddresses: [
              castedEvent.chapter.url,
              ...castedState.readHistoryAddresses
            ]);
            break;
          case ComicReadingMarkType.readBefore: // 标记之前章节已读
            var chapters = castedEvent.chapters;
            var source = await platform.toSavedSource();
            List<String> addresses = [];
            List<History> histories = [];
            // 一次性查询出所有已存在的历史记录
            var extendedHistoryAddresses = (await findHistories(
                    forceDisplayed: false,
                    addressesIn: chapters.map((c) => c.url).toList()))
                .map((h) => h.address)
                .toList();
            // 剔除已存在的历史
            chapters
                .removeWhere((c) => extendedHistoryAddresses.contains(c.url));
            for (models.Chapter chapter in chapters) {
              histories.add(History(
                sourceId: source.id,
                title: chapter.title,
                homeUrl: castedState.comic.url,
                address: chapter.url,
                cover: castedState.comic.cover,
                displayed: false,
              ));
              addresses.add(chapter.url);
            }
            // 插入新的不显示历史（仅标记已读）
            await insertHistories(histories);
            yield castedState.copyWith(readHistoryAddresses: [
              ...addresses,
              ...castedState.readHistoryAddresses
            ]);
            break;
          case ComicReadingMarkType.unreadOne: // 标记未读
            await deleteHistory(address: castedEvent.chapter.url);
            // 更新上次阅读历史
            add(ComicReadHistoriesUpdateEvent());
            break;
        }
        break;
      case ComicChapterColumnsChangedEvent: // 章节布局变化（列数）
        var castedEvent = event as ComicChapterColumnsChangedEvent;
        var castedState = state as ComicLoadedState;
        var favorite = await getFavorite(address: castedState.comic.url);
        if (favorite != null) // 如果已收藏，持久化存储设置
          await updateFavorite(
              favorite..layoutColumns = castedEvent.layoutColumns);
        yield (state as ComicLoadedState)
            .copyWith(layoutColumns: castedEvent.layoutColumns);
        break;
      case ComicVisibilityUpdateEvent:
        var castedEvent = event as ComicVisibilityUpdateEvent;
        yield (state as ComicLoadedState).copyWith(
          isShowToolBar: castedEvent.showToolBar,
          isShowFavoriteButton: castedEvent.showFavoriteButton,
          isShowAppBarTitle: castedEvent.showAppBarTitle,
        );
        break;

      case ComicAppBarBackgroundChangedEvent:
        var castedEvent = event as ComicAppBarBackgroundChangedEvent;
        yield (state as ComicLoadedState).copyWith(
          appBarColor: castedEvent.color,
        );
        break;
    }
  }

  Future<models.Comic> fetchComic() async {
    var loadedComic =
        await compute(_fetchChaptersTask, Tuple2(platform, comic));
    // 更新已收藏的章节数量
    var favorite = await getFavorite(address: loadedComic.url);
    if (favorite != null) {
      favorite.latestChaptersCount = loadedComic.chapters.length;
      if (loadedComic.cover.isNotEmpty) favorite.cover = loadedComic.cover;
      await updateFavorite(favorite);
    }
    return loadedComic;
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}

models.Comic _fetchChaptersTask(Tuple2<models.Platform, models.Comic> args) {
  var platform = args.item1;
  var comic = args.item2;

  platform.fetchChapters(comic);
  return comic;
}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:executor/executor.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mikack/models.dart';
import 'package:tuple/tuple.dart';
import 'updates_event.dart';
import 'updates_state.dart';

import '../../store/impl.dart';
import '../../store/models.dart';
import '../../widgets/comics_view.dart';
import '../../main.dart';
import '../../ext.dart';

final log = Logger('UpdatesBloc');

class UpdatesBloc extends Bloc<UpdatesEvent, UpdatesState> {
  @override
  UpdatesState get initialState => UpdatesLocalLoadedState(viewItems: const []);

  @override
  Stream<UpdatesState> mapEventToState(UpdatesEvent event) async* {
    switch (event) {
      case UpdatesEvent.localRequest: // 请求本地数据
        var viewItems = await getLocalUpdates();
        yield UpdatesLocalLoadedState(viewItems: viewItems);
        break;
      case UpdatesEvent.remoteRequest: // 请求远程数据
        // 删除已存在的更新记录
        await deleteAllChapterUpdates();
        var favorites = await findFavorites();
        // 输出一个带总数的初始状态
        yield UpdatesRemoteLoadedState(
            viewItems: const [], total: favorites.length);
        // 依次输出全部检查结果
        await for (var viewItem in checkAllUpdates(favorites)) {
          if (viewItem == null)
            yield (state as UpdatesRemoteLoadedState).progressIncrement();
          else
            yield (state as UpdatesRemoteLoadedState).pushWith(viewItem);
        }
        break;
      case UpdatesEvent.stopRefresh: // 停止刷新
        // TODO: 刷新导致流阻塞，无法及时接收事件，待研究和解决
//        yield (state as UpdatesRemoteLoadedState).completedAhead();
        break;
    }
  }

  Future<List<ComicViewItem>> getLocalUpdates() async {
    var favorites = await findFavorites();
    if (favorites.length == 0) return const [];
    var chapterUpdates = await findChapterUpdates();
    List<ComicViewItem> comicViewItems = [];
    for (ChapterUpdate chapterUpdate in chapterUpdates) {
      var filteredFavorites =
          favorites.where((f) => f.address == chapterUpdate.homeUrl);
      if (filteredFavorites.isEmpty) continue;
      var favorite = filteredFavorites.first;
      var countDiff =
          chapterUpdate.chaptersCount - favorite.latestChaptersCount;
      if (favorite != null && countDiff > 0) {
        var source = await getSource(id: favorite.sourceId);
        if (source == null) break;
        var filteredPlatformsList =
            platformList.where((p) => p.domain == source.domain);
        if (filteredPlatformsList.isEmpty) continue;
        var platform = filteredPlatformsList.first;
        var comic = favorite.toComic();
        comic.headers = platform.buildBaseHeaders();
        comicViewItems
            .add(comic.toViewItem(platform: platform, badgeValue: countDiff));
      }
    }
    return comicViewItems;
  }

  Stream<ComicViewItem> checkAllUpdates(List<Favorite> favorites) {
    // 并发检测更新
    final executor = Executor(concurrency: 8);
    var controller = StreamController<ComicViewItem>();
    var counter = 0;
    var outValue = (ComicViewItem viewItem) async {
      controller.add(viewItem);
      counter++;
      if (counter == favorites.length) {
        controller.close();
        log.info('Task output stream is closed.');
        await executor.close();
        // TODO: close 方法导致阻塞，无法执行后续日志输出。原因待调查。
        log.info('Task executor is closed.');
      }
    };
    var outNull = () async => await outValue(null);
    for (var i = 0; i < favorites.length; i++) {
      var favorite = favorites[i];
      executor.scheduleTask(() async {
        var source = await getSource(id: favorite.sourceId);
        if (source == null) {
          await outNull();
          return;
        }
        var platform =
            platformList.firstWhere((p) => p.domain == source.domain);
        try {
          var comic = await compute(
              _fetchChaptersTask, Tuple2(platform, favorite.toComic()));
          var countDiff = comic.chapters.length - favorite.latestChaptersCount;
          if (countDiff > 0) {
            comic.headers = platform.buildBaseHeaders();
            // 插入更新记录
            await insertChapterUpdate(ChapterUpdate(
              comic.url,
              chaptersCount: comic.chapters.length,
            ));
            // 输出结果
            await outValue(
                comic.toViewItem(platform: platform, badgeValue: countDiff));
          } else
            await outNull();
        } catch (_) {
          await outNull();
        }
      });
    }
    return controller.stream;
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}

Comic _fetchChaptersTask(Tuple2<Platform, Comic> args) {
  var platform = args.item1;
  var comic = args.item2;

  platform.fetchChapters(comic);
  return comic;
}

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

  bool _isStopped = false;

  @override
  Stream<UpdatesState> mapEventToState(UpdatesEvent event) async* {
    switch (event.runtimeType) {
      case UpdatesRequestEvent: // 请求类型的事件
        var castedEvent = event as UpdatesRequestEvent;
        switch (castedEvent.type) {
          case UpdatesRequestEventTypes.localRequest: // 请求本地数据
            var viewItems = await getLocalUpdates();
            yield UpdatesLocalLoadedState(viewItems: viewItems);
            break;
          case UpdatesRequestEventTypes.remoteRequest: // 请求远程数据
            _isStopped = false;
            // 删除已存在的更新记录
            await deleteAllChapterUpdates();
            var favorites = await findFavorites();
            // 输出一个带总数的初始状态
            yield UpdatesRemoteLoadedState(
                viewItems: const [], total: favorites.length);
            checkAllUpdates(favorites).forEach((task) {
              task.then((viewItem) {
                if (!_isStopped) add(UpdatesLoadedEvent(viewItem: viewItem));
              });
            });

            break;
          case UpdatesRequestEventTypes.stopRefreshRequest: // 停止刷新
            _isStopped = true;
            yield (state as UpdatesRemoteLoadedState).completedAhead();
            break;
        }
        break;
      case UpdatesLoadedEvent: // 装载数据事件（一般于内部使用）
        var castedEvent = event as UpdatesLoadedEvent;
        if (_isStopped) {
          yield (state as UpdatesRemoteLoadedState).completedAhead();
        } else if (!(state as UpdatesRemoteLoadedState).isCompleted) {
          // 提前完成的状态不应该进入这里
          if (castedEvent.viewItem == null)
            yield (state as UpdatesRemoteLoadedState).progressIncrement();
          else
            yield (state as UpdatesRemoteLoadedState)
                .pushWith(castedEvent.viewItem);
        }
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

  List<Future<ComicViewItem>> checkAllUpdates(List<Favorite> favorites) {
    // 并发检测更新
    final executor = Executor(concurrency: 8);
    var taskList = <Future<ComicViewItem>>[];
    for (var i = 0; i < favorites.length; i++) {
      var favorite = favorites[i];
      var task = executor.scheduleTask(() async {
        if (_isStopped) return null;
        var source = await getSource(id: favorite.sourceId);
        if (source == null) return null;
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
            return comic.toViewItem(platform: platform, badgeValue: countDiff);
          } else
            return null;
        } catch (_) {
          return null;
        }
      });
      taskList.add(task);
    }

    return taskList;
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

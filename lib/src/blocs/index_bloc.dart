import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'package:mikack/models.dart' as models;

import 'index_event.dart';
import 'index_state.dart';
import '../widget/comics_view.dart';
import '../ext.dart';

class IndexBloc extends Bloc<IndexEvent, IndexState> {
  final models.Platform platform;

  Map<String, String> httpHeaders;

  IndexBloc(this.platform) {
    this.httpHeaders = platform.buildBaseHeaders();
  }

  @override
  IndexState get initialState => IndexLoadedState(
        comicViewItems: const [],
        isFetching: true,
        isViewList: false,
      );

  @override
  Stream<IndexState> mapEventToState(IndexEvent event) async* {
    switch (event.runtimeType) {
      case IndexRequestEvent: // 请求漫画索引
        var castedEvent = event as IndexRequestEvent;
        yield (state as IndexLoadedState).copyWith(
          error: false,
          isFetching: true,
          currentPage: castedEvent.page,
          currentKeywords: '',
          // 清空关键字（当前通过关键字是否为空判断发送搜索还是索引请求）
          comicViewItems: castedEvent.page == 1 ? const [] : null, // 第一页则清空之前数据
        );
        getComics(castedEvent.page).then((comicViewItems) {
          add(IndexLoadedEvent(comicViewItems: comicViewItems));
        }).catchError((e) {
          add(IndexErrorOccurredEvent(message: e.toString()));
        });
        break;
      case IndexSearchEvent: // 请求漫画搜索
        var castedEvent = event as IndexSearchEvent;
        yield (state as IndexLoadedState).copyWith(
          error: false,
          isFetching: true,
          currentPage: castedEvent.page,
          currentKeywords: castedEvent.keywords,
          comicViewItems: castedEvent.page == 1 ? const [] : null, // 第一页则清空之前数据
        );
        searchComics(castedEvent.keywords, castedEvent.page)
            .then((comicViewItems) {
          add(IndexLoadedEvent(comicViewItems: comicViewItems));
        });
        break;
      case IndexErrorOccurredEvent: // 错误发生
        var castedEvent = event as IndexErrorOccurredEvent;
        yield (state as IndexLoadedState).copyWith(
          error: true,
          errorMessage: castedEvent.message,
        );
        break;
      case IndexLoadedEvent: // 数据装载完成
        var castedEvent = event as IndexLoadedEvent;
        var castedState = state as IndexLoadedState;
        yield castedState.copyWith(isFetching: false, comicViewItems: [
          ...castedState.comicViewItems,
          ...castedEvent.comicViewItems
        ]);
        break;
      case IndexViewModeChangedEvent: // 显示模式改变
        var castedEvent = event as IndexViewModeChangedEvent;
        yield (state as IndexLoadedState)
            .copyWith(isViewList: castedEvent.isViewList);
        break;
    }
  }

  Future<List<ComicViewItem>> getComics(int page) async {
    var comics = await compute(_getComicsTask, Tuple2(platform, page));
    comics.forEach((c) => c.headers = httpHeaders);
    return comics.toViewItems();
  }

  Future<List<ComicViewItem>> searchComics(String keywords, int page) async {
    try {
      var comics =
          await compute(_searchComicsTask, Tuple3(platform, keywords, page));
      comics.forEach((c) => c.headers = httpHeaders);
      return comics.toViewItems();
    } catch (e) {
      return const [];
    }
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}

List<models.Comic> _getComicsTask(Tuple2<models.Platform, int> args) {
  var platform = args.item1;
  var page = args.item2;
  return platform.index(page);
}

List<models.Comic> _searchComicsTask(
    Tuple3<models.Platform, String, int> args) {
  var platform = args.item1;
  var keywords = args.item2;
  var page = args.item3;
  return platform.paginatedSearch(keywords, page);
}

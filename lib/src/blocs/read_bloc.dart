import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:mikack/models.dart' as models;
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

import 'read_event.dart';
import 'read_state.dart';
import '../helper/compute_ext.dart';
import '../../store.dart';
import '../ext.dart';

class ReadBloc extends Bloc<ReadEvent, ReadState> {
  final models.Platform platform;
  final models.Comic comic;

  ReadBloc({
    @required this.platform,
    @required this.comic,
  });

  @override
  ReadState get initialState => ReadLoadedState(
        isShowToolbar: false,
        isLoading: true,
        currentPage: 0,
        pages: const [],
      );

  @override
  Stream<ReadState> mapEventToState(ReadEvent event) async* {
    switch (event.runtimeType) {
      case ReadCreatePageIteratorEvent: // 创建迭代器
        var castedEvent = event as ReadCreatePageIteratorEvent;
        _createPageIterator(platform, castedEvent.chapter)
            .then((createdPageIterator) {
          add(ReadChapterLoadedEvent(
            chapter: createdPageIterator.item2,
            pageIterator: createdPageIterator.item1.asPageIterator(),
          ));
        }).catchError((e) {
          print(e);
        });
        break;
      case ReadChapterLoadedEvent: // 章节数据装载
        var castedEvent = event as ReadChapterLoadedEvent;
        yield (state as ReadLoadedState).copyWith(
          isLoading: false,
          chapter: castedEvent.chapter,
          pageIterator: castedEvent.pageIterator,
        );
        // 载入第一页
        add(ReadNextPageEvent(page: 1));
        // 添加到阅读历史
        addHistory(castedEvent.chapter);
        break;
      case ReadNextPageEvent: // 请求下一页
        var castedEvent = event as ReadNextPageEvent;
        var stateSnapshot = state as ReadLoadedState;
        if (castedEvent.page > stateSnapshot.pages.length) {
          // 载入下一页
          _fetchNextPage(stateSnapshot.pageIterator).then((address) {
            add(ReadPageLoadedEvent(page: address));
          }).catchError((e) {
            // TODO: 响应翻页错误
            print(e);
          });
        }
        // 修改页码
        yield stateSnapshot.copyWith(
            currentPage: stateSnapshot.currentPage + 1);
        break;
      case ReadPrevPageEvent: // 请求上一页
        var stateSnapshot = state as ReadLoadedState;
        yield stateSnapshot.copyWith(
            currentPage: stateSnapshot.currentPage - 1);
        break;
      case ReadPageLoadedEvent: // 页面数据装载
        var castedEvent = event as ReadPageLoadedEvent;
        var castedState = state as ReadLoadedState;
        yield castedState
            .copyWith(pages: [...castedState.pages, castedEvent.page]);
        break;
    }
  }

  // 添加阅读历史
  Future<void> addHistory(models.Chapter chapter) async {
    var history = await getHistory(address: chapter.url);
    if (history != null) {
      // 如果存在阅读历史，仅更新（并强制可见）
      history.title = chapter.title;
      history.homeUrl = comic.url;
      history.cover = comic.cover;
      history.displayed = true;
      await updateHistory(history);
    } else {
      // 创建阅读历史
      var source = await platform.toSavedSource();
      var history = History(
        sourceId: source.id,
        title: chapter.title,
        homeUrl: comic.url,
        address: chapter.url,
        cover: comic.cover,
        displayed: true,
      );
      await insertHistory(history);
    }
  }

  Future<Tuple2<ValuePageIterator, models.Chapter>> _createPageIterator(
    models.Platform platform,
    models.Chapter chapter,
  ) async {
    return await compute(_createPageIteratorTask, Tuple2(platform, chapter));
  }

  final lock = Lock(); // 同步调用迭代器（当前必须）

  Future<String> _fetchNextPage(models.PageIterator pageIterator) async {
    return lock.synchronized(() async {
      return await compute(
          _getNextAddressTask, pageIterator.asValuePageIterator());
    });
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}

Tuple2<ValuePageIterator, models.Chapter> _createPageIteratorTask(
    Tuple2<models.Platform, models.Chapter> args) {
  var platform = args.item1;
  var chapter = args.item2;

  var pageIterator = platform.createPageIter(chapter);

  return Tuple2(
    ValuePageIterator(
      pageIterator.createdIterPointer.address,
      pageIterator.iterPointer.address,
    ),
    chapter,
  );
}

String _getNextAddressTask(ValuePageIterator valuePageIterator) {
  return valuePageIterator.asPageIterator().next();
}

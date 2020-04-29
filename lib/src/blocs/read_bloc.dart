import 'dart:isolate';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/src/models.dart';
import 'package:quiver/iterables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

import 'read_event.dart';
import 'read_state.dart';
import '../helper/compute_ext.dart';
import '../../store.dart';
import '../ext.dart';
import '../values.dart';
import '../exceptions.dart';

final _log = Logger('ReadBloc');

class ReadBloc extends Bloc<ReadEvent, ReadState> {
  final models.Platform platform;
  final models.Comic comic;
  final int chapterReadAt;

  ReadBloc({
    @required this.platform,
    @required this.comic,
    @required this.chapterReadAt,
  });

  @override
  ReadState get initialState => ReadLoadedState(
        readingMode: ReadingModeType.leftToRight,
        isLeftHandMode: false,
        isShowToolbar: false,
        isLoading: true,
        preCaching: true,
        preLoading: defaultPreLoading,
        chapterReadAt: chapterReadAt,
        currentPage: 0,
        pages: const [],
      );

  ReceivePort _nextPageResultPort; // 留下 port 用以通信释放迭代器
  bool _pageIteratorIsFreed = false;

  @override
  Stream<ReadState> mapEventToState(ReadEvent event) async* {
    switch (event.runtimeType) {
      case ReadSettingsRequestEvent: // 载入设置
        SharedPreferences prefs = await SharedPreferences.getInstance();
        // 读取：阅读模式
        var readingModeKey = prefs.getString(kReadingMode);
        var readingMode = readingModeKey != null
            ? ReadingModeItem(readingModeKey).type()
            : null;
        // 读取：预加载页面
        var preLoading = prefs.getInt(kPreLoading);
        // 读取：预缓存图片
        var preCaching = prefs.getBool(kPreCaching);
        // 读取：是否启用左手模式
        var isLeftHandMode = prefs.getBool(kLeftHandMode);
        yield (state as ReadLoadedState).copyWith(
          readingMode: readingMode,
          isLeftHandMode: isLeftHandMode,
          preLoading: preLoading,
          preCaching: preCaching,
        );
        break;
      case ReadCreatePageIteratorEvent: // 创建迭代器
        _pageIteratorIsFreed = false;
        var castedEvent = event as ReadCreatePageIteratorEvent;
        // 清除迭代器错误并初始化数据
        yield (state as ReadLoadedState).copyWith(
          createIteratorError: noneError,
          isShowToolbar: false,
          isLoading: true,
          currentPage: 0,
          preFetchAt: 0,
          chapterReadAt: castedEvent.chapterReadAt,
          pages: const [],
        );
        // 创建页面迭代器
        _createPageIterator(platform, castedEvent.chapter)
            .then((createdPageIterator) {
          add(ReadChapterLoadedEvent(
            chapterReadAt: castedEvent.chapterReadAt,
            pageIterator: createdPageIterator.item1.asPageIterator(),
            chapter: createdPageIterator.item2,
          ));
        }).catchError((e) {
          add(ReadCreatePageIteratorFailedEvent(message: e.toString()));
        });
        break;
      case ReadCreatePageIteratorFailedEvent: // 创建页面迭代器失败
        var castedEvent = event as ReadCreatePageIteratorFailedEvent;
        yield (state as ReadLoadedState).copyWith(
            isLoading: false,
            createIteratorError: ErrorWrapper.message(castedEvent.message));
        break;
      case ReadChapterLoadedEvent: // 章节数据装载
        var castedEvent = event as ReadChapterLoadedEvent;
        // 写入阅读历史
        var history = await writeToHistories(castedEvent.chapter);
        var lastReadPage = history.lastReadPage ?? 1;
        yield (state as ReadLoadedState).copyWith(
          createIteratorError: noneError,
          isLoading: false,
          chapterReadAt: castedEvent.chapterReadAt,
          chapter: castedEvent.chapter,
          pageIterator: castedEvent.pageIterator,
        );
        if (lastReadPage > 1) {
          // 存在上次阅读记录，直接跳页
          yield (state as ReadLoadedState).copyWith(continuePage: lastReadPage);
        } else {
          // 载入第一页
          add(ReadNextPageEvent(
              page: 1, preLoading: (state as ReadLoadedState).preLoading));
        }
        break;
      case ReadNextPageEvent: // 请求下一页
        var castedEvent = event as ReadNextPageEvent;
        var stateSnapshot = state as ReadLoadedState;
        if (castedEvent.page > stateSnapshot.pages.length ||
            (castedEvent.page > stateSnapshot.preFetchAt - 1)) {
          // 载入后续页面（包括预加载）
          for (var i in range(castedEvent.preLoading + 1)) {
            if ((stateSnapshot.preFetchAt + 1 <=
                    stateSnapshot.chapter.pageCount) &&
                (stateSnapshot.preFetchAt <=
                    stateSnapshot.currentPage + stateSnapshot.preLoading)) {
              // 自增预加载位置
              stateSnapshot = stateSnapshot.copyWith(
                  preFetchAt: stateSnapshot.preFetchAt + 1);
              yield stateSnapshot;
              // 获取下一页
              _fetchNextPage(stateSnapshot.pageIterator).then((address) {
                add(ReadPageLoadedEvent(
                    pageNum: stateSnapshot.currentPage + 1 + i, page: address));
              }).catchError((e) {
                // TODO: 响应翻页错误
                print(e);
              });
            }
          }
        }
        // 修改页码
        yield stateSnapshot.copyWith(
            currentPage: stateSnapshot.currentPage + 1);
        break;
      case ReadMakeUpPageEvent: // 弥补空缺页面（无预加载）
        var castedEvent = event as ReadMakeUpPageEvent;
        var stateSnapshot = state as ReadLoadedState;
        // 载入下一页
        if (stateSnapshot.preFetchAt < castedEvent.page) {
          var isMakeUp = castedEvent.page != stateSnapshot.currentPage;
          _fetchNextPage(stateSnapshot.pageIterator).then((address) {
            add(ReadPageLoadedEvent(
                pageNum: castedEvent.page, page: address, isMakeUp: isMakeUp));
          }).catchError((e) {
            // TODO: 响应翻页错误
            print(e);
          });
          yield stateSnapshot.copyWith(preFetchAt: castedEvent.page);
        }
        break;
      case ReadPrevPageEvent: // 请求上一页
        var stateSnapshot = state as ReadLoadedState;
        yield stateSnapshot.copyWith(
            currentPage: stateSnapshot.currentPage - 1);
        break;
      case ReadPageLoadedEvent: // 页面数据装载
        var castedEvent = event as ReadPageLoadedEvent;
        var castedState = state as ReadLoadedState;
        bool preCaching;
        if (castedEvent.isMakeUp ?? false)
          preCaching = false; // 如果是弥补空缺页面则不进行预缓存
        yield castedState.copyWith(
            preCaching: preCaching,
            pages: [...castedState.pages, castedEvent.page]);
        break;
      case ReadToolbarDisplayStatusChangedEvent: // 工具栏显示状态改变
        var stateSnapshot = state as ReadLoadedState;
        yield stateSnapshot.copyWith(
            isShowToolbar: !stateSnapshot.isShowToolbar);
        break;
      case ReadCurrentPageForceChangedEvent: // 强制修改当前页码
        var castedEvent = event as ReadCurrentPageForceChangedEvent;
        yield (state as ReadLoadedState)
            .copyWith(currentPage: castedEvent.page);
        break;
      case ReadFreeEvent: // 释放迭代器
        clearGestureDetailsCache(); // 清除手势缓存（很重要，否则会造成严重的内存泄漏）
        // 记录上次阅读页面
        var history =
            await getHistory(address: (state as ReadLoadedState).chapter.url);
        if (history != null) {
          history.lastReadPage = (state as ReadLoadedState).currentPage;
          await updateHistory(history);
        }
        // 释放迭代器内存
        _pageIteratorIsFreed = true;
        var castedEvent = event as ReadFreeEvent;
        if (castedEvent.pageIterator != null) {
          if (_nextPageResultPort != null) {
            // 以通信的方式安全释放迭代器内存（注意，需要保证迭代器 API 非并发调用）
            var destroyCommand = Tuple2(ComputeController.destroyCommand,
                castedEvent.pageIterator.asValuePageIterator());
            _nextPageResultPort.sendPort.send(destroyCommand);
          } else {
            // 直接释放迭代器内存
            castedEvent.pageIterator.free();
            _log.info('Iterator is freed');
          }
        }
        break;
      case ReadJumpProgressUpdatedEvent: // 跳页进度更新
        var castedEvent = event as ReadJumpProgressUpdatedEvent;
        yield (state as ReadLoadedState)
            .copyWith(jumpProgress: castedEvent.value);
        break;
      case ReadForceStoppedJumpingChangedEvent: // 强制停止跳转
        var castedEvent = event as ReadForceStoppedJumpingChangedEvent;
        yield (state as ReadLoadedState)
            .copyWith(forceStopped: castedEvent.stopped);
        break;
    }
  }

  // 添加或更新阅读历史
  Future<History> writeToHistories(models.Chapter chapter) async {
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
      history = History(
        sourceId: source.id,
        title: chapter.title,
        homeUrl: comic.url,
        address: chapter.url,
        cover: comic.cover,
        displayed: true,
      );
      await insertHistory(history);
    }

    return history;
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
      if (_pageIteratorIsFreed)
        throw PageIteratorException('Iterator is freed');
      var controller = await createComputeController(
          _getNextAddressTask, pageIterator.asValuePageIterator());
      _nextPageResultPort = controller.resultPort;
      var address = await controllableCompute(controller);
      _nextPageResultPort = null;
      return address;
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

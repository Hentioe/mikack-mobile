import 'dart:isolate';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:logging/logging.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/helper/chrome.dart';
import 'package:mikack_mobile/helper/compute_ext.dart';
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:mikack_mobile/pages/settings.dart';
import 'package:mikack_mobile/store/impl/history_api.dart';
import 'package:mikack_mobile/store/models.dart';
import 'package:mikack_mobile/widgets/outline_text.dart';
import 'package:mikack_mobile/widgets/text_hint.dart';
import 'package:mikack_mobile/ext.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';

final log = Logger('Read2Page');
const read2PageBackgroundColor = Color.fromARGB(255, 50, 50, 50);
const _pageInfoTextColor = Color.fromARGB(255, 255, 255, 255);
const _pageInfoOutlineColor = Color.fromARGB(255, 0, 0, 0);
const _pageInfoFontSize = 13.0;
const _spinkitSize = 35.0;
const _connectionIndicatorColor = Color.fromARGB(255, 138, 138, 138);

enum ChapterPreviewDirection { prev, next }

class _Read2Page extends StatefulWidget {
  _Read2Page({
    this.platform,
    this.comic,
    this.chapter,
    this.prevChapter,
    this.nextChapter,
  });

  final models.Platform platform;
  final models.Comic comic;
  final models.Chapter chapter;
  final models.Chapter prevChapter;
  final models.Chapter nextChapter;

  @override
  State<StatefulWidget> createState() => _Read2PageState();
}

class _Read2PageState extends State<_Read2Page> {
  bool _loading = true;
  models.Chapter _chapter;
  models.PageIterator _pageIterator;
  List<String> _pages = [];
  int _currentPage = 1;
  PageController pageController;
  bool _leftHandMode = false;

  @override
  void initState() {
    createPageIterator();
    fetchLeftHandMode();
    super.initState();
  }

  @override
  void dispose() {
    if (_pageIterator != null) {
      if (nextResultPort != null) {
        // 以通信的方式安全释放迭代器内存（注意，需要保证迭代器 API 非并发调用）
        nextResultPort.sendPort.send(Tuple2(ComputeController.destroyCommand,
            _pageIterator.asValuePageIterator()));
        nextResultPort = null;
      } else {
        // 直接释放迭代器内存
        _pageIterator.free();
        log.info('Iterator is freed');
      }
    }
    pageController?.dispose();
    clearGestureDetailsCache();
    super.dispose();
  }

  // 加载左手模式设置
  void fetchLeftHandMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var leftHandMode = prefs.getBool(leftHandModeKey);
    if (leftHandMode == null) leftHandMode = false;
    setState(() => _leftHandMode = leftHandMode);
  }

  void handlePageChange(int page) {
    if (page == _currentPage || page == 0 || page == _chapter.pageCount + 1)
      return;
    if (page > _currentPage)
      handleNext();
    else
      handlePrev();
  }

  // 添加阅读历史
  void addHistory(models.Chapter chapter) async {
    var history = await getHistory(address: chapter.url);
    if (history != null) {
      // 如果存在阅读历史，仅更新（并强制可见）
      history.title = chapter.title;
      history.homeUrl = widget.comic.url;
      history.cover = widget.comic.cover;
      history.displayed = true;
      await updateHistory(history);
    } else {
      // 创建阅读历史
      var source = await widget.platform.toSavedSource();
      var history = History(
        sourceId: source.id,
        title: chapter.title,
        homeUrl: widget.comic.url,
        address: chapter.url,
        cover: widget.comic.cover,
        displayed: true,
      );
      await insertHistory(history);
    }
  }

  void createPageIterator() async {
    var created = await compute(
        _createPageIteratorTask, Tuple2(widget.platform, widget.chapter));
    // 初始化页面控制器（未来会根据历史记录跳转页码）
    pageController = PageController(initialPage: _currentPage);
    if (!mounted) {
      created.item1.asPageIterator().free();
      log.info('Iterator is freed');
      pageController.dispose();
      return;
    }
    // 迭代器创建完成隐藏系统 UI
    hiddenSystemUI();
    setState(() {
      _pageIterator = created.item1.asPageIterator();
      _chapter = created.item2;
      _loading = false;
      addHistory(_chapter);
    });
    // 加载第一页
    fetchNextPage();
  }

  final lock = Lock(); // 同步调用迭代器（必须）
  ReceivePort nextResultPort; // 留下 port 用以通信释放内存

  void fetchNextPage({preCount = 2}) async {
    // 同步资源下载和地址池写入
    if (!mounted) return;
    await lock.synchronized(() async {
      if (!mounted) return;
      if (_pages.length >= _chapter.pageCount) return;
      var controller = await createComputeController(
          _getNextAddressTask, _pageIterator.asValuePageIterator());
      nextResultPort = controller.resultPort;
      var address = await controllableCompute(controller);
      nextResultPort = null;
      if (!mounted) return;
      setState(() => _pages.add(address));
      // 预缓存图片资源
      precacheImage(
        ExtendedImage.network(
          address,
          headers: _chapter.pageHeaders,
          cache: true,
        ).image,
        context,
      );
    });
    // 预加载（递归并递减预下载次数）
    if (preCount > 0) fetchNextPage(preCount: --preCount);
  }

  void handlePrev() {
    if (_currentPage <= 1) return;
    // 直接修改页码
    setState(() {
      _currentPage--;
    });
  }

  void handleNext() {
    var currentCount = _pages.length;
    if (_currentPage == _chapter.pageCount) return;
    if (_currentPage < currentCount) {
      // 加载并预下载
      if ((_currentPage + 1) == currentCount) fetchNextPage();
    } else {
      // 超出已加载数量，无预加载按页加载
      fetchNextPage(preCount: 0); // 加载页面
    }
    setState(() {
      _currentPage++;
    });
  }

  animateToPage(page) {
    pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 80),
      curve: Curves.easeInCubic,
    );
  }

  animateNextPage() {
    pageController.nextPage(
      duration: Duration(milliseconds: 80),
      curve: Curves.easeInCubic,
    );
  }

  animatePrevPage() {
    pageController.previousPage(
      duration: Duration(milliseconds: 80),
      curve: Curves.easeInCubic,
    );
  }

  void _handleTapUp(TapUpDetails details, BuildContext context) {
    if (_loading) return;
    var centerLocation = MediaQuery.of(context).size.width / 2; // 取屏幕的一半长度
    var x = details.globalPosition.dx;

    if (centerLocation > x) {
      // 左屏幕（默认上一页，左手模式相反）
      if (_leftHandMode)
        animateNextPage();
      else
        animatePrevPage();
    } else {
      // 右屏幕（默认下一页，左手模式相反）
      if (_leftHandMode)
        animatePrevPage();
      else
        animateNextPage();
    }
  }

  // 构建页码信息视图
  Widget _buildPageInfoView() {
    var pageInfo =
        _chapter == null ? '' : '$_currentPage/${_chapter.pageCount}';
    return Positioned(
      bottom: 2,
      left: 0,
      right: 0,
      child: Container(
        child: Center(
          child: OutlineText(
            pageInfo,
            fontSize: _pageInfoFontSize,
            textColor: _pageInfoTextColor,
            outlineColor: _pageInfoOutlineColor,
          ),
        ),
      ),
    );
  }

  // 原图片请求中的加载动画，现暂时无用
  //  final connectingIndicator = SpinKitWave(
  //    color: _connectionIndicatorColor,
  //    size: _spinkitSize,
  //  );

  Widget _buildImageView(String address) {
    return ExtendedImage.network(
      address,
      headers: _chapter.pageHeaders,
      fit: BoxFit.contain,
      cache: true,
      mode: ExtendedImageMode.gesture,
      initGestureConfigHandler: (state) {
        var img = state.extendedImageInfo.image;
        var screenSize = MediaQuery.of(context).size;
        var maxScale = 4.5;
        var initialScale = 1.0;
        var animationMaxScale = 5.5;
        // 如果图片的长：宽比例大于屏幕长：宽比例，则设置独特的缩放值
        // 屏幕：长-3 宽-1
        // 图片：长-5 宽-1
        // (3/1) < (5/1)
        if ((screenSize.height / screenSize.width) < (img.height / img.width)) {
          // 计算放大多少倍宽度占满屏幕宽度
          initialScale =
              screenSize.width / (img.width / (img.height / screenSize.height));
          maxScale = initialScale + 1.0;
          animationMaxScale = maxScale + 1.0;
        }
        return GestureConfig(
          minScale: 1.0,
          animationMinScale: 0.7,
          maxScale: maxScale,
          animationMaxScale: animationMaxScale,
          speed: 1.0,
          inertialSpeed: 100.0,
          initialScale: initialScale,
          inPageView: true,
          initialAlignment: InitialAlignment.topCenter,
          cacheGesture: true,
        );
      },
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Center(
              child: const CircularProgressIndicator(),
            );
            break;
          case LoadState.failed:
            return Center(
              child: RaisedButton(
                  child: Text('重试'), onPressed: () => state.reLoadImage()),
            ); // 加载失败显示标题文本
            break;
          default:
            return null;
            break;
        }
      },
    );
  }

  final connectingView = const SpinKitPouringHourglass(
      color: _connectionIndicatorColor, size: _spinkitSize);

  final chapterInfoHeaderStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.bold,
    color: Colors.grey[400],
  );
  final chapterInfoStyle = TextStyle(
    fontSize: 18,
    color: Colors.grey[400],
    decoration: TextDecoration.underline,
  );

  Widget _buildPreviewChapter(ChapterPreviewDirection direction) {
    var directionText;
    var previewChapter;
    switch (direction) {
      case ChapterPreviewDirection.prev:
        directionText = '上';
        previewChapter = widget.prevChapter;
        break;
      case ChapterPreviewDirection.next:
        directionText = '下';
        previewChapter = widget.nextChapter;
        break;
    }
    if (previewChapter == null)
      return Center(
        child: Text('无$directionText一章节信息', style: chapterInfoHeaderStyle),
      );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$directionText一章：', style: chapterInfoHeaderStyle),
        SizedBox(height: 10),
        MaterialButton(
          child: Text(previewChapter.title, style: chapterInfoStyle),
          onPressed: () => Navigator.pop(context, previewChapter),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        backgroundColor: read2PageBackgroundColor,
        resizeToAvoidBottomInset: _loading,
        body: _loading
            ? TextHint('载入中…')
            : Stack(
                children: [
                  Positioned.fill(
                    child: ExtendedImageGesturePageView.builder(
                      controller: pageController,
                      itemCount: _chapter.pageCount + 2,
                      itemBuilder: (ctx, index) {
                        if (index == 0) {
                          // 上一章
                          return _buildPreviewChapter(
                              ChapterPreviewDirection.prev);
                        } else if (index == _chapter.pageCount + 1) {
                          // 下一章
                          return _buildPreviewChapter(
                              ChapterPreviewDirection.next);
                        } else if (index - 1 >= _pages.length) {
                          return Center(child: connectingView);
                        } else {
                          return _buildImageView(_pages[index - 1]);
                        }
                      },
                      onPageChanged: handlePageChange,
                    ),
                  ),
                  _buildPageInfoView(),
                ],
              ),
      ),
      onTapUp: (detail) => _handleTapUp(detail, context),
    );
  }
}

class Read2Page extends BasePage {
  Read2Page({
    this.platform,
    this.comic,
    this.chapter,
    this.prevChapter,
    this.nextChapter,
  });

  final models.Platform platform;
  final models.Comic comic;
  final models.Chapter chapter;
  final models.Chapter prevChapter;
  final models.Chapter nextChapter;

  @override
  Widget build(BuildContext context) => _Read2Page(
        platform: platform,
        comic: comic,
        chapter: chapter,
        prevChapter: prevChapter,
        nextChapter: nextChapter,
      );
}

String _getNextAddressTask(ValuePageIterator valuePageIterator) {
  return valuePageIterator.asPageIterator().next();
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

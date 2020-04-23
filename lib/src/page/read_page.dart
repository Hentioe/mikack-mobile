import 'package:extended_image/extended_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mikack/models.dart' as models;
import 'package:quiver/iterables.dart';

import '../models.dart';
import '../helper/chrome.dart';
import '../blocs.dart';
import '../widget/outline_text.dart';
import '../widget/text_hint.dart';

enum ChapterPreviewDirection { prev, next }

const _mainBackgroundColor = Color.fromARGB(255, 40, 40, 40);
const _pageInfoTextColor = Color.fromARGB(255, 255, 255, 255);
const _pageInfoOutlineColor = Color.fromARGB(255, 0, 0, 0);
const _pageInfoFontSize = 13.0;
const _connectionIndicatorSize = 35.0;
const _connectingIndicatorColor = Color.fromARGB(255, 115, 115, 115);
final _toolBarBackgroundColor = _mainBackgroundColor.withAlpha(160);

class ReadPage extends StatefulWidget {
  final models.Platform platform;
  final models.Comic comic;
  final List<models.Chapter> chapters;
  final int initChapterReadAt;

  ReadPage({
    @required this.platform,
    @required this.comic,
    @required this.chapters,
    @required this.initChapterReadAt,
  });

  @override
  State<StatefulWidget> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  ReadBloc bloc;

  PageController _pageController;
  ScrollController _scrollController;
  var pageSizes = <int, double>{};

  @override
  void initState() {
    bloc = ReadBloc(
      platform: widget.platform,
      comic: widget.comic,
      chapterReadAt: widget.initChapterReadAt,
    );
    // 创建页面迭代器
    bloc.add(ReadCreatePageIteratorEvent(
      chapterReadAt: widget.initChapterReadAt,
      chapter: widget.chapters[widget.initChapterReadAt],
    ));
    // 读取设置
    bloc.add(ReadSettingsRequestEvent());
    super.initState();
  }

  @override
  void dispose() {
    var stateSnapshot = bloc.state as ReadLoadedState;
    // 释放迭代器
    bloc.add(ReadFreeEvent(pageIterator: stateSnapshot.pageIterator));
    bloc.close();
    _pageController?.dispose();
    super.dispose();
  }

  void _handleSliderChange(double value) {
    var page = value.toInt();
    var stateSnapshot = bloc.state as ReadLoadedState;
    // 跳转页面
    _pageController?.jumpToPage(page);
    if (_scrollController != null) {
      // 叠加之前页的总长度
      var offset = pageSizes.entries
          .where((entry) => entry.key <= page)
          .map((entry) => entry.value)
          .reduce((a, b) => a + b);
      _scrollController.jumpTo(offset);
    }
    bloc.add(ReadCurrentPageForceChangedEvent(page: page));
    if (page > stateSnapshot.preFetchAt) // 非滑动过渡页面，直接跳转页码，自动加载中间空白页面
      for (var i in range(page - stateSnapshot.preFetchAt)) {
        bloc.add(
          ReadMakeUpPageEvent(page: stateSnapshot.preFetchAt + i + 1),
        );
      }
  }

  void _handlePageChange(int page) {
    var stateSnapshot = bloc.state as ReadLoadedState;
    // 过滤掉非页面页码
    if (page == stateSnapshot.currentPage ||
        page == 0 ||
        page == stateSnapshot.chapter.pageCount + 1) return;
    if (page > stateSnapshot.currentPage) {
      // 下一页
      bloc.add(ReadNextPageEvent(
          page: stateSnapshot.currentPage + 1,
          preLoading: stateSnapshot.preLoading));
    } else {
      // 上一页
      bloc.add(ReadPrevPageEvent());
    }
  }

  _animateNextPage() {
    _pageController?.nextPage(
      duration: Duration(milliseconds: 80),
      curve: Curves.easeInCubic,
    );
    if (_scrollController != null) {
      var stateSnapshot = bloc.state as ReadLoadedState;
      // 叠加当前页的总长度
      var offset = pageSizes.entries
          .where((entry) => entry.key <= stateSnapshot.currentPage)
          .map((entry) => entry.value)
          .reduce((a, b) => a + b);
      _scrollController.animateTo(offset,
          duration: Duration(milliseconds: 80), curve: Curves.easeInCubic);
    }
  }

  _animatePrevPage() {
    var stateSnapshot = bloc.state as ReadLoadedState;
    _pageController?.previousPage(
      duration: Duration(milliseconds: 80),
      curve: Curves.easeInCubic,
    );
    if (_scrollController != null) {
      // 叠加之前页的总长度
      var offset = 0.0;
      if (stateSnapshot.currentPage > 2)
        offset = pageSizes.entries
            .where((entry) => entry.key < stateSnapshot.currentPage - 1)
            .map((entry) => entry.value)
            .reduce((a, b) => a + b);
      _scrollController.animateTo(offset,
          duration: Duration(milliseconds: 80), curve: Curves.easeInCubic);
    }
  }

  void _handleGlobalTapUp(TapUpDetails details) {
    var stateSnapshot = bloc.state as ReadLoadedState;
    if (stateSnapshot.isLoading) return;
    var centerX = MediaQuery.of(context).size.width / 2;
    var centerY = MediaQuery.of(context).size.height / 2;
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;

    // 中下区域（显示翻页工具栏）
    if (y > centerY && x > centerX - 100 && x < centerX + 100) {
      bloc.add(ReadToolbarDisplayStatusChangedEvent());
      return;
    }
    // 切换页面
    if (centerX > x) {
      // 左屏幕（默认上一页，左手模式相反）
      if (stateSnapshot.isLeftHandMode)
        _animateNextPage();
      else
        _animatePrevPage();
    } else {
      // 右屏幕（默认下一页，左手模式相反）
      if (stateSnapshot.isLeftHandMode)
        _animatePrevPage();
      else
        _animateNextPage();
    }
  }

  Widget _buildImageView({
    @required Map<String, String> httpHeaders,
    @required String address,
    @required bool inPageView,
  }) {
    return ExtendedImage.network(
      address,
      headers: httpHeaders,
      fit: BoxFit.contain,
      cache: true,
      mode: ExtendedImageMode.gesture,
      initGestureConfigHandler: (state) {
        var img = state.extendedImageInfo.image;
        var screenSize = MediaQuery.of(context).size;
        var maxScale = 4.5;
        var initialScale = 1.0;
        var screenHeight = screenSize.height;
        // 如果图片的长：宽比例大于屏幕长：宽比例，则设置独特的缩放值
        // 屏幕：长-3 宽-1
        // 图片：长-5 宽-1
        // (3/1) < (5/1)
        if ((screenHeight / screenSize.width) < (img.height / img.width)) {
          // 计算放大多少倍宽度占满屏幕宽度
          initialScale =
              screenSize.width / (img.width / (img.height / screenHeight));
          maxScale = initialScale + 1.0;
        }
        return GestureConfig(
          animationMinScale: 0.7,
          maxScale: maxScale,
          speed: 1.0,
          inertialSpeed: 300.0,
          initialScale: initialScale,
          inPageView: inPageView,
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
          case LoadState.failed:
            return Center(
              child: RaisedButton(
                  child: Text('重试'), onPressed: () => state.reLoadImage()),
            ); // 加载失败显示标题文本
          case LoadState.completed:
            return null;
          default:
            return null;
        }
      },
    );
  }

  void _scrollEvent() {
    var stateSnapshot = bloc.state as ReadLoadedState;
    // 计算页码
    var offset = _scrollController.offset;
    var currentSum = 0.0;
    var page = 1;
    for (var i = 1; i < pageSizes.length + 1; i++) {
      currentSum += pageSizes[i];
      if (currentSum > offset) break;
      page++;
    }
    if (page > stateSnapshot.currentPage) {
      if (page < stateSnapshot.chapter.pageCount + 1)
        bloc.add(ReadNextPageEvent(
            page: page, preLoading: stateSnapshot.preLoading));
    } else if (page < stateSnapshot.currentPage) {
      bloc.add(ReadPrevPageEvent());
    }
  }

  final connectingView = const SpinKitPouringHourglass(
      color: _connectingIndicatorColor, size: _connectionIndicatorSize);

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
    var stateSnapshot = bloc.state as ReadLoadedState;
    var directionText;
    int chapterReadAt;
    models.Chapter previewChapter;
    switch (direction) {
      case ChapterPreviewDirection.prev:
        directionText = '上';
        chapterReadAt = stateSnapshot.chapterReadAt - 1;
        if (chapterReadAt >= 0) previewChapter = widget.chapters[chapterReadAt];
        break;
      case ChapterPreviewDirection.next:
        directionText = '下';
        chapterReadAt = stateSnapshot.chapterReadAt + 1;
        if (chapterReadAt < widget.chapters.length)
          previewChapter = widget.chapters[chapterReadAt];
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
          onPressed: () {
            // 释放旧迭代其
            bloc.add(ReadFreeEvent(pageIterator: stateSnapshot.pageIterator));
            // 创建新页面迭代器
            bloc.add(ReadCreatePageIteratorEvent(
              chapterReadAt: chapterReadAt,
              chapter: previewChapter,
            ));
          },
        ),
      ],
    );
  }

  // 构建页码信息视图
  Widget _buildPageInfoView() {
    var stateSnapshot = bloc.state as ReadLoadedState;
    var pageInfo = stateSnapshot.chapter == null
        ? ''
        : '${stateSnapshot.currentPage}/${stateSnapshot.chapter.pageCount}';
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 20,
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

  Widget _buildChapterInfoView(models.Chapter chapter) {
    return Container(
      color: _toolBarBackgroundColor,
      padding: EdgeInsets.only(bottom: 10, top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(kMinInteractiveDimension / 2),
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.comic.title.isEmpty ? '历史阅读' : widget.comic.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
              SizedBox(height: 4),
              Text(
                chapter.title,
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationSlider({
    @required int pageTotal,
    @required int currentPage,
  }) {
    return Container(
      color: _toolBarBackgroundColor,
      child: Slider(
        inactiveColor: Colors.white,
        activeColor: Colors.white,
        value: currentPage.toDouble(),
        min: 1.0,
        max: pageTotal.toDouble(),
        label: '$currentPage',
        onChanged: _handleSliderChange,
      ),
    );
  }

  Widget _buildPaperRollPagesView() {
    var stateSnapshot = bloc.state as ReadLoadedState;
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    return ListView.builder(
      padding: EdgeInsets.zero,
      controller: _scrollController,
      itemCount: stateSnapshot.chapter.pageCount,
      itemBuilder: (ctx, index) {
        if (index >= stateSnapshot.pages.length) {
          return Container(
              height: screenHeight,
              child: Center(
                child: Text(
                  (index + 1).toString(),
                  style:
                      TextStyle(fontSize: 50, color: _connectingIndicatorColor),
                ),
              ));
        } else {
          return ExtendedImage.network(
            stateSnapshot.pages[index],
            headers: stateSnapshot.chapter.pageHeaders,
            fit: BoxFit.contain,
            cache: true,
            loadStateChanged: (state) {
              switch (state.extendedImageLoadState) {
                case LoadState.loading:
                  return Container(
                    height: screenHeight,
                    child: Center(
                      child: const CircularProgressIndicator(),
                    ),
                  );
                case LoadState.failed:
                  return Center(
                    child: RaisedButton(
                        child: Text('重试'),
                        onPressed: () => state.reLoadImage()),
                  ); // 加载失败显示标题文本
                case LoadState.completed:
                  var rawHeight = state.extendedImageInfo.image.height;
                  var rawWidth = state.extendedImageInfo.image.width;
                  // 屏幕显示长度需要按照缩放比例计算
                  var r = rawWidth / screenWidth;
                  var height = rawHeight / r;
                  pageSizes[index + 1] = height;
                  return null;
                default:
                  return null;
              }
            },
          );
        }
      },
    );
  }

  Widget _buildPagesView() {
    var stateSnapshot = bloc.state as ReadLoadedState;
    var scrollDirection;
    switch (stateSnapshot.readingMode) {
      case ReadingModeType.leftToRight:
        scrollDirection = Axis.horizontal;
        break;
      case ReadingModeType.topToBottom:
        scrollDirection = Axis.vertical;
        break;
      case ReadingModeType.paperRoll:
        return _buildPaperRollPagesView();
    }
    return Positioned.fill(
      child: ExtendedImageGesturePageView.builder(
        controller: _pageController,
        scrollDirection: scrollDirection,
        itemCount: stateSnapshot.chapter.pageCount + 2,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            // 上一章
            return _buildPreviewChapter(ChapterPreviewDirection.prev);
          } else if (index == stateSnapshot.chapter.pageCount + 1) {
            // 下一章
            return _buildPreviewChapter(ChapterPreviewDirection.next);
          } else if (index - 1 >= stateSnapshot.pages.length) {
            return Center(child: connectingView);
          } else {
            return _buildImageView(
              address: stateSnapshot.pages[index - 1],
              httpHeaders: stateSnapshot.chapter.pageHeaders,
              inPageView: true,
            );
          }
        },
        onPageChanged: _handlePageChange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<ReadBloc, ReadState>(
            bloc: bloc,
            // 章节发生变化（创建了新迭代器）
            condition: (prevState, state) {
              if (prevState is ReadLoadedState && state is ReadLoadedState) {
                return prevState.chapter != state.chapter;
              } else
                return false;
            },
            listener: (context, state) {
              var castedState = state as ReadLoadedState;
              // 初始化 Controller
              if (castedState.readingMode == ReadingModeType.paperRoll) {
                _pageController?.dispose();
                _pageController = null;
                _scrollController = ScrollController();
                _scrollController.addListener(_scrollEvent);
              } else {
                _scrollController?.dispose();
                _scrollController?.removeListener(_scrollEvent);
                _scrollController = null;
                _pageController = PageController(initialPage: 1);
              }
              var screenHeight = MediaQuery.of(context).size.height;
              pageSizes.clear();
              range(castedState.chapter.pageCount).forEach((i) {
                pageSizes[i + 1] = screenHeight;
              });
              // 全屏
              hiddenSystemUI();
            },
          ),
          BlocListener<ReadBloc, ReadState>(
            bloc: bloc,
            // 预缓存图片
            condition: (prevState, state) {
              if (prevState != bloc.initialState &&
                  prevState is ReadLoadedState &&
                  state is ReadLoadedState &&
                  state.preCaching) {
                // 页面数量有变化，但当前页码没变（需剔除直接加载的第一个页面）
                return prevState.pages.length > 0 &&
                    prevState.pages.length != state.pages.length &&
                    prevState.currentPage == state.currentPage;
              } else
                return false;
            },
            listener: (context, state) {
              var stateSnapshot = state as ReadLoadedState;
              precacheImage(
                ExtendedImage.network(
                  stateSnapshot.pages.last,
                  headers: stateSnapshot.chapter.pageHeaders,
                  cache: true,
                ).image,
                context,
              );
            },
          ),
        ],
        child: BlocBuilder<ReadBloc, ReadState>(
          bloc: bloc,
          builder: (context, state) {
            var castedState = state as ReadLoadedState;

            List<Widget> paginationSlider = [];
            List<Widget> infoView = [];
            if (castedState.isShowToolbar) {
              if (castedState.chapter.pageCount > 1)
                paginationSlider.add(Positioned(
                  bottom: 19,
                  left: 0,
                  right: 0,
                  child: _buildPaginationSlider(
                    pageTotal: castedState.chapter.pageCount,
                    currentPage: castedState.currentPage,
                  ),
                ));
              infoView.add(Positioned(
                left: 0,
                right: 0,
                child: _buildChapterInfoView(castedState.chapter),
              ));
            }

            return Scaffold(
              backgroundColor: _mainBackgroundColor,
              resizeToAvoidBottomInset: castedState.isLoading,
              body: castedState.isLoading
                  ? Container(
                      child: castedState.error
                          ? Center(
                              child: RaisedButton(
                                  child: Text('重试'),
                                  onPressed: () {
                                    // TODO: 处理重试
                                  }),
                            )
                          : TextHint('载入中…'),
                    )
                  : GestureDetector(
                      child: Stack(
                        children: [
                          _buildPagesView(),
                          ...infoView,
                          ...paginationSlider,
                          _buildPageInfoView(),
                        ],
                      ),
                      onTapUp: _handleGlobalTapUp,
                    ),
            );
          },
        ),
      ),
    );
  }
}

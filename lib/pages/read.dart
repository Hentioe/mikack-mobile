import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mikack_mobile/helper/chrome.dart';
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tuple/tuple.dart';
import 'package:mikack/models.dart' as models;
import '../widgets/text_hint.dart';
import '../widgets/outline_text.dart';
import '../ext.dart';
import '../store.dart';
import '../helper/compute_ext.dart';
import 'settings.dart';

const readingBackgroundColor = Color.fromARGB(255, 50, 50, 50);
const pageInfoTextColor = Color.fromARGB(255, 255, 255, 255);
const pageInfoOutlineColor = Color.fromARGB(255, 0, 0, 0);
const pageInfoFontSize = 13.0;
const spinkitSize = 35.0;
const connectionIndicatorColor = Color.fromARGB(255, 138, 138, 138);

class PagesView extends StatelessWidget {
  PagesView(
    this.chapter,
    this.addresses,
    this.currentPage,
    this.handleNext,
    this.handlePrev, {
    this.scrollController,
    this.waiting = false,
    this.leftHandMode = false,
  });

  final models.Chapter chapter;
  final List<String> addresses;
  final int currentPage;
  final void Function(int) handleNext;
  final void Function(int) handlePrev;
  final ScrollController scrollController;
  final bool waiting;
  final bool leftHandMode;

  bool isLoading() {
    return (addresses == null || addresses.length == 0 || waiting);
  }

  Widget _buildLoadingView() {
    if (waiting) {
      return SpinKitPouringHourglass(
          color: connectionIndicatorColor, size: spinkitSize);
    } else {
      return const TextHint('载入中…');
    }
  }

  final connectingIndicator = SpinKitWave(
    color: connectionIndicatorColor,
    size: spinkitSize,
  );

  Widget _buildImageView() {
    return Container(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        controller: scrollController,
        children: [
          Image.network(
            addresses[currentPage - 1],
            headers: chapter.pageHeaders,
            fit: BoxFit.fitWidth,
            width: double.infinity,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent loadingProgress) {
              if (loadingProgress == null) {
                if (child is Semantics) {
                  var rawImage = child.child;
                  if (rawImage is RawImage) {
                    if (rawImage.image == null)
                      return Center(
                        child: connectingIndicator,
                      );
                  }
                }
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes
                      : null,
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildView() {
    return isLoading() ? _buildLoadingView() : _buildImageView();
  }

  void _handleTapUp(TapUpDetails details, BuildContext context) {
    if (isLoading()) return;
    var centerLocation = MediaQuery.of(context).size.width / 2; // 取屏幕的一半长度
    var x = details.globalPosition.dx;

    if (centerLocation > x) {
      // 左屏幕（默认上一页，左手模式相反）
      if (leftHandMode)
        handleNext(currentPage);
      else
        handlePrev(currentPage);
    } else {
      // 右屏幕（默认下一页，左手模式相反）
      if (leftHandMode)
        handlePrev(currentPage);
      else
        handleNext(currentPage);
    }
  }

  // 构建页码信息视图
  Widget _buildPageInfoView() {
    var pageInfo = chapter == null ? '' : '$currentPage/${chapter.pageCount}';
    return Positioned(
      bottom: 2,
      left: 0,
      right: 0,
      child: Container(
        child: Center(
          child: OutlineText(
            pageInfo,
            fontSize: pageInfoFontSize,
            textColor: pageInfoTextColor,
            outlineColor: pageInfoOutlineColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        backgroundColor: readingBackgroundColor,
        resizeToAvoidBottomPadding: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Center(child: _buildView()),
            ),
            _buildPageInfoView(),
          ],
        ),
      ),
      onTapUp: (detail) => _handleTapUp(detail, context),
    );
  }
}

class _MainView extends StatefulWidget {
  _MainView(this.platform, this.comic, this.chapter);

  final models.Platform platform;
  final models.Comic comic;
  final models.Chapter chapter;

  @override
  State<StatefulWidget> createState() => _MainViewState();
}

class _MainViewState extends State<_MainView> {
  var _currentPage = 0;
  var _addresses = <String>[];
  bool _waiting = false;
  bool _leftHandMode = false;
  models.Chapter _chapter;
  models.PageIterator _pageInterator;

  final ScrollController pageScrollController = ScrollController();

  @override
  void initState() {
    // 创建页面迭代器
    createPageInterator();
    fetchLeftHandMode();
    super.initState();
  }

  // 加载左手模式设置
  void fetchLeftHandMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var leftHandMode = prefs.getBool(leftHandModeKey);
    if (leftHandMode == null) leftHandMode = false;
    setState(() => _leftHandMode = leftHandMode);
  }

  @override
  void dispose() {
    if (_pageInterator != null) {
      // 以通信的方式安全释放迭代器内存（注意，需要保证迭代器 API 非并发调用）
      nextResultPort?.sendPort?.send(Tuple2(ComputeController.destoryCommand,
          _pageInterator.asValuePageInaterator()));
      nextResultPort = null;
    }
    super.dispose();
  }

  // 添加阅读历史
  void addHistory(models.Chapter chapter) async {
    var history = await getHistory(address: chapter.url);
    var favorite = await getFavorite(address: widget.comic.url);
    if (history != null) {
      // 如果存在阅读历史，仅更新
      history.title = chapter.title;
      history.homeUrl = widget.comic.url;
      history.cover = widget.comic.cover;
      // 如果漫画被收藏，和最后一次阅读关联上
      if (favorite != null) {
        favorite.lastReadHistoryId = history.id;
        favorite.lastReadTime = DateTime.now();
        await updateFavorite(favorite);
      }
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
      // 如果漫画被收藏，和最后一次阅读关联上
      if (favorite != null) {
        favorite.lastReadHistoryId = history.id;
        favorite.lastReadTime = DateTime.now();
        await updateFavorite(favorite);
      }
    }
  }

  void createPageInterator() async {
    var created = await compute(
        _createPageIteratorTask, Tuple2(widget.platform, widget.chapter));
    // 迭代器创建完成隐藏系统 UI
    if (!mounted) return;
    hiddenSystemUI();
    setState(() {
      _pageInterator = created.item1.asPageIterator();
      _chapter = created.item2;
      addHistory(_chapter);
    });
    // 加载第一页
    fetchNextPage(turning: true);
  }

  final lock = Lock(); // 同步调用迭代器（必须）
  ReceivePort nextResultPort; // 留下 port 用以通信释放内存

  void fetchNextPage({turning = false, preCount = 2}) async {
    // 同步资源下载和地址池写入
    if (turning) setState(() => _waiting = true);
    await lock.synchronized(() async {
      if (_addresses.length >= _chapter.pageCount) return;
      var controller = await createComputeController(
          _getNextAddressTask, _pageInterator.asValuePageInaterator());
      nextResultPort = controller.resultPort;
      var address = await controllableCompute(controller);
      setState(() {
        _addresses.add(address);
        if (turning) {
          _waiting = false;
          _currentPage++;
        }
      });
      // 预缓存（立即翻页的不缓存）
      if (!turning)
        precacheImage(
            NetworkImage(address, headers: _chapter.pageHeaders), context);
    });
    // 预下载
    if (preCount > 0) fetchNextPage(preCount: --preCount);
  }

  void handleNext(page) {
    var currentCount = _addresses.length;
    if (page == _chapter.pageCount) return;
    // 直接修改页码
    if (page < currentCount) {
      setState(() {
        _currentPage = page + 1;
      });
      // 预下载
      if ((page + 1) == currentCount) fetchNextPage();
    } else {
      fetchNextPage(turning: true, preCount: 0); // 加载并翻页
    }
    pageScrollController.jumpTo(0);
  }

  void handlePrev(page) {
    var currentCount = _addresses.length;
    if (page <= 1 || page > currentCount) return;
    // 直接修改页码
    if (page <= currentCount) {
      setState(() {
        _currentPage = page - 1;
      });
    }
    pageScrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return PagesView(
      _chapter,
      _addresses,
      _currentPage,
      handleNext,
      handlePrev,
      scrollController: pageScrollController,
      waiting: _waiting,
      leftHandMode: _leftHandMode,
    );
  }
}

class ReadPage extends BasePage {
  ReadPage(this.platform, this.comic, this.chapter);

  final models.Platform platform;
  final models.Comic comic;
  final models.Chapter chapter;

  @override
  Widget build(BuildContext context) {
    return _MainView(platform, comic, chapter);
  }
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

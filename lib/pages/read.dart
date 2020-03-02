import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'package:mikack/models.dart' as models;
import '../widgets/text_hint.dart';

class PagesView extends StatelessWidget {
  PagesView(this.chapter, this.addresses, this.currentPage, this.handleNext,
      this.handlePrev,
      {this.scrollController});

  final models.Chapter chapter;
  final List<String> addresses;
  final int currentPage;
  final void Function(int) handleNext;
  final void Function(int) handlePrev;
  final ScrollController scrollController;

  bool isLoading() {
    return (addresses == null || addresses.length == 0);
  }

  Widget _buildLoadingView() {
    return const TextHint('载入中…');
  }

  Widget _buildImageView() {
    return Image.network(
      addresses[currentPage - 1],
      headers: chapter.pageHeaders,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes
                : null,
          ),
        );
      },
    );
  }

  Widget _buildView() {
    return isLoading()
        ? _buildLoadingView()
        : ListView(
            shrinkWrap: true,
            children: [_buildImageView()],
            controller: scrollController,
          );
  }

  void _handleTapUp(TapUpDetails details, BuildContext context) {
    var centerLocation = MediaQuery.of(context).size.width / 2;
    var x = details.globalPosition.dx;

    if (centerLocation > x) {
      handlePrev(currentPage);
    } else {
      handleNext(currentPage);
    }
  }

  final pageInfoSize = 10.0;

  @override
  Widget build(BuildContext context) {
    var pageInfo = chapter == null ? '' : '$currentPage/${chapter.pageCount}';

    return Scaffold(
        body: GestureDetector(
      child: Stack(
        children: [
          Positioned.fill(
              child: Container(
                  color: Colors.white, child: Center(child: _buildView()))),
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Container(
              child: Center(
                child: Stack(
                  children: <Widget>[
                    // Stroked text as border.
                    Text(
                      pageInfo,
                      style: TextStyle(
                        fontSize: pageInfoSize,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 1.5
                          ..color = Colors.black,
                      ),
                    ),
                    // Solid text as fill.
                    Text(
                      pageInfo,
                      style: TextStyle(
                        fontSize: pageInfoSize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      onTapUp: (detail) => _handleTapUp(detail, context),
    ));
  }
}

class _MainView extends StatefulWidget {
  _MainView(this.platform, this.chapter);

  final models.Platform platform;
  final models.Chapter chapter;

  @override
  State<StatefulWidget> createState() => _MainViewState();
}

class _MainViewState extends State<_MainView> {
  var _currentPage = 0;
  var _addresses = <String>[];
  models.Chapter _chapter;
  models.PageIterator _pageInterator;

  final ScrollController pageScrollController = ScrollController();

  @override
  void initState() {
    // 创建页面迭代器
    createPageInterator(context);
    super.initState();
  }

  @override
  void dispose() {
    if (_pageInterator != null) _pageInterator.free();
    super.dispose();
  }

  void createPageInterator(BuildContext context) async {
    var created = await compute(
        _createPageIteratorTask, Tuple2(widget.platform, widget.chapter));
    setState(() {
      _pageInterator = created.item1.asPageIterator();
      _chapter = created.item2;
    });
    // 加载第一页
    fetchNextPage(flip: true);
  }

  void fetchNextPage({flip = false, preCount = 3}) async {
    if (_currentPage > _chapter.pageCount) return;
    var address = await compute(
        _getNextAddressTask, _pageInterator.asValuePageInaterator());
    // 预下载
    precacheImage(
        NetworkImage(address, headers: _chapter.pageHeaders), context);
    setState(() {
      _addresses.add(address);
      if (flip) _currentPage++;
      // 预加载
      for (var i = 1; i <= preCount; i++) {
        if ((_currentPage + i) < _chapter.pageCount) fetchNextPage(preCount: 0);
      }
    });
  }

  void handleNext(page) async {
    var currentCount = _addresses.length;
    if (page > currentCount || page == _chapter.pageCount) return;
    // 加载第一页
    if (page == currentCount) fetchNextPage(flip: true);
    // 直接修改页码
    if (page < currentCount) {
      setState(() {
        _currentPage = page + 1;
      });
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
    return PagesView(_chapter, _addresses, _currentPage, handleNext, handlePrev,
        scrollController: pageScrollController);
  }
}

class ReadPage extends StatelessWidget {
  ReadPage(this.platform, this.chapter);

  final models.Platform platform;
  final models.Chapter chapter;

  @override
  Widget build(BuildContext context) {
    return _MainView(platform, chapter);
  }
}

class ValuePageIterator {
  int createdIterPointerAddress;
  int iterPointerAddress;

  ValuePageIterator(this.createdIterPointerAddress, this.iterPointerAddress);

  models.PageIterator asPageIterator() {
    return models.PageIterator(
        Pointer.fromAddress(this.createdIterPointerAddress),
        Pointer.fromAddress(this.iterPointerAddress));
  }
}

extension PageInteratorCopyable on models.PageIterator {
  ValuePageIterator asValuePageInaterator() {
    return ValuePageIterator(
        this.createdIterPointer.address, this.iterPointer.address);
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
      ValuePageIterator(pageIterator.createdIterPointer.address,
          pageIterator.iterPointer.address),
      chapter);
}

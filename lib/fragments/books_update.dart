import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mikack_mobile/store.dart';
import 'package:mikack_mobile/widgets/text_hint.dart';
import 'package:tuple/tuple.dart';
import 'package:mikack/models.dart' as models;
import '../main.dart' show platformList;
import '../widgets/comics_view.dart';
import '../ext.dart';

class BooksView extends StatelessWidget {
  BooksView(this.comicViewItems);

  final List<ComicViewItem> comicViewItems;

  @override
  Widget build(BuildContext context) {
    if (comicViewItems.length == 0)
      return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        return ListView(
          children: <Widget>[
            Container(
              child: Center(
                child: TextHint('还未发现更新'),
              ),
              height: constraints.maxHeight,
            ),
          ],
        );
      });
    return Scrollbar(
      child: ComicsView(comicViewItems, showBadge: true, showPlatform: true),
    );
  }
}

class _BooksUpdateFragment extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BooksUpdateFragmentState();
}

class _BooksUpdateFragmentState extends State<_BooksUpdateFragment> {
  List<ComicViewItem> _comicViewItems = [];
  var _refershing = false;
  var _progressIndicatorValue = 0.0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRefresh() async {
    var favorites = await findFavorites();
    setState(() {
      _comicViewItems.clear();
      _refershing = true;
    });
    // 并发检测更新
    for (var i = 0; i < favorites.length; i++) {
      var favorite = favorites[i];
      var source = await getSource(id: favorite.sourceId);
      if (source == null) break;
      var platform = platformList.firstWhere((p) => p.domain == source.domain);
      var comic = await compute(
          _fetchChaptersTask, Tuple2(platform, favorite.toComic()));
      var countDiff = comic.chapters.length - favorite.insertedChaptersCount;
      if (countDiff > 0) {
        comic.headers = platform.buildBaseHeaders();
        setState(() => _comicViewItems
            .add(comic.toViewItem(platform: platform, badgeValue: countDiff)));
      }
      setState(() => _progressIndicatorValue = (i + 1) / favorites.length);
    }
    setState(() {
      _refershing = false;
      _progressIndicatorValue = 0.0;
    });
  }

  void _handleStopRefresh() async {
    setState(() => _refershing = false);
  }

  @override
  Widget build(BuildContext context) {
    var refersingView = <Widget>[];
    var stopView = <Widget>[];
    if (_refershing) {
      if (_progressIndicatorValue > 0) // 进度为空时不显示
        refersingView.add(Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(value: _progressIndicatorValue),
        ));
      stopView.add(Positioned(
        bottom: 15,
        right: 15,
        child: FloatingActionButton(
          tooltip: '停止更新',
          child: Icon(Icons.stop),
          onPressed: _handleStopRefresh,
        ),
      ));
    }

    return RefreshIndicator(
      child: Stack(
        children: [
          ...refersingView,
          Positioned.fill(child: BooksView(_comicViewItems)),
          ...stopView,
        ],
      ),
      onRefresh: _handleRefresh,
    );
  }
}

class BooksUpdateFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BooksUpdateFragment();
  }
}

models.Comic _fetchChaptersTask(Tuple2<models.Platform, models.Comic> args) {
  var platform = args.item1;
  var comic = args.item2;

  platform.fetchChapters(comic);
  return comic;
}

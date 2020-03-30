import 'package:executor/executor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikack_mobile/pages/comic.dart';
import 'package:mikack_mobile/store.dart';
import 'package:mikack_mobile/store/impl/chapter_update_api.dart';
import 'package:mikack_mobile/widgets/text_hint.dart';
import 'package:tuple/tuple.dart';
import 'package:mikack/models.dart' as models;
import '../main.dart' show platformList;
import '../widgets/comics_view.dart';
import '../ext.dart';

class BooksView extends StatelessWidget {
  BooksView(
    this.comicViewItems, {
    this.firstOpen,
    this.fromLocal = false,
    this.lastUpdateTime,
    this.onTap,
  });

  final bool firstOpen;
  final List<ComicViewItem> comicViewItems;
  final bool fromLocal;
  final DateTime lastUpdateTime;
  final void Function(models.Comic) onTap;

  @override
  Widget build(BuildContext context) {
    if (comicViewItems.length == 0)
      return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        return ListView(
          children: <Widget>[
            Container(
              child: Center(
                child: TextHint('${firstOpen ? '下拉检查更新' : '未发现更新'}'),
              ),
              height: constraints.maxHeight,
            ),
          ],
        );
      });
    return Scrollbar(
      child: ComicsView(
        comicViewItems,
        showBadge: true,
        showPlatform: true,
        onTap: onTap,
      ),
    );
  }
}

class _BooksUpdateFragment extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BooksUpdateFragmentState();
}

class _BooksUpdateFragmentState extends State<_BooksUpdateFragment> {
  var _firstOpen = true;
  List<ComicViewItem> _comicViewItems = [];
  var _refreshing = false;
  var _progressIndicatorValue = 0.0;

  @override
  void initState() {
    // 载入更新记录
    fetchChapterUpdates();
    super.initState();
  }

  void fetchChapterUpdates() async {
    var favorites = await findFavorites();
    var chapterUpdates = await findChapterUpdates();
    List<ComicViewItem> comicViewItems = [];
    for (ChapterUpdate chapterUpdate in chapterUpdates) {
      var favorite =
          favorites.firstWhere((f) => f.address == chapterUpdate.homeUrl);
      var countDiff =
          chapterUpdate.chaptersCount - favorite.latestChaptersCount;
      if (favorite != null && countDiff > 0) {
        var source = await getSource(id: favorite.sourceId);
        if (source == null) break;
        var platform =
            platformList.firstWhere((p) => p.domain == source.domain);
        var comic = favorite.toComic();
        comic.headers = platform.buildBaseHeaders();
        comicViewItems
            .add(comic.toViewItem(platform: platform, badgeValue: countDiff));
      }
    }
    setState(() {
      _comicViewItems = comicViewItems;
    });
  }

  Future<void> _handleRefresh() async {
    var favorites = await findFavorites();
    setState(() {
      _firstOpen = false;
      _comicViewItems.clear();
      _refreshing = true;
    });
    await deleteAllChapterUpdates(); // 删除已存在的更新记录
    // 并发检测更新
    final executor = Executor(concurrency: 8);
    var counter = 0;
    for (var favorite in favorites) {
      executor.scheduleTask(() async {
        if (!_refreshing) {
          Fluttertoast.showToast(msg: '检查更新已停止');
          return;
        }
        var source = await getSource(id: favorite.sourceId);
        if (source == null) return;
        var platform =
            platformList.firstWhere((p) => p.domain == source.domain);
        var comic = await compute(
            _fetchChaptersTask, Tuple2(platform, favorite.toComic()));
        var countDiff = comic.chapters.length - favorite.latestChaptersCount;
        if (countDiff > 0) {
          comic.headers = platform.buildBaseHeaders();
          if (mounted)
            setState(() => _comicViewItems.add(
                comic.toViewItem(platform: platform, badgeValue: countDiff)));
          // 插入更新记录
          await insertChapterUpdate(ChapterUpdate(
            comic.url,
            chaptersCount: comic.chapters.length,
          ));
        }
        if (mounted)
          setState(() {
            _progressIndicatorValue = ++counter / favorites.length;
          });
      });
    }
    await executor.join(withWaiting: true);
    await executor.close();
    if (mounted)
      setState(() {
        _refreshing = false;
        _progressIndicatorValue = 0.0;
      });
  }

  void _handleStopRefresh() async {
    Fluttertoast.showToast(msg: '检查更新停止中…');
    setState(() => _refreshing = false);
  }

  void _openComicPage(models.Comic comic) async {
    var favorites = await findFavorites();
    var favorite = favorites.firstWhere((f) => f.address == comic.url);
    if (favorite == null) {
      // TODO: 收藏已不存在了
    }
    var source = await getSource(id: favorite.sourceId);
    if (source == null) {
      // TODO: 图源已不存在了
    }
    var platform = platformList.firstWhere((p) => p.domain == source.domain);
    if (platform == null) {
      // TODO: 已不支持这个平台了哦
    }
    comic.headers = platform.buildBaseHeaders();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicPage(platform, comic),
      ),
    ).then((_) => fetchChapterUpdates());
  }

  @override
  Widget build(BuildContext context) {
    var refreshingView = <Widget>[];
    var stopView = <Widget>[];
    if (_refreshing) {
      if (_progressIndicatorValue > 0) // 进度为空时不显示
        refreshingView.add(Positioned(
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
          ...refreshingView,
          Positioned.fill(
              child: BooksView(
            _comicViewItems,
            firstOpen: _firstOpen,
            onTap: _openComicPage,
          )),
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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:mikack_mobile/store.dart';
import 'package:tuple/tuple.dart';
import 'package:mikack/models.dart' as models;
import 'comic/info_tab.dart';
import 'comic/chapters_tab.dart';
import './read.dart';

class _MainPage extends StatefulWidget {
  _MainPage(this.platform, this.comic);

  final models.Platform platform;
  final models.Comic comic;

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<_MainPage>
    with SingleTickerProviderStateMixin {
  TabController tabController;
  models.Comic _comic;

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    _comic = widget.comic;
    // 更新上次阅读时间
    updateLastReadTime();
    fetchChapters();
    super.initState();
  }

  void openReadPage(models.Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadPage(widget.platform, widget.comic, chapter),
      ),
    );
  }

  void fetchChapters() async {
    var comic =
        await compute(_fetchChaptersTask, Tuple2(widget.platform, _comic));
    setState(() {
      _comic = comic;
    });
  }

  void updateLastReadTime() async {
    var favotite = await getFavorite(address: _comic.url);
    if (favotite != null) {
      favotite.lastReadTime = DateTime.now();
      await updateFavorite(favotite);
    }
  }

  void openFirstChapter(BuildContext context) {
    openReadPage(_comic.chapters[0]);
  }

  @override
  Widget build(BuildContext context) {
    var showFloatActionBtn =
        _comic.chapters != null && _comic.chapters.length == 1;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_backspace),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.comic.title),
        bottom: TabBar(
          tabs: const [
            Tab(text: '信息'),
            Tab(text: '章节'),
          ],
          controller: tabController,
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          InfoTab(widget.platform, _comic),
          ChaptersTab(
            _comic,
            openReadPage: openReadPage,
          )
        ],
      ),
      floatingActionButton: showFloatActionBtn
          ? FloatingActionButton(
              child: Icon(Icons.play_arrow),
              onPressed: () => openFirstChapter(context))
          : null,
    );
  }
}

class ComicPage extends BasePage {
  ComicPage(this.platform, this.comic);

  final models.Platform platform;
  final models.Comic comic;

  @override
  Widget build(BuildContext context) {
    initNavigationBar();
    return _MainPage(platform, comic);
  }
}

models.Comic _fetchChaptersTask(Tuple2<models.Platform, models.Comic> args) {
  var platform = args.item1;
  var comic = args.item2;

  platform.fetchChapters(comic);
  return comic;
}

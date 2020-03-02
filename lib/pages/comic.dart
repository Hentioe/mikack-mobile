import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    fetchChapters();
    super.initState();
  }

  void fetchChapters() async {
    var comic = await compute(
        _fetchChaptersTask, {'platform': widget.platform, 'comic': _comic});
    setState(() {
      _comic = comic;
    });
  }

  void openFirstChapter(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ReadPage(widget.platform, _comic.chapters[0])));
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
          ChaptersTab(widget.platform, _comic)
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

class ComicPage extends StatelessWidget {
  ComicPage(this.platform, this.comic);

  final models.Platform platform;
  final models.Comic comic;

  @override
  Widget build(BuildContext context) => _MainPage(platform, comic);
}

models.Comic _fetchChaptersTask(args) {
  models.Platform platform = args['platform'];
  models.Comic comic = args['comic'];

  platform.fetchChapters(comic);
  return comic;
}

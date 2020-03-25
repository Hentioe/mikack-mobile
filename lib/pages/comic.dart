import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikack_mobile/pages/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mikack_mobile/helper/chrome.dart';
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:mikack_mobile/store.dart';
import 'package:tuple/tuple.dart';
import 'package:mikack/models.dart' as models;
import 'comic/info_tab.dart';
import 'comic/chapters_tab.dart';
import './read.dart';
import '../ext.dart';

class _ComicPage extends StatefulWidget {
  _ComicPage(this.platform, this.comic);

  final models.Platform platform;
  final models.Comic comic;

  @override
  State<StatefulWidget> createState() => _ComicPageState();
}

class _ComicPageState extends State<_ComicPage>
    with SingleTickerProviderStateMixin {
  TabController tabController;
  models.Comic _comic;
  bool _isFavorite = false;
  int _tabIndex = 0;
  bool _sortReversed = false;
  List<String> _readHistoryLinks = [];
  String _lastReadAt;

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() => _tabIndex = tabController.index);
    });
    _comic = widget.comic;
    // 更新上次阅读时间
    updateLastReadTime();
    // 加载章节信息
    fetchChapters();
    // 加载收藏状态
    fetchIsFavorite();
    // 加载已阅读的章节链接
    fetchReadHistoryLinks();
    // 加载上次阅读位置
    fetchLastHistory();
    super.initState();
  }

  void fetchReadHistoryLinks() async {
    var readHistories =
        await findHistories(forceDisplayed: false, homeUrl: _comic.url);
    setState(
        () => _readHistoryLinks = readHistories.map((h) => h.address).toList());
  }

  void openReadPage(models.Chapter chapter) {
    setNavigationBarColor(readingBackgroundColor);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadPage(widget.platform, widget.comic, chapter),
      ),
    ).then((_) {
      setSystemUI(primaryColor: primaryColor);
      fetchReadHistoryLinks();
      fetchLastHistory();
    });
  }

  void fetchChapters() async {
    var comic =
        await compute(_fetchChaptersTask, Tuple2(widget.platform, _comic));
    // 更新已收藏的章节数量
    var favorite = await getFavorite(address: comic.url);
    if (favorite != null) {
      favorite.latestChaptersCount = comic.chapters.length;
      await updateFavorite(favorite);
    }
    // 加载排序设置
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var chaptersReversed = prefs.getBool(chaptersReversedKey);
    if (chaptersReversed == null) chaptersReversed = false;
    setState(() {
      _sortReversed = chaptersReversed;
      _comic = comic;
    });
  }

  void fetchLastHistory() async {
    var lastReadHistory = await getLastHistory(_comic.url);

    if (lastReadHistory != null)
      setState(() => _lastReadAt = lastReadHistory.address);
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

  void fetchIsFavorite() async {
    var favorite = await getFavorite(address: _comic.url);
    if (favorite != null) setState(() => _isFavorite = true);
  }

  // 处理收藏按钮点击
  void _handleFavorite() async {
    var source = await widget.platform.toSavedSource();
    if (!_isFavorite) {
      // 收藏
      await insertFavorite(Favorite(
        sourceId: source.id,
        name: _comic.title,
        address: _comic.url,
        cover: _comic.cover,
        latestChaptersCount:
            _comic.chapters != null ? _comic.chapters.length : 0,
      ));
      setState(() => _isFavorite = true);
    } else {
      // 取消收藏
      await deleteFavorite(address: _comic.url);
      setState(() => _isFavorite = false);
    }
  }

  static final moreMenus = {'在浏览器中打开': 1, '清空已阅读记录': 2};

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: '无法自动打开链接',
      );
    }
  }

  void resetReadHistories() async {
    await deleteHistories(homeUrl: _comic.url);
    setState(() {
      _readHistoryLinks = [];
      _lastReadAt = null;
    });
  }

  void _handleMenuSelect(value) {
    switch (value) {
      case 1:
        launchUrl(_comic.url);
        break;
      case 2:
        resetReadHistories();
        break;
    }
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<int>(
      tooltip: '更多功能',
      icon: Icon(Icons.more_vert),
      onSelected: _handleMenuSelect,
      itemBuilder: (BuildContext context) => moreMenus.entries
          .map((entry) => PopupMenuItem(
                value: entry.value,
                child: Text(entry.key),
              ))
          .toList(),
    );
  }

  void _handleChapterReadMark(models.Chapter chapter) async {
    var source = await widget.platform.toSavedSource();
    var history = await getHistory(address: chapter.url);
    if (history == null) {
      await insertHistory(History(
        sourceId: source.id,
        title: chapter.title,
        homeUrl: _comic.url,
        address: chapter.url,
        cover: _comic.cover,
        displayed: false,
      ));
    }
    setState(() => _readHistoryLinks.add(chapter.url));
  }

  void _handleChaptersReadMark(List<models.Chapter> chapters) async {
    var source = await widget.platform.toSavedSource();
    List<String> urls = [];
    List<History> histories = [];
    // 一次性查询出所有已存在的历史记录
    var extendedHistoryAddresses = (await findHistories(
            forceDisplayed: false,
            addressesIn: chapters.map((c) => c.url).toList()))
        .map((h) => h.address)
        .toList();
    // 剔除已存在的历史
    chapters.removeWhere((c) => extendedHistoryAddresses.contains(c.url));
    for (models.Chapter chapter in chapters) {
      histories.add(History(
        sourceId: source.id,
        title: chapter.title,
        homeUrl: _comic.url,
        address: chapter.url,
        cover: _comic.cover,
        displayed: false,
      ));
      urls.add(chapter.url);
    }
    // 插入新的不显示历史（仅标记已读）
    await insertHistories(histories);
    setState(() => _readHistoryLinks.addAll(urls));
  }

  void _handleChapterUnReadMark(models.Chapter chapter) async {
    await deleteHistory(address: chapter.url);
    setState(() => _readHistoryLinks.remove(chapter.url));
  }

  void handleReverse() async {
    setState(() => _sortReversed = !_sortReversed);
  }

  void handleShare() async {
    await FlutterShare.share(
      title: '分享：${_comic.title}',
      linkUrl: _comic.url,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabActions = [];
    switch (_tabIndex) {
      case 0:
        tabActions.add(IconButton(
            tooltip: '分享此漫画', icon: Icon(Icons.share), onPressed: handleShare));
        break;
      case 1:
        tabActions.add(IconButton(
          tooltip: '反转排序',
          icon: Icon(Icons.swap_horiz),
          onPressed: handleReverse,
        ));
        break;
    }
    var showFloatActionBtn =
        _comic.chapters != null && _comic.chapters.length == 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.comic.title),
        bottom: TabBar(
          tabs: const [
            Tab(text: '信息'),
            Tab(text: '章节'),
          ],
          controller: tabController,
        ),
        actions: [...tabActions, _buildMoreMenu()],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          InfoTab(
            widget.platform,
            _comic,
            isFavorite: _isFavorite,
            handleFavorite: _handleFavorite,
          ),
          ChaptersTab(
            _comic,
            reversed: _sortReversed,
            lastReadAt: _lastReadAt,
            readHistoryLinks: _readHistoryLinks,
            openReadPage: openReadPage,
            handleChapterReadMark: _handleChapterReadMark,
            handleChapterUnReadMark: _handleChapterUnReadMark,
            handleChaptersReadMark: _handleChaptersReadMark,
          )
        ],
      ),
      floatingActionButton: showFloatActionBtn
          ? FloatingActionButton(
              tooltip: '开始阅读',
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
    initSystemUI();
    return _ComicPage(platform, comic);
  }
}

models.Comic _fetchChaptersTask(Tuple2<models.Platform, models.Comic> args) {
  var platform = args.item1;
  var comic = args.item2;

  platform.fetchChapters(comic);
  return comic;
}

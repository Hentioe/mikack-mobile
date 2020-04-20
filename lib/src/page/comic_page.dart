import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikack/models.dart' as models;
import 'package:url_launcher/url_launcher.dart';

import '../blocs.dart';
import '../widget/series_system_ui.dart';
import './comic_tabs/info_tab.dart';
import './comic_tabs/chapters_tab.dart';

import '../page/read_page.dart';
import '../helper/chrome.dart';

class ComicPage2 extends StatefulWidget {
  final models.Platform platform;
  final models.Comic comic;

  final BuildContext appContext;

  ComicPage2({@required this.platform, @required this.comic, this.appContext});

  @override
  State<StatefulWidget> createState() => ComicPage2State();

  static final moreMenus = {'在浏览器中打开': 1, '清空已阅读记录': 2};
}

class ComicPage2State extends State<ComicPage2>
    with SingleTickerProviderStateMixin {
  ComicBloc bloc;
  TabController tabController;

  @override
  void initState() {
    bloc = ComicBloc(platform: widget.platform, comic: widget.comic);
    bloc.add(ComicRequestEvent());
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      bloc.add(ComicTabChangedEvent(index: tabController.index));
    });
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    tabController.dispose();
    super.dispose();
  }

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: '无法自动打开链接',
      );
    }
  }

  void _handleMenuSelect(value, {models.Comic latestComic}) {
    var comic = latestComic ?? widget.comic;
    switch (value) {
      case 1:
        launchUrl(comic.url);
        break;
      case 2:
        bloc.add(ComicReadingMarkCleanRequestEvent());
        break;
    }
  }

  Widget _buildMoreMenu({models.Comic latestComic}) {
    return PopupMenuButton<int>(
      tooltip: '更多功能',
      icon: Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuSelect(value, latestComic: latestComic),
      itemBuilder: (BuildContext context) => ComicPage2.moreMenus.entries
          .map((entry) => PopupMenuItem(
                value: entry.value,
                child: Text(entry.key),
              ))
          .toList(),
    );
  }

  void _handleShare(models.Comic latestComic) async {
    var comic = latestComic ?? widget.comic;
    await FlutterShare.share(
      title: '分享：${comic.title}',
      linkUrl: comic.url,
    );
  }

  void _handleFavorite({bool isCancel}) async {
    bloc.add(ComicFavoriteEvent(isCancel: isCancel));
  }

  Function(models.Chapter) _handleOpenReadPage(
          BuildContext context, models.Comic latestComic) =>
      (models.Chapter chapter) async {
        // 查找上一章
//        var tmpChapters =
//            latestComic.chapters.where((c) => c.which == chapter.which - 1);
//        var prevChapter = tmpChapters.length == 0 ? null : tmpChapters.first;
//        // 查找下一章
//        tmpChapters =
//            latestComic.chapters.where((c) => c.which == chapter.which + 1);
//        var nextChapter = tmpChapters.length == 0 ? null : tmpChapters.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReadPage2(
              platform: widget.platform,
              comic: widget.comic,
              chapter: chapter,
            ),
          ),
        ).then((r) {
          if (r is models.Chapter)
            _handleOpenReadPage(context, latestComic)(r);
          else {
            restoreStatusBarColor();
            showSystemUI();
            // 更新阅读历史记录
            bloc.add(ComicReadHistoriesUpdateEvent());
          }
        });
      };

  Function(models.Chapter) _handleReadingMarkUpdate(
          BuildContext context, ComicReadingMarkType markType) =>
      (models.Chapter chapter) {
        bloc.add(
            ComicReadingMarkUpdateEvent(markType: markType, chapter: chapter));
      };

  Function() _handleRetry(BuildContext context) => () {
        bloc.add(ComicRetryEvent());
      };

  Widget _buildTabActions(int tabIndex, {models.Comic latestComic}) {
    var defaultButton = IconButton(
        tooltip: '分享此漫画',
        icon: Icon(Icons.share),
        onPressed: () => _handleShare(latestComic));
    switch (tabIndex) {
      case 0:
        return defaultButton;
      case 1:
        return IconButton(
          tooltip: '反转排序',
          icon: Icon(Icons.swap_horiz),
          onPressed: () => bloc.add(ComicReverseEvent()),
        );
      default:
        return defaultButton;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SeriesSystemUI(
      child: BlocListener<ComicBloc, ComicState>(
        bloc: bloc,
        condition: (prevState, state) {
          if (prevState != bloc.initialState &&
              prevState is ComicLoadedState &&
              state is ComicLoadedState) {
            return prevState.isFavorite != state.isFavorite;
          }
          return false;
        },
        listener: (context, state) {
          var castedState = state as ComicLoadedState;
          var msg = castedState.isFavorite ? '已添加至书架' : '已从书架删除';
          Fluttertoast.showToast(msg: msg);
          // 刷新收藏列表
          widget.appContext
              ?.bloc<BookshelfBloc>()
              ?.add(BookshelfRequestEvent.sortByDefault());
        },
        child: BlocBuilder<ComicBloc, ComicState>(
          bloc: bloc,
          builder: (context, state) {
            var castedState = state as ComicLoadedState;
            var showFloatActionBtn = castedState.comic.chapters != null &&
                castedState.comic.chapters.length == 1;
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
                actions: [
                  _buildTabActions(
                    castedState.tabIndex,
                  ),
                  _buildMoreMenu(latestComic: castedState.comic),
                ],
              ),
              body: TabBarView(
                controller: tabController,
                children: [
                  InfoTab(
                    widget.platform,
                    castedState.comic,
                    error: castedState.error,
                    handleRetry: _handleRetry(context),
                    isFavorite: castedState.isFavorite,
                    handleFavorite: () =>
                        _handleFavorite(isCancel: castedState.isFavorite),
                  ),
                  ChaptersTab(
                    castedState.comic,
                    error: castedState.error,
                    handleRetry: _handleRetry(context),
                    reversed: castedState.reversed,
                    readHistoryAddresses: castedState.readHistoryAddresses,
                    lastReadAt: castedState.lastReadAt,
                    openReadPage:
                        _handleOpenReadPage(context, castedState.comic),
                    handleChapterReadMark: _handleReadingMarkUpdate(
                        context, ComicReadingMarkType.readOne),
                    handleChaptersReadMark: (chapters) => bloc.add(
                        ComicReadingMarkUpdateEvent(
                            markType: ComicReadingMarkType.readBefore,
                            chapters: chapters)),
                    handleChapterUnReadMark: _handleReadingMarkUpdate(
                        context, ComicReadingMarkType.unreadOne),
                  ),
                ],
              ),
              floatingActionButton: showFloatActionBtn
                  ? FloatingActionButton(
                      heroTag: 'startReaddingFab',
                      tooltip: '开始阅读',
                      child: Icon(Icons.play_arrow),
                      onPressed: () =>
                          _handleOpenReadPage(context, castedState.comic)(
                              castedState.comic.chapters.first))
                  : null,
            );
          },
        ),
      ),
    );
  }
}

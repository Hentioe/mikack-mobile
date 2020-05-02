import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;
import 'package:url_launcher/url_launcher.dart';

import 'read_page.dart';
import '../helper/chrome.dart';
import '../values.dart';
import '../widget/series_system_ui.dart';
import '../blocs.dart';
import '../ext.dart';

const _groupWitchSpacing = 10000;
const _coverBlurSigma = 8.5;
const _comicBodyHeight = 250.0;
const _chapterSpacing = 16.0;

class ComicPage extends StatefulWidget {
  final models.Platform platform;
  final models.Comic comic;

  final BuildContext appContext;

  ComicPage({@required this.platform, @required this.comic, this.appContext});

  @override
  State<StatefulWidget> createState() => _ComicPageState();

  static final moreMenus = {'在浏览器中打开': 1, '清空已阅读记录': 2};
}

class _ComicPageState extends State<ComicPage> {
  ComicBloc bloc;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    bloc = ComicBloc(platform: widget.platform, comic: widget.comic);
    bloc.add(ComicRequestEvent());
    scrollController.addListener(_scrollEvent);
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    scrollController.removeListener(_scrollEvent);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollEvent() {
    if (scrollController.offset >= _comicBodyHeight - kToolbarHeight) {
      bloc.add(ComicAppBarBackgroundChangedEvent(color: vPrimarySwatch));
      bloc.add(ComicVisibilityUpdateEvent(showAppBarTitle: true));
    } else {
      bloc.add(ComicVisibilityUpdateEvent(showAppBarTitle: false));
      bloc.add(ComicAppBarBackgroundChangedEvent(color: Colors.white));
    }
  }

  Function(models.Chapter) _handleOpenReadPage(
          BuildContext context, models.Comic latestComic) =>
      (models.Chapter chapter) async {
        var stateSnapshot = bloc.state as ComicLoadedState;
        var position = 0;
        stateSnapshot.comic.chapters.asMap().forEach((i, c) {
          if (c == chapter) position = i;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReadPage(
              platform: widget.platform,
              comic: widget.comic,
              chapters: stateSnapshot.comic.chapters,
              initChapterReadAt: position,
            ),
          ),
        ).then((r) {
          restoreStatusBarColor();
          showSystemUI();
          // 更新阅读历史记录
          bloc.add(ComicReadHistoriesUpdateEvent());
        });
      };

  void _handleFavorite({bool isCancel}) async {
    bloc.add(ComicFavoriteEvent(isCancel: isCancel));
  }

  Function() _handleRetry(BuildContext context) => () {
        bloc.add(ComicRetryEvent());
      };

  void _handleShare(models.Comic latestComic) async {
    var comic = latestComic ?? widget.comic;
    await FlutterShare.share(
      title: '分享：${comic.title}',
      linkUrl: comic.url,
    );
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

  List<models.Chapter> reverseByGroup(List<models.Chapter> chapters,
      {whichAt = 0, List<List<models.Chapter>> reversedGroup}) {
    var group = <models.Chapter>[];
    for (models.Chapter c in chapters) {
      if (c.which >= whichAt * _groupWitchSpacing &&
          c.which < (whichAt + 1) * _groupWitchSpacing)
        group.add(c);
      else
        break;
    }
    if (reversedGroup == null) reversedGroup = [];
    reversedGroup.add(group.reversed.toList());
    if (group.last.which == chapters.last.which) {
      // 到底了，合并并返回
      return reversedGroup.expand((c) => c).toList();
    }
    return reverseByGroup(
      chapters.getRange(group.length, chapters.length).toList(),
      whichAt: ++whichAt,
      reversedGroup: reversedGroup,
    );
  }

  void _handleChapterMenuSelect(int value, models.Chapter chapter) async {
    var stateSnapshot = bloc.state as ComicLoadedState;
    switch (value) {
      case 0: // 标记已读
        bloc.add(ComicReadingMarkUpdateEvent(
            markType: ComicReadingMarkType.readOne, chapter: chapter));
        break;
      case 1: // 标记未读
        bloc.add(ComicReadingMarkUpdateEvent(
            markType: ComicReadingMarkType.unreadOne, chapter: chapter));
        break;
      case 2: // 标记之前章节已读
        var beginAt = chapter.which ~/ _groupWitchSpacing * _groupWitchSpacing;
        var beforeChapters = stateSnapshot.comic.chapters
            .where((c) => c.which > beginAt && c.which < chapter.which)
            .toList();
        bloc.add(
          ComicReadingMarkUpdateEvent(
              markType: ComicReadingMarkType.readBefore,
              chapters: beforeChapters),
        );
        break;
      default:
        // 无效菜单
        break;
    }
  }

  Widget _buildFavoriteView() {
    var stateSnapshot = bloc.state as ComicLoadedState;
    return Positioned(
      top: _comicBodyHeight - 28, // 浮动按钮默认大小为 56.0，取一半
      right: 15,
      child: FloatingActionButton(
        heroTag: 'favoriteFab',
        tooltip: '${stateSnapshot.isFavorite ? '从书架删除' : '添加到书架'}',
        child: Icon(
            stateSnapshot.isFavorite ? Icons.bookmark : Icons.bookmark_border),
        onPressed: () => _handleFavorite(isCancel: stateSnapshot.isFavorite),
      ),
    );
  }

  Widget _buildComicInfoView() {
    var stateSnapshot = bloc.state as ComicLoadedState;
    return Stack(
      children: [
        Stack(
          children: [
            // 背景图
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: ExtendedNetworkImageProvider(
                    stateSnapshot.comic.cover,
                    cache: true,
                  ),
                  fit: BoxFit.fitWidth,
                ),
              ),
              height: _comicBodyHeight,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: _coverBlurSigma, sigmaY: _coverBlurSigma),
                  child: Container(
                    decoration:
                        BoxDecoration(color: Colors.white.withOpacity(0.35)),
                  ),
                ),
              ),
            ),
            // 表面内容
            Container(
              width: double.infinity,
              height: _comicBodyHeight,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                left: 22,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左图
                  Hero(
                    tag: 'cover-${widget.comic.url}',
                    child: ExtendedImage.network(
                      stateSnapshot.comic.cover,
                      width: 74,
                      cache: true,
                      loadStateChanged: (state) {
                        switch (state.extendedImageLoadState) {
                          case LoadState.failed:
                            return Center(
                              child: Text(
                                '封面',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                            ); // 加载失败显示标题文本
                            break;
                          default:
                            return null;
                            break;
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                  // 文字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stateSnapshot.comic.title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                        ),
                        SizedBox(height: 10),
                        _ComicProperty(
                            '章节数量',
                            stateSnapshot.comic.chapters == null
                                ? '未知'
                                : stateSnapshot.comic.chapters.length),
                        SizedBox(height: 10),
                        _ComicProperty('来源', widget.platform.name),
                        SizedBox(height: 20),
                        Text(
                            stateSnapshot.comic.chapters != null
                                ? '暂无说明'
                                : stateSnapshot.error ? '载入失败' : '载入中…',
                            style: TextStyle(
                                color: Colors.grey[800], fontSize: 15)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showChapterMenu(models.Chapter chapter, Offset downPosition) async {
    var stateSnapshot = bloc.state as ComicLoadedState;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    var r = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
          downPosition & Size(0, 0), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(
          enabled: !stateSnapshot.readHistoryAddresses.contains(chapter.url),
          value: 0,
          child: Text('标记已读'),
        ),
        PopupMenuItem(
          enabled: stateSnapshot.readHistoryAddresses.contains(chapter.url),
          value: 1,
          child: Text('标记未读'),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('标记之前章节已读'),
        ),
      ],
    );
    _handleChapterMenuSelect(r, chapter);
  }

  void _handleColumnsLayoutToggled(int itemIndex) {
    switch (itemIndex) {
      case 0:
        bloc.add(ComicChapterColumnsChangedEvent(layoutColumns: 1));
        break;
      case 1:
        bloc.add(ComicChapterColumnsChangedEvent(layoutColumns: 3));
        break;
      case 2:
        bloc.add(ComicChapterColumnsChangedEvent(layoutColumns: 2));
        break;
      default:
        break;
    }
  }

  void _handleSortToggled(int _itemIndex) {
    bloc.add(ComicReverseEvent());
  }

  double _buildGridAspectRatio() {
    var stateSnapshot = bloc.state as ComicLoadedState;
    switch (stateSnapshot.layoutColumns) {
      case 1:
        return 14;
      case 2:
        return 6.8;
      case 3:
        return 4.2;
      default:
        return 1;
    }
  }

  Widget _buildToolbarView() {
    var stateSnapshot = bloc.state as ComicLoadedState;
    return Positioned(
      top: _comicBodyHeight - _ToggleBar.height / 2, // 浮动按钮默认大小为 56.0，取一半
      left: _chapterSpacing,
      child: Wrap(
        spacing: 8,
        children: [
          _ToggleBar(
            headerText: '章节布局',
            items: [
              _ToggleItem(
                text: '单列',
                checked: stateSnapshot.layoutColumns == 1,
              ),
              _ToggleItem(
                  text: '紧凑', checked: stateSnapshot.layoutColumns == 3),
              _ToggleItem(
                  text: '宽松', checked: stateSnapshot.layoutColumns == 2),
            ],
            onToggled: _handleColumnsLayoutToggled,
          ),
          _ToggleBar(
            headerText: '排序方式',
            items: [
              _ToggleItem(text: '升序', checked: !stateSnapshot.reversed),
              _ToggleItem(text: '倒序', checked: stateSnapshot.reversed),
            ],
            onToggled: _handleSortToggled,
          ),
        ],
      ),
    );
  }

  Widget _buildComicChaptersView() {
    var stateSnapshot = bloc.state as ComicLoadedState;
    if (stateSnapshot.error)
      return Column(
        children: [
          SizedBox(height: 28),
          Center(
            child: RaisedButton(
                child: Text('重试'), onPressed: _handleRetry(context)),
          ),
        ],
      );
    if (stateSnapshot.comic.chapters == null)
      return Column(
        children: [
          SizedBox(height: 28),
          Center(
            child: CircularProgressIndicator(),
          )
        ],
      );
    var chapters = stateSnapshot.comic.chapters;
    if (chapters.length > 1 && stateSnapshot.reversed)
      chapters = reverseByGroup(chapters);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: stateSnapshot.layoutColumns,
        childAspectRatio: _buildGridAspectRatio(),
        mainAxisSpacing: _chapterSpacing,
        crossAxisSpacing: _chapterSpacing,
      ),
      padding: EdgeInsets.only(
        left: _chapterSpacing,
        bottom: _chapterSpacing,
        right: _chapterSpacing,
      ),
      itemCount: chapters.length,
      itemBuilder: (ctx, i) {
        var c = chapters[i];
        return _ChapterItem(
          chapter: c,
          hasReadMark: stateSnapshot.readHistoryAddresses.contains(c.url),
          isLastRead: stateSnapshot.lastReadAt != null &&
              stateSnapshot.lastReadAt == c.url,
          onPressed: _handleOpenReadPage(context, stateSnapshot.comic),
          onLongPressed: _showChapterMenu,
        );
      },
    );
  }

  List<Widget> _buildActions({models.Comic latestComic}) {
    return <Widget>[
      IconButton(
        tooltip: '分享此漫画',
        icon: Icon(Icons.share),
        onPressed: () => _handleShare(latestComic),
      ),
    ];
  }

  Widget _buildMoreMenu({models.Comic latestComic}) {
    return PopupMenuButton<int>(
      tooltip: '更多功能',
      icon: Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuSelect(value, latestComic: latestComic),
      itemBuilder: (BuildContext context) => ComicPage.moreMenus.entries
          .map(
            (entry) =>
                PopupMenuItem(value: entry.value, child: Text(entry.key)),
          )
          .toList(),
    );
  }

  Widget _buildFloatingActionButton() {
    var stateSnapshot = bloc.state as ComicLoadedState;
    if (stateSnapshot.comic.chapters == null ||
        stateSnapshot.comic.chapters.isEmpty) return null;
    var lastReadChapter = stateSnapshot.comic.chapters
        .where((c) => c.url == stateSnapshot.lastReadAt);
    if (lastReadChapter.isNotEmpty) {
      return FloatingActionButton(
        heroTag: 'continue-reading',
        tooltip: '继续阅读',
        child: Icon(Icons.restore),
        onPressed: () => _handleOpenReadPage(context, stateSnapshot.comic)(
            lastReadChapter.first),
      );
    } else {
      return FloatingActionButton(
        heroTag: 'start-reading',
        tooltip: '开始阅读',
        child: Icon(Icons.play_arrow),
        onPressed: () => _handleOpenReadPage(context, stateSnapshot.comic)(
            stateSnapshot.comic.chapters.first),
      );
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
          var stateSnapshot = state as ComicLoadedState;
          var msg = stateSnapshot.isFavorite ? '已添加至书架' : '已从书架删除';
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
            return Scaffold(
              backgroundColor: Colors.white,
              body: NestedScrollView(
                controller: scrollController,
                headerSliverBuilder: (ctx, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: castedState.appBarColor,
                      expandedHeight: _comicBodyHeight + 10,
                      pinned: true,
                      snap: false,
                      floating: false,
                      forceElevated: false,
                      title: castedState.isShowAppBarTitle
                          ? Text(castedState.comic.title)
                          : null,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            _buildComicInfoView(),
                            Visibility(
                              visible: castedState.isShowFavoriteButton,
                              child: _buildFavoriteView(),
                            ),
                            Visibility(
                              visible: castedState.isShowToolBar,
                              child: _buildToolbarView(),
                            )
                          ],
                        ),
                      ),
                      actions: [
                        ..._buildActions(),
                        _buildMoreMenu(latestComic: castedState.comic),
                      ],
                    ),
                  ];
                },
                body: Stack(
                  children: [
                    _buildComicChaptersView(),
                  ],
                ),
              ),
              floatingActionButton: _buildFloatingActionButton(),
            );
          },
        ),
      ),
    );
  }
}

class _ToggleItem {
  final bool checked;
  final String text;

  _ToggleItem({@required this.text, this.checked = false});
}

const _toggleItemXSpacing = 8.0;
const _toggleItemYSpacing = 2.0;

class _ToggleBar extends StatelessWidget {
  final String headerText;
  final List<_ToggleItem> items;
  final void Function(int itemIndex) onToggled;

  _ToggleBar({
    @required this.headerText,
    @required this.items,
    this.onToggled,
  });

  final _spacing = EdgeInsets.only(
    left: _toggleItemXSpacing,
    top: _toggleItemYSpacing,
    right: _toggleItemXSpacing,
    bottom: _toggleItemYSpacing,
  );

  static var _radius = Radius.circular(6);
  static var _borderRadius = BorderRadius.only(
    bottomLeft: _radius,
    bottomRight: _radius,
    topLeft: _radius,
    topRight: _radius,
  );

  static var height = 45.0;

  final boxShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(40),
      blurRadius: 2.0, // has the effect of softening the shadow
      spreadRadius: 2.0, // has the effect of extending the shadow
      offset: Offset(
        1.5, // horizontal, move right 10
        1.5, // vertical, move down 10
      ),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: _borderRadius,
        boxShadow: boxShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3),
                color: Colors.grey[100],
                child: Text(
                  headerText,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey[600],
                  ),
                ),
              )
            ],
          ),
          Row(
            children: items
                .mapWithIndex(
                  (i, item) => GestureDetector(
                    child: Container(
                      padding: _spacing,
                      decoration: BoxDecoration(
                        color:
                            item.checked ? vPrimarySwatch : vPrimarySwatch[100],
                        borderRadius: BorderRadius.only(
                          bottomLeft: i == 0 ? _radius : Radius.zero,
                          bottomRight:
                              i == (items.length - 1) ? _radius : Radius.zero,
                        ),
                      ),
                      child: Text(
                        item.text,
                        style: TextStyle(
                            color: item.checked
                                ? Colors.white
                                : vPrimarySwatch[600],
                            fontSize: 11.5),
                      ),
                    ),
                    onTap: () {
                      if (onToggled != null) onToggled(i);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ComicProperty extends StatelessWidget {
  _ComicProperty(this.name, this.value);

  final String name;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$name ',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        Text(value.toString(), style: TextStyle(color: Colors.grey[850])),
      ],
    );
  }
}

class _ChapterItem extends StatefulWidget {
  final models.Chapter chapter;
  final bool hasReadMark;
  final bool isLastRead;
  final Function(models.Chapter) onPressed;
  final Function(models.Chapter, Offset) onLongPressed;

  _ChapterItem({
    @required this.chapter,
    this.hasReadMark = false,
    this.isLastRead = false,
    this.onPressed,
    this.onLongPressed,
  });

  @override
  __ChapterItemState createState() => __ChapterItemState();
}

class __ChapterItemState extends State<_ChapterItem> {
  Offset _downPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: FlatButton(
        textColor: widget.isLastRead
            ? Colors.white
            : widget.hasReadMark ? Colors.grey[400] : Colors.grey[700],
        color: widget.isLastRead ? vPrimarySwatch : null,
        child: Text(widget.chapter.title,
            maxLines: 1, style: TextStyle(fontWeight: FontWeight.normal)),
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(14),
          side: BorderSide(
              color: widget.isLastRead ? vPrimarySwatch : Colors.grey[400]),
        ),
        onPressed: () {
          if (widget.onPressed != null) widget.onPressed(widget.chapter);
        },
        onLongPress: () {
          if (widget.onLongPressed != null)
            widget.onLongPressed(widget.chapter, _downPosition);
        },
      ),
      onTapDown: (detail) {
        _downPosition = detail.globalPosition;
      },
    );
  }
}

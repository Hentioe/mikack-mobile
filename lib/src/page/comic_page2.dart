import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;
import 'package:url_launcher/url_launcher.dart';

import 'comic_page.dart';
import 'read_page.dart';
import '../helper/chrome.dart';
import '../values.dart';
import '../widget/series_system_ui.dart';
import '../blocs.dart';

const _groupSpacing = 10000;
const _coverBlurSigma = 3.5;
const _comicBodyHeight = 200.0;
const _chapterSpacing = 16.0;

/// TODO: 章节操作功能（长按上下文菜单）

class ComicPage2 extends StatefulWidget {
  final models.Platform platform;
  final models.Comic comic;

  final BuildContext appContext;

  ComicPage2({@required this.platform, @required this.comic, this.appContext});

  @override
  State<StatefulWidget> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage2> {
  ComicBloc bloc;

  @override
  void initState() {
    bloc = ComicBloc(platform: widget.platform, comic: widget.comic);
    bloc.add(ComicRequestEvent());
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
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
      if (c.which >= whichAt * _groupSpacing &&
          c.which < (whichAt + 1) * _groupSpacing)
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
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            // 表面内容
            Container(
              width: double.infinity,
              height: _comicBodyHeight,
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左图
                  Hero(
                    tag: 'cover-${widget.comic.url}',
                    child: ExtendedImage.network(
                      stateSnapshot.comic.cover,
                      width: 100,
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
                        _ComicProperty('图源', widget.platform.name),
                        SizedBox(height: 20),
                        Text(
                            stateSnapshot.comic.chapters != null
                                ? '暂无说明'
                                : stateSnapshot.error ? '载入失败' : '载入中……',
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

  List<Widget> _buildToolbarButtons() {
    var stateSnapshot = bloc.state as ComicLoadedState;
    return [
      stateSnapshot.columns == 3
          ? _ToolbarButton(
              icon: Icons.view_module,
              text: '紧凑排列',
              onTap: () =>
                  bloc.add(ComicChapterColumnsChangedEvent(columns: 2)),
            )
          : _ToolbarButton(
              icon: Icons.view_week,
              text: '宽松排列',
              onTap: () =>
                  bloc.add(ComicChapterColumnsChangedEvent(columns: 3)),
            ),
      _ToolbarButton(
          icon: Icons.sort,
          text: stateSnapshot.reversed ? '倒序' : '正序',
          onTap: () => bloc.add(ComicReverseEvent())),
    ];
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: _chapterSpacing - _toolBarButtonPaddingSize,
            top: _chapterSpacing,
            right: _chapterSpacing,
          ),
          child: Wrap(
            children: _buildToolbarButtons(),
          ),
        ),
        GridView.count(
          crossAxisCount: stateSnapshot.columns,
          shrinkWrap: true,
          mainAxisSpacing: _chapterSpacing,
          crossAxisSpacing: _chapterSpacing,
          padding: EdgeInsets.all(_chapterSpacing),
          childAspectRatio: stateSnapshot.columns == 3 ? 4.2 : 6.2,
          physics: ClampingScrollPhysics(),
          children: chapters
              .map((c) => _ChapterItem(
                    chapter: c,
                    hasReadMark:
                        stateSnapshot.readHistoryAddresses.contains(c.url),
                    isLastRead: stateSnapshot.lastReadAt != null &&
                        stateSnapshot.lastReadAt == c.url,
                    onPressed:
                        _handleOpenReadPage(context, stateSnapshot.comic),
                  ))
              .toList(),
        ),
      ],
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
          .map((entry) => PopupMenuItem(
                value: entry.value,
                child: Text(entry.key),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SeriesSystemUI(
      child: BlocBuilder<ComicBloc, ComicState>(
        bloc: bloc,
        builder: (context, state) {
          var castedState = state as ComicLoadedState;
          var isShowFloatButton = castedState.comic.chapters != null &&
              castedState.comic.chapters.length == 1;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(widget.comic.title),
              actions: [
                ..._buildActions(),
                _buildMoreMenu(latestComic: castedState.comic),
              ],
            ),
            body: Stack(
              children: [
                ListView(
                  children: [
                    _buildComicInfoView(),
                    _buildComicChaptersView(),
                  ],
                ),
                _buildFavoriteView(),
              ],
            ),
            floatingActionButton: isShowFloatButton
                ? FloatingActionButton(
                    heroTag: 'startReaddingFab',
                    tooltip: '开始阅读',
                    child: Icon(Icons.play_arrow),
                    onPressed: () =>
                        _handleOpenReadPage(context, castedState.comic)(
                            castedState.comic.chapters.first),
                  )
                : null,
          );
        },
      ),
    );
  }
}

const _toolBarButtonPaddingSize = 6.0;

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function() onTap;

  _ToolbarButton({@required this.icon, this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
//      highlightColor: Colors.black.withAlpha(20),
      child: Container(
        padding: EdgeInsets.only(
            left: _toolBarButtonPaddingSize, right: _toolBarButtonPaddingSize),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: vPrimarySwatch[300], size: 26),
            Text(text,
                style: TextStyle(color: vPrimarySwatch[300], fontSize: 12)),
          ],
        ),
      ),
      onTap: () {
        if (onTap != null) onTap();
      },
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

class _ChapterItem extends StatelessWidget {
  final models.Chapter chapter;
  final bool hasReadMark;
  final bool isLastRead;
  final Function(models.Chapter) onPressed;

  _ChapterItem({
    @required this.chapter,
    this.hasReadMark = false,
    this.isLastRead = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      textColor:
          isLastRead ? Colors.white : hasReadMark ? Colors.grey[500] : null,
      color: isLastRead ? vPrimarySwatch : null,
      child: Text(chapter.title,
          maxLines: 1, style: TextStyle(fontWeight: FontWeight.normal)),
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(14),
        side: BorderSide(color: isLastRead ? vPrimarySwatch : Colors.grey[300]),
      ),
      onPressed: () {
        if (onPressed != null) onPressed(chapter);
      },
    );
  }
}

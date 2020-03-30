import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:mikack_mobile/widgets/comics_view.dart';

import 'favicon.dart';

const comicCoverLoadingView = const SizedBox(
  height: comicsViewGridLoadingSize,
  width: comicsViewGridLoadingSize,
  child: CircularProgressIndicator(strokeWidth: 2),
);

class ComicCard extends StatelessWidget {
  ComicCard(
    this.viewItem, {
    this.fit = StackFit.loose,
    this.width,
    this.height,
    this.showBadge = false,
    this.showPlatform = false,
    this.onTap,
    this.onLongPress,
  });

  final ComicViewItem viewItem;
  final StackFit fit;
  final double width;
  final double height;
  final bool showBadge;
  final bool showPlatform;
  final Function(ComicViewItem) onTap;
  final Function(ComicViewItem) onLongPress;

  @override
  Widget build(BuildContext context) {
    List<Widget> platformView = [];
    if (showPlatform)
      platformView.addAll([
        Favicon(viewItem.platform, size: 14),
        SizedBox(width: 4),
      ]);
    List<Widget> badgeView = [];
    if (showBadge)
      badgeView.add(
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 30,
            height: 22,
            color: Colors.blue,
            child: Center(
                child: Text(
              '${(viewItem.badgeValue ?? 0) > 999 ? 999 : viewItem.badgeValue}',
              // 最大显示 999
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )),
          ),
        ),
      );
    return Card(
      child: Stack(
        fit: fit,
        children: [
          // 封面
          Hero(
            tag: 'cover-${viewItem.comic.url}',
            child: ExtendedImage.network(
              viewItem.comic.cover,
              width: width,
              height: height,
              fit: BoxFit.cover,
              headers: viewItem.comic.headers,
              cache: true,
              loadStateChanged: (state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    return Center(
                      child: comicCoverLoadingView,
                    );
                    break;
                  case LoadState.failed:
                    return Center(
                      child: Text(
                        viewItem.comic.title,
                        style: TextStyle(color: Colors.grey, fontSize: 18),
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
          // 徽章（角标）
          ...badgeView,
          // 文字
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(left: 5, top: 20, right: 5, bottom: 5),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                    Color.fromARGB(120, 0, 0, 0),
                    Colors.transparent,
                  ])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ...platformView,
                  Flexible(
                    child: Text(
                      viewItem.comic.title,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),
          ),
          // 点击事件和效果
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap != null ? onTap(viewItem) : null,
                onLongPress: () =>
                    onLongPress != null ? onLongPress(viewItem) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

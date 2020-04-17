import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/widgets/comic_card.dart';
import '../src/values.dart';

const viewListCoverHeight = 56.0;
const viewListCoverWidth = viewListCoverHeight * coverRatio;
const listCoverRadius = 4.0;
const comicsViewGridChildSpacing = 4.0;
const comicsViewGridLoadingSize = 16.0;

class ComicViewItem {
  final models.Comic comic;
  final models.Platform platform;
  final int badgeValue;

  ComicViewItem(
    this.comic, {
    this.platform,
    this.badgeValue,
  });
}

class ComicsView extends StatelessWidget {
  ComicsView(
    this.items, {
    this.isViewList = false,
    this.showPlatform = false,
    this.showBadge = false,
    this.onTap,
    this.onLongPress,
    this.scrollController,
  });

  final List<ComicViewItem> items;
  final bool isViewList;
  final bool showPlatform;
  final bool showBadge;
  final Function(models.Comic) onTap;
  final Function(models.Comic) onLongPress;
  final ScrollController scrollController;

  // 列表显示的边框形状
  final viewListShape = const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.all(Radius.circular(1)));

  // 列表显示
  Widget _buildViewList() {
    var children = items
        .map(
          (item) => Card(
            shape: viewListShape,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ExtendedImage.network(item.comic.cover,
                  headers: item.comic.headers,
                  fit: BoxFit.cover,
                  width: viewListCoverWidth,
                  height: viewListCoverHeight,
                  cache: true, loadStateChanged: (state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    return Center(
                      child: loadingView,
                    );
                    break;
                  case LoadState.failed:
                    return Center(
                      child: Text(
                        '无图',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ); // 加载失败显示标题文本
                    break;
                  default:
                    return null;
                    break;
                }
              }),
              title: Text(item.comic.title,
                  style: TextStyle(color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              onTap: () => onTap(item.comic),
            ),
          ),
        )
        .toList();
    return ListView(
      children: children,
      controller: scrollController,
    );
  }

  // 加载指示器
  final loadingView = const SizedBox(
    height: comicsViewGridLoadingSize,
    width: comicsViewGridLoadingSize,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  // 网格显示
  Widget _buildGridView(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: comicsViewGridChildSpacing / 2,
      crossAxisSpacing: comicsViewGridChildSpacing / 2,
      childAspectRatio: coverRatio,
      padding: EdgeInsets.all(comicsViewGridChildSpacing),
      children: List.generate(items.length, (index) {
        return ComicCard(
          items[index],
          fit: StackFit.expand,
          showBadge: showBadge,
          showPlatform: showPlatform,
          onTap: (item) => onTap == null ? null : onTap(item.comic),
          onLongPress: (item) =>
              onLongPress == null ? null : onLongPress(item.comic),
        );
      }),
      controller: scrollController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return isViewList ? _buildViewList() : _buildGridView(context);
  }
}

import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/widgets/favicon.dart';

const viewListCoverHeight = double.infinity;
const viewListCoverWidth = 50.0;
const listCoverRadius = 4.0;

class ComicViewItem {
  final models.Comic comic;
  final models.Platform platfrom;

  ComicViewItem(
    this.comic, {
    this.platfrom,
  });
}

class ComicsView extends StatelessWidget {
  ComicsView(
    this.items, {
    this.isViewList = false,
    this.showPlatform = false,
    this.onTap,
    this.onLongPress,
    this.scrollController,
  });

  final List<ComicViewItem> items;
  final bool isViewList;
  final bool showPlatform;
  final Function(models.Comic) onTap;
  final Function(models.Comic) onLongPress;
  final ScrollController scrollController;

  // 列表显示的边框形状
  final viewListShape = const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.all(Radius.circular(1)));

  // 列表显示
  Widget _buildViewList() {
    var children = items
        .map((item) => Card(
              shape: viewListShape,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Image.network(item.comic.cover,
                    headers: item.comic.headers,
                    fit: BoxFit.cover,
                    height: viewListCoverHeight,
                    width: viewListCoverWidth),
                title: Text(item.comic.title,
                    style: TextStyle(color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                onTap: () => onTap(item.comic),
              ),
            ))
        .toList();
    return ListView(
      children: children,
      controller: scrollController,
    );
  }

  // 网格显示
  Widget _buildGridView(BuildContext context) {
    var attachItems = <Widget Function(ComicViewItem)>[];
    if (showPlatform)
      attachItems.add(
        (item) => Positioned(
          right: 4,
          top: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              color: Colors.white.withOpacity(0.7),
              child: Favicon(item.platfrom, size: 22),
            ),
          ),
        ),
      );
    return GridView.count(
      crossAxisCount: 2,
      children: List.generate(items.length, (index) {
        return Card(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 图片
              Image.network(
                items[index].comic.cover,
                fit: BoxFit.cover,
                headers: items[index].comic.headers,
              ),
              // 文字
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      EdgeInsets.only(left: 5, top: 20, right: 5, bottom: 5),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                        Color.fromARGB(120, 0, 0, 0),
                        Colors.transparent,
                      ])),
                  child: Center(
                    child: Text(items[index].comic.title,
                        style: TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              ...attachItems.map((builder) => builder(items[index])).toList(),
              // 点击事件和效果
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        onTap == null ? null : onTap(items[index].comic),
                    onLongPress: () => onLongPress == null
                        ? null
                        : onLongPress(items[index].comic),
                  ),
                ),
              ),
            ],
          ),
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

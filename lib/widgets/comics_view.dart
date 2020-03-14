import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;

const viewListCoverHeight = double.infinity;
const viewListCoverWidth = 50.0;
const listCoverRadius = 4.0;

class ComicsView extends StatelessWidget {
  ComicsView(
    this.comics, {
    this.isViewList = false,
    this.onTap,
    this.onLongPress,
    this.scrollController,
  });

  final bool isViewList;
  final List<models.Comic> comics;
  final Function(models.Comic) onTap;
  final Function(models.Comic) onLongPress;
  final ScrollController scrollController;

  // 列表显示的边框形状
  final viewListShape = const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.all(Radius.circular(1)));

  // 列表显示
  Widget _buildViewList() {
    var children = comics
        .map((c) => Card(
              shape: viewListShape,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Image.network(c.cover,
                    headers: c.headers,
                    fit: BoxFit.cover,
                    height: viewListCoverHeight,
                    width: viewListCoverWidth),
                title: Text(c.title,
                    style: TextStyle(color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                onTap: () => onTap(c),
              ),
            ))
        .toList();
    return ListView(
      children: children,
      controller: scrollController,
    );
  }

  // 网格显示
  Widget _buildGridView() {
    return GridView.count(
      crossAxisCount: 2,
      children: List.generate(comics.length, (index) {
        return Card(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 图片
              Image.network(
                comics[index].cover,
                fit: BoxFit.cover,
                headers: comics[index].headers,
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
                    child: Text(comics[index].title,
                        style: TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              // 点击事件和效果
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap == null ? null : onTap(comics[index]),
                    onLongPress: () =>
                        onLongPress == null ? null : onLongPress(comics[index]),
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
    return isViewList ? _buildViewList() : _buildGridView();
  }
}

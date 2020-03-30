import 'dart:ui';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;
import '../../widgets/text_hint.dart';

class MetaRow extends StatelessWidget {
  MetaRow(this.name, this.value);

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

const coverBlurSigma = 3.5;
const coverMetaHeight = 200.0;

class InfoTab extends StatelessWidget {
  InfoTab(this.platform, this.comic,
      {this.isFavorite = false, this.handleFavorite});

  final models.Platform platform;
  final models.Comic comic;
  final bool isFavorite;
  final void Function() handleFavorite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 图片和元信息
            Stack(
              children: [
                // 背景图
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: ExtendedNetworkImageProvider(
                        comic.cover,
                        cache: true,
                      ),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  height: coverMetaHeight,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: coverBlurSigma, sigmaY: coverBlurSigma),
                      child: Container(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                // 表面内容
                Container(
                    width: double.infinity,
                    height: coverMetaHeight,
                    padding: EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左图
                        Hero(
                          tag: 'cover-${comic.url}',
                          child: ExtendedImage.network(
                            comic.cover,
                            width: 100,
                            cache: true,
                            loadStateChanged: (state) {
                              switch (state.extendedImageLoadState) {
                                case LoadState.failed:
                                  return Center(
                                    child: Text(
                                      '图片呢？',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 18),
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
                                comic.title,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                              ),
                              SizedBox(height: 10),
                              MetaRow(
                                  '章节数量',
                                  comic.chapters == null
                                      ? '未知'
                                      : comic.chapters.length),
                              SizedBox(height: 10),
                              MetaRow('图源', platform.name),
                            ],
                          ),
                        )
                      ],
                    )),
              ],
            ),
            // 描述文字
            ListView(
              shrinkWrap: true,
              children: [
                SizedBox(height: 25),
                Container(
                  child: Center(
                    child: TextHint(comic.chapters == null ? '加载中…' : '暂无说明'),
                  ),
                )
              ],
            )
          ],
        ),
        Positioned(
          top: coverMetaHeight - 28, // 浮动按钮默认大小为 56.0，取一半
          right: 15,
          child: FloatingActionButton(
            heroTag: 'favoriteFab',
            tooltip: '${isFavorite ? '从书架删除' : '添加到书架'}',
            child: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
            onPressed: handleFavorite,
          ),
        )
      ],
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mikack/src/models.dart' as models;

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
        Text(value.toString(), style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }
}

const coverBlurSigma = 4.5;

class InfoTab extends StatelessWidget {
  InfoTab(this.platform, this.comic);

  final models.Platform platform;
  final models.Comic comic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Stack(
          children: [
            // 背景图
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(comic.cover), fit: BoxFit.fitWidth),
              ),
              height: 200,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: coverBlurSigma, sigmaY: coverBlurSigma),
                  child: Container(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            // 表面内容
            Container(
                width: double.infinity,
                height: 200,
                padding: EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左图
                    Image.network(
                      comic.cover,
                      width: 100,
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
        SizedBox(height: 50),
        Container(
          child: Center(
            child: Text(comic.chapters == null ? '加载中…' : '暂无说明',
                style: TextStyle(fontSize: 25, color: Colors.grey[400])),
          ),
        )
      ],
    );
  }
}

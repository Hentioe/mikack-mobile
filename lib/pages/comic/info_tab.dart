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
        Text(value.toString(), style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}

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
            Container(
              width: double.infinity,
              height: 200,
              child: Image.network(comic.cover, fit: BoxFit.fitWidth),
            ),
            Container(
                width: double.infinity,
                height: 200,
                padding: EdgeInsets.all(20),
                color: Color.fromARGB(170, 255, 255, 255),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      comic.cover,
                      width: 100,
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comic.title,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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

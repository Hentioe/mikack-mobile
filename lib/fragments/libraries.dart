import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:tuple/tuple.dart';
import '../pages/detail.dart';
import '../pages/index.dart';
import '../widgets/tag.dart';
import '../main.dart' show platformList, nsfwTagValue;
import '../widgets/favicon.dart';

const allowNsfwHint = '未设置允许 NSFW 内容';

class LibrariesFragment extends StatelessWidget {
  LibrariesFragment(this.platforms);

  final List<models.Platform> platforms;

  List<Widget> _buildPlatformList(BuildContext context) {
    return platforms
        .map((p) => Card(
              margin: EdgeInsets.only(bottom: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadiusDirectional.all(Radius.circular(2))),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Hero(
                    tag: 'favicon-${p.domain}',
                    child: Favicon(p, size: 30),
                  ),
                ),
                title: Text(p.name),
                trailing: OutlineButton(
                  textColor: Colors.blueAccent,
                  borderSide: BorderSide(color: Colors.blueAccent),
                  highlightedBorderColor: Colors.blueAccent,
                  child: Text('详细'),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => DetailPage(p))),
                ),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => IndexPage(p))),
              ),
            ))
        .toList();
  }

  Future<Tuple2<List<int>, List<int>>> openFilter(
    BuildContext context, {
    List<int> includes = const [],
    List<int> excludes = const [],
    allowNsfw = false,
  }) {
    var completer = Completer<Tuple2<List<int>, List<int>>>();
    var tagModels = tags();
    var includesTags = tagModels
        .map((t) => Tag(
              t.value,
              t.name,
              stateful: true,
              selected: includes.contains(t.value),
              stateFixed: !allowNsfw && t.value == nsfwTagValue,
              stateFixedReason: allowNsfwHint,
              onTap: (value, selected) =>
                  selected ? includes.add(value) : includes.remove(value),
            ))
        .toList();
    var excludesTags = tagModels
        .map((t) => Tag(
              t.value,
              t.name,
              stateful: true,
              selected: excludes.contains(t.value),
              stateFixed: !allowNsfw && t.value == nsfwTagValue,
              stateFixedReason: allowNsfwHint,
              onTap: (value, selected) =>
                  selected ? excludes.add(value) : excludes.remove(value),
            ))
        .toList();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('平台过滤'),
        actions: [
          FlatButton(
            child: Text("取消"),
            onPressed: () => Navigator.of(context).pop(), //关闭对话框
          ),
          FlatButton(
            child: Text("应用"),
            onPressed: () {
              completer.complete(Tuple2(includes, excludes));
              Navigator.of(context).pop(true); //关闭对话框
            },
          ),
        ],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标签过滤
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '包含的标签',
                  style: TextStyle(fontSize: 14.5, color: Colors.grey[700]),
                ),
                Divider(),
                SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  alignment: WrapAlignment.start,
                  runSpacing: 10,
                  children: includesTags,
                ),
                SizedBox(height: 25),
                Text(
                  '排除的标签',
                  style: TextStyle(fontSize: 14.5, color: Colors.grey[700]),
                ),
                Divider(),
                SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  alignment: WrapAlignment.start,
                  runSpacing: 10,
                  children: excludesTags,
                ),
              ],
            ),
            SizedBox(height: 25),
            Center(
              child: Text('部分平台可能存在多个标签',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            )
          ],
        ),
      ),
    );
    return completer.future;
  }

  Widget _buildHeaderText() {
    var text = platformList.length == platforms.length ? '全部' : '已过滤';
    return Text(
      '$text (${platforms.length})',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 14.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.only(top: 15, bottom: 15),
            child: _buildHeaderText(),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Column(
              children: _buildPlatformList(context),
            ),
          ),
        ],
      ),
    );
  }
}

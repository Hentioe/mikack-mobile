import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:tuple/tuple.dart';
import '../pages/detail.dart';
import '../pages/index.dart';
import '../widgets/tag.dart';
import '../ext.dart';
import '../main.dart' show platformList;

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
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    p.favicon == null ? '' : p.favicon,
                    width: 30,
                    height: 30,
                    fit: BoxFit.fill,
                    headers: p.buildBaseHeaders(),
                    filterQuality: FilterQuality.none,
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
  }) {
    var completer = Completer<Tuple2<List<int>, List<int>>>();
    var tagModels = tags();
    var includesTags = tagModels
        .map((t) => Tag(
              t.value,
              t.name,
              stateful: true,
              selected: includes.contains(t.value),
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
        content: Stack(
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
                  alignment: WrapAlignment.center,
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
                  alignment: WrapAlignment.center,
                  children: excludesTags,
                ),
              ],
            ),
            // 备注
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Center(
                child: Text('注意，一个平台可能存在多个标签',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
              ),
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

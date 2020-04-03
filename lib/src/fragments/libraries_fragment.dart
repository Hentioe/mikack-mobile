import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:tuple/tuple.dart';

import '../../pages/detail.dart';
import '../../pages/index.dart';
import '../../src/blocs.dart';
import '../../widgets/favicon.dart';
import '../../widgets/tag.dart';
import '../../main.dart' show nsfwTagValue;

const _rootSpacing = 15.0;
const _librariesFilterTagFontSize = 10.8;
const allowNsfwHint = '未设置允许 NSFW 内容';

class LibrariesFragment2 extends StatelessWidget {
  LibrariesFragment2({
    Key key,
    includes = const <int>[],
    excludes = const <int>[],
  }) : super(key: key);

  /// 打开过滤器弹窗，用于响应主屏幕应用栏的过滤 action 触摸事件。（理论上 MainPage 全局可用）
  /// 返回将包含选择的完整条件的 Future
  /// TODO: 取消也需返回内容，避免长期引用导致的内存泄漏
  static Future<Tuple2<List<int>, List<int>>> openFilter(
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
              fontSize: _librariesFilterTagFontSize,
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
              fontSize: _librariesFilterTagFontSize,
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

  void Function(models.Platform) _handleItemTap(BuildContext context) =>
      (models.Platform platform) => Navigator.push(context,
          MaterialPageRoute(builder: (context) => IndexPage(platform)));

  void Function(models.Platform) _handleItemDetail(BuildContext context) =>
      (models.Platform platform) => Navigator.push(context,
          MaterialPageRoute(builder: (context) => DetailPage(platform)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(_rootSpacing),
      children: [
        BlocBuilder<LibrariesBloc, LibrariesState>(
          condition: (prevState, state) => state is LibrariesFilteredState,
          builder: (context, state) => _Group(
            title: '全部',
            platforms: (state as LibrariesFilteredState).list,
            handleItemTap: _handleItemTap(context),
            handleItemDetail: _handleItemDetail(context),
          ),
        )
      ],
    );
  }
}

class _Group extends StatelessWidget {
  _Group({
    @required this.title,
    this.platforms = const [],
    this.handleItemTap,
    this.handleItemDetail,
  });

  final String title;
  final List<models.Platform> platforms;
  final void Function(models.Platform) handleItemTap;
  final void Function(models.Platform) handleItemDetail;

  Widget _buildPlatformItemView(
    models.Platform platform, {
    showDomain = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: platforms.last.domain != platform.domain
            ? Border(bottom: BorderSide(color: Colors.grey[300]))
            : null,
      ),
      child: ListTile(
        leading: Hero(
          tag: 'favicon-${platform.domain}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Favicon(platform, size: 30),
          ),
        ),
        title: Text(platform.name),
        subtitle: showDomain
            ? Text(platform.domain, style: TextStyle(color: Colors.grey[600]))
            : null,
        trailing: OutlineButton(
          textColor: Colors.blueAccent,
          borderSide: BorderSide(color: Colors.blueAccent),
          highlightedBorderColor: Colors.blueAccent,
          child: Text('详细'),
          onPressed: () => handleItemDetail(platform),
        ),
        onTap: () => handleItemTap(platform),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title (${platforms.length})',
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        SizedBox(height: 20),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: platforms.map((p) => _buildPlatformItemView(p)).toList(),
          ),
        )
      ],
    );
  }
}

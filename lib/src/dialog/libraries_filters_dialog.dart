import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart';
import 'package:tuple/tuple.dart';

import '../../widgets/tag.dart';
import '../values.dart';

const _librariesFilterTagFontSize = 10.8;
const _allowNsfwHint = '未在设置中允许 NSFW 内容';

Future<Tuple2<List<int>, List<int>>> openLibrariesFiltersDialog(
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
            stateFixedReason: _allowNsfwHint,
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
            stateFixedReason: _allowNsfwHint,
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

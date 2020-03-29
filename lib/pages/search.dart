import 'dart:collection';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:mikack_mobile/widgets/comics_view.dart';
import 'package:mikack_mobile/widgets/favicon.dart';
import 'package:mikack_mobile/widgets/tag.dart';
import 'package:mikack_mobile/ext.dart';
import 'package:mikack_mobile/widgets/text_hint.dart';
import 'package:tuple/tuple.dart';

import 'comic.dart';

const searchResultCoverHeight = 210.0;
const searchResultCoverWidth = coverRatio * searchResultCoverHeight;

class _SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

const searchPageSpacing = 18.0;

class _SearchPageState extends State<_SearchPage> {
  var _submitted = false;
  String _keywords;
  List<models.Platform> _platforms =
      platforms().where((p) => p.isSearchable).toList();

  final TextEditingController editingController = TextEditingController();

  ThemeData appBarTheme() {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      primaryColor: Colors.white,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
      primaryColorBrightness: Brightness.light,
      primaryTextTheme: theme.textTheme,
    );
  }

  final filterTextHeaderStyle =
      TextStyle(color: Colors.grey[800], fontSize: 16);

  var includes = <int>[];
  var excludes = <int>[];

  List<String> _excludesPlatformDomains = [];

  void updatePlatforms() {
    setState(() {
      _platforms = findPlatforms(
        includes.map((v) => models.Tag(v, '')).toList(),
        excludes.map((v) => models.Tag(v, '')).toList(),
      ).where((p) => p.isSearchable).toList();
      _excludesPlatformDomains.clear();
    });
  }

  Widget _buildFilterView() {
    var tagModels = tags();
    var includesTags = tagModels
        .map((t) => Tag(
              t.value,
              t.name,
              stateful: true,
              selected: includes.contains(t.value),
              onTap: (value, selected) {
                selected ? includes.add(value) : includes.remove(value);
                updatePlatforms();
              },
            ))
        .toList();
    var excludesTags = tagModels
        .map((t) => Tag(
              t.value,
              t.name,
              stateful: true,
              selected: excludes.contains(t.value),
              onTap: (value, selected) {
                selected ? excludes.add(value) : excludes.remove(value);
                updatePlatforms();
              },
            ))
        .toList();
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(searchPageSpacing),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                '包含的标签',
                style: filterTextHeaderStyle,
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: includesTags,
              ),
              SizedBox(height: 16),
              Text(
                '排除的标签',
                style: filterTextHeaderStyle,
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: excludesTags,
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
        Divider(
          height: 0,
          color: Colors.grey[400],
          indent: 100,
          endIndent: 100,
        ),
        // 平台列表
        Expanded(
          child: Scrollbar(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _platforms.map((p) {
                var isContains = _excludesPlatformDomains.contains(p.domain);
                return ListTile(
                  leading: Favicon(p, size: 20),
                  contentPadding: EdgeInsets.only(
                      left: searchPageSpacing, right: searchPageSpacing),
                  title: Text(p.name),
                  trailing: Icon(
                      isContains
                          ? Icons.check_box_outline_blank
                          : Icons.check_box,
                      color: isContains ? Colors.grey : primaryColor),
                  onTap: () {
                    if (isContains)
                      setState(() {
                        _excludesPlatformDomains.remove(p.domain);
                      });
                    else
                      setState(() {
                        _excludesPlatformDomains.add(p.domain);
                      });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSearchClear() {
    editingController.clear();
  }

  LinkedHashMap<models.Platform, List<ComicViewItem>> _groupedItems =
      LinkedHashMap.from({});

  void handleSearch() async {
    setState(() {
      _groupedItems.clear();
    });
    for (models.Platform platform in _platforms
        .where((p) => !_excludesPlatformDomains.contains(p.domain))) // 过滤已排除的
    {
      var comics =
          await compute(_searchComicsTask, Tuple2(platform, _keywords));
      if (mounted)
        setState(() {
          _groupedItems
              .addAll({platform: comics.toViewItems(platform: platform)});
        });
      else
        break;
    }
  }

  // 封面加载指示器
  final coverLoadingView = const SizedBox(
    height: comicsViewGridLoadingSize,
    width: comicsViewGridLoadingSize,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  // TODO: 独立漫画卡片小部件，和 ComicsView 共享
  Widget _buildResultView() {
    var participantsCount = _platforms.length - _excludesPlatformDomains.length;
    if (participantsCount == 0) // 没选择平台
      return TextHint('未选择任何平台');
    if (_groupedItems.length == 0) // 载入中（零结果）
      return Center(child: CircularProgressIndicator());
    List<Widget> searchingIndicator = []; // 搜索进度指示器
    List<Widget> searchingView = []; // 搜索中指示器
    if (_platforms.length >
        _groupedItems.length + _excludesPlatformDomains.length) {
      searchingIndicator.add(Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: LinearProgressIndicator(
          value: _groupedItems.length / participantsCount,
        ),
      ));
      searchingView.add(Padding(
        padding:
            EdgeInsets.only(top: searchPageSpacing, bottom: searchPageSpacing),
        child: Center(child: CircularProgressIndicator()),
      ));
    }
    return Scrollbar(
      child: Stack(
        children: [
          ListView(
            children: [
              ..._groupedItems.entries
                  .map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // 平台分组的间距
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                left: searchPageSpacing,
                                top: searchPageSpacing),
                            child: Text(
                              entry.key.name,
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ),
                          SizedBox(height: 10),
                          // 平台包含的标签
                          Padding(
                            padding: EdgeInsets.only(left: searchPageSpacing),
                            child: Wrap(
                              spacing: 6,
                              children: entry.key.tags
                                  .map((t) => Tag(t.value, t.name,
                                      color: Colors.grey[500]))
                                  .toList(),
                            ),
                          ),
                          // 搜索结果
                          entry.value.length == 0
                              ? Padding(
                                  padding: EdgeInsets.all(searchPageSpacing),
                                  child: Text(
                                    '无结果',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: searchResultCoverHeight +
                                      searchPageSpacing * 2,
                                  child: ListView.builder(
                                    padding: EdgeInsets.all(searchPageSpacing),
                                    itemCount: entry.value.length,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (_, index) => Card(
                                      child: Stack(
                                        children: [
                                          // 图片
                                          ExtendedImage.network(
                                            entry.value[index].comic.cover,
                                            fit: BoxFit.cover,
                                            headers: entry
                                                .value[index].comic.headers,
                                            cache: true,
                                            width: searchResultCoverWidth,
                                            height: searchResultCoverHeight,
                                            loadStateChanged: (state) {
                                              switch (state
                                                  .extendedImageLoadState) {
                                                case LoadState.loading:
                                                  return Center(
                                                    child: coverLoadingView,
                                                  );
                                                  break;
                                                case LoadState.failed:
                                                  return Center(
                                                    child: Text(
                                                      entry.value[index].comic
                                                          .title,
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 18),
                                                    ),
                                                  ); // 加载失败显示标题文本
                                                  break;
                                                default:
                                                  return null;
                                                  break;
                                              }
                                            },
                                          ),
                                          // 文字
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                  left: 5,
                                                  top: 20,
                                                  right: 5,
                                                  bottom: 5),
                                              decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                      begin: Alignment
                                                          .bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                    Color.fromARGB(
                                                        120, 0, 0, 0),
                                                    Colors.transparent,
                                                  ])),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      entry.value[index].comic
                                                          .title,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          // 点击事件和效果
                                          Positioned.fill(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ComicPage(
                                                            entry.key,
                                                            entry.value[index]
                                                                .comic),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ))
                  .toList(),
              ...searchingView,
            ],
          ),
          ...searchingIndicator
        ],
      ),
    );
  }

  void _handleSubmit(String value) {
    if (value.isEmpty) return;
    setState(() {
      _submitted = true;
      _keywords = value;
    });
    // 处理搜索
    handleSearch();
  }

  void _handleOpenEditField() {
    setState(() {
      _submitted = false;
    });
    editingController.text = _keywords;
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var showElevation = _submitted &&
            _platforms.length ==
                _groupedItems.length + _excludesPlatformDomains.length ||
        _groupedItems.length == 0;
    var actions = <Widget>[];
    Widget body;
    if (_submitted) {
      // 搜索图标
      actions.add(IconButton(
          icon: Icon(Icons.search), onPressed: _handleOpenEditField));
      body = _buildResultView();
    } else {
      actions.add(IconButton(
        icon: Icon(Icons.close),
        onPressed: _handleSearchClear,
      ));
      // 过滤视图
      body = _buildFilterView();
    }
    return MaterialApp(
      theme: appBarTheme(),
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: showElevation ? null : 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
          title: _submitted
              ? Text('$_keywords')
              : TextField(
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  controller: editingController,
                  onSubmitted: _handleSubmit,
                  decoration: InputDecoration(hintText: '全局搜索'),
                ),
          actions: actions,
        ),
        body: body,
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SearchPage();
}

List<models.Comic> _searchComicsTask(Tuple2<models.Platform, String> args) {
  var platform = args.item1;
  var keywords = args.item2;
  return platform.search(keywords);
}

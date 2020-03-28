import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:mikack_mobile/widgets/favicon.dart';
import 'package:mikack_mobile/widgets/tag.dart';

class _SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

const searchPagePadding = 18.0;

class _SearchPageState extends State<_SearchPage> {
  var _submitted = false;
  String _keywords;
  List<models.Platform> _platforms = platforms();

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
      );
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
          margin: EdgeInsets.all(searchPagePadding),
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
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: _platforms.map((p) {
              var isContains = _excludesPlatformDomains.contains(p.domain);
              return ListTile(
                leading: Favicon(p, size: 20),
                contentPadding: EdgeInsets.only(
                    left: searchPagePadding, right: searchPagePadding),
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
      ],
    );
  }

  void _handleSearchClear() {
    editingController.clear();
  }

  void _handleSubmit(String value) {
    if (value.isEmpty) return;
    setState(() {
      _submitted = true;
      _keywords = value;
    });
  }

  void _handleOpenEditField() {
    setState(() {
      _submitted = false;
    });
    editingController.text = _keywords;
  }

  @override
  Widget build(BuildContext context) {
    var actions = <Widget>[];
    Widget body;
    if (_submitted) {
      // 搜索图标
      actions.add(IconButton(
          icon: Icon(Icons.search), onPressed: _handleOpenEditField));
      body = ListView(
        padding: EdgeInsets.only(
            left: searchPagePadding, right: searchPagePadding, top: 8),
        children: [],
      );
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
        appBar: AppBar(
          elevation: _submitted ? null : 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
          title: _submitted
              ? Text('$_keywords - 搜索结果：')
              : TextField(
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  controller: editingController,
                  onSubmitted: _handleSubmit,
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

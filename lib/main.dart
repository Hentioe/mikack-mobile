import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:quiver/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fragments/libraries.dart';
import 'fragments/bookshelf.dart';
import 'fragments/books_update.dart';
import 'fragments/histories.dart';
import 'pages/base_page.dart';
import 'pages/settings.dart';

// 全部平台列表
final List<models.Platform> platformList = platforms();
const bookshelfSoryByKey = 'bookshelf_sory_by';

void main() => runApp(MyApp());

class MyApp extends BasePage {
  @override
  Widget build(BuildContext context) {
    initSystemUI();
    return MaterialApp(
      title: 'Mikack Mobile',
      theme: ThemeData(
        // This is the theme
        primarySwatch: primaryColor,
      ),
      home: MyHomePage(),
    );
  }
}

final startPages = BiMap<String, String>();

class DrawerItem {
  final String title;
  final IconData iconData;
  final Widget fragment;
  final List<Widget> actions;

  DrawerItem(this.title, this.iconData, this.fragment,
      {this.actions = const []});
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key) {
    startPages.addAll({
      'default': '系统默认',
      'bookshelf': '我的书架',
      'books_update': '书架更新',
      'libraries': '图书仓库',
      'histories': '浏览历史',
    });
  }

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const headerLogoSize = 65.0;

class _MyHomePageState extends State<MyHomePage> {
  int _selectedDrawerIndex = 0;
  List<DrawerItem> _drawerItems = [];
  List<int> _includeTags = [];
  List<int> _excludesTags = [];
  List<models.Platform> _platforms = [];
  BookshelfSortBy _bookshelfSortBy = BookshelfSortBy.readAt;

  @override
  void initState() {
    fetchLockedDrawerIndex();
    fetchPlatforms();
    fetchBookshelfSortBy();
    super.initState();
  }

  void fetchLockedDrawerIndex() async {
    var prefs = await SharedPreferences.getInstance();
    var lockedKey = prefs.getString(startPageKey);
    int index = 0;
    if (lockedKey != null && lockedKey != 'default') {
      var drawerItemName = startPages[lockedKey];
      for (var i = 0; i < _drawerItems.length; i++) {
        if (_drawerItems[i].title == drawerItemName) {
          index = i;
          break;
        }
      }
    }
    setState(() => _selectedDrawerIndex = index);
  }

  void fetchPlatforms() async {
    setState(() {
      _platforms = findPlatforms(
        _includeTags.map((v) => models.Tag(v, '')).toList(),
        _excludesTags.map((v) => models.Tag(v, '')).toList(),
      );
    });
  }

  void fetchBookshelfSortBy() async {
    var prefs = await SharedPreferences.getInstance();
    var sortBy = parseBookshelfSortBy(prefs.getString(bookshelfSoryByKey));
    if (sortBy != _bookshelfSortBy) {
      setState(() => _bookshelfSortBy = sortBy);
    }
  }

  final _header = DrawerHeader(
    decoration: BoxDecoration(color: primaryColor),
    child: Row(
      children: [
        Image.asset(
          'images/logo.png',
          width: headerLogoSize,
          height: headerLogoSize,
        )
      ],
    ),
  );

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // 关闭抽屉
  }

  void _handleSearch() {}

  void _handleLibrariesFilter() {
    var fragment = _drawerItems[_selectedDrawerIndex].fragment;
    if (fragment is LibrariesFragment) {
      fragment
          .openFilter(context, includes: _includeTags, excludes: _excludesTags)
          .then((filters) {
        var includes = filters.item1;
        var excludes = filters.item2;

        setState(() {
          _includeTags = includes;
          _excludesTags = excludes;
        });
        fetchPlatforms();
      });
    }
  }

  Widget _buildBookshelfSortMenuView() {
    return PopupMenuButton<BookshelfSortBy>(
      icon: Icon(Icons.sort),
      onSelected: updateBookshelfSortBy,
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: BookshelfSortBy.readAt,
          child: Text('上次阅读时间'),
        ),
        const PopupMenuItem(
          value: BookshelfSortBy.insertedAt,
          child: Text('最初添加时间'),
        ),
      ],
    );
  }

  void updateBookshelfSortBy(BookshelfSortBy sortBy) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(bookshelfSoryByKey, sortBy.value());
    setState(() => _bookshelfSortBy = sortBy);
  }

  void initDrawerItems() {
    _drawerItems = [
      DrawerItem(
        '我的书架',
        Icons.class_,
        BookshelfFragment(sortBy: _bookshelfSortBy),
        actions: [_buildBookshelfSortMenuView()],
      ),
      DrawerItem('书架更新', Icons.fiber_new, BooksUpdateFragment()),
      DrawerItem(
        '图书仓库',
        Icons.store,
        LibrariesFragment(_platforms),
        actions: [
          IconButton(
              icon: Icon(Icons.filter_list), onPressed: _handleLibrariesFilter)
        ],
      ),
      DrawerItem('浏览历史', Icons.history, HistoriesFragment()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    initDrawerItems();
    var drawerOptions = <Widget>[];
    for (var i = 0; i < _drawerItems.length; i++) {
      var d = _drawerItems[i];
      drawerOptions.add(new ListTile(
        leading: new Icon(d.iconData),
        title: new Text(d.title),
        selected: i == _selectedDrawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_drawerItems[_selectedDrawerIndex].title),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: _handleSearch),
          ..._drawerItems[_selectedDrawerIndex].actions
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header,
            Column(
              children: drawerOptions,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('设置'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage()),
              ),
            ),
          ],
        ),
      ),
      body: _drawerItems[_selectedDrawerIndex].fragment,
    );
  }
}

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/logging.dart';
import 'package:mikack_mobile/pages/search.dart';
import 'package:mikack_mobile/pages/terms.dart';
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
const bookshelfSortByKey = 'bookshelf_sort_by';

final drawerItems = LinkedHashMap.from({
  'default': '系统默认',
  'bookshelf': '我的书架',
  'books_update': '书架更新',
  'libraries': '图书仓库',
  'histories': '浏览历史',
});

const defaultDrawerIndex = 0;

Future<int> getDrawerIndex() async {
  int index = defaultDrawerIndex;
  var prefs = await SharedPreferences.getInstance();
  var lockedKey = prefs.getString(startPageKey);
  if (lockedKey != null && lockedKey != 'default') {
    var entries = drawerItems.entries.toList();
    for (var i = 1; i < entries.length; i++) {
      if (entries[i].key == lockedKey) {
        index = i - 1;
        break;
      }
    }
  }
  return index;
}

void main() async {
  initLogger();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(await getDrawerIndex()));
}

class MyApp extends BasePage {
  MyApp(this.drawerIndex);

  final int drawerIndex;

  @override
  Widget build(BuildContext context) {
    initSystemUI();
    return MaterialApp(
      title: 'Mikack mobile',
      theme: ThemeData(
        // This is the theme
        primarySwatch: primaryColor,
      ),
      home: MyHomePage(drawerIndex: drawerIndex),
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
  MyHomePage({Key key, this.drawerIndex}) : super(key: key) {
    startPages.addEntries(drawerItems.entries.map(
      (entry) => MapEntry(entry.key, entry.value),
    ));
  }

  final int drawerIndex;

  @override
  _MyHomePageState createState() => _MyHomePageState(drawerIndex: drawerIndex);
}

const headerLogoSize = 65.0;
const nsfwTagValue = 4;

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState({drawerIndex = 0}) {
    this._drawerIndex = drawerIndex;
  }

  int _drawerIndex;
  List<DrawerItem> _drawerItems = [];
  List<int> includeTags = [];
  bool allowNsfw = false;
  List<int> excludesTags = [nsfwTagValue];
  List<models.Platform> _platforms = [];
  BookshelfSortBy _bookshelfSortBy = BookshelfSortBy.readAt;

  @override
  void initState() {
    fetchPlatforms();
    fetchBookshelfSortBy();
    fetchAllowNsfw();
    checkPermAccept();
    super.initState();
  }

  void checkPermAccept() async {
    var prefs = await SharedPreferences.getInstance();
    var versionStr = prefs.getString(acceptPermVersionKey);
    if (versionStr == null)
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TermsPage(readOnly: false)));
  }

  void fetchPlatforms() async {
    setState(() {
      _platforms = findPlatforms(
        includeTags.map((v) => models.Tag(v, '')).toList(),
        excludesTags.map((v) => models.Tag(v, '')).toList(),
      );
    });
  }

  void fetchBookshelfSortBy() async {
    var prefs = await SharedPreferences.getInstance();
    var sortBy = parseBookshelfSortBy(prefs.getString(bookshelfSortByKey));
    if (sortBy != _bookshelfSortBy) {
      setState(() => _bookshelfSortBy = sortBy);
    }
  }

  void fetchAllowNsfw() async {
    var prefs = await SharedPreferences.getInstance();
    var isAllow = prefs.getBool(allowNsfwKey);
    if (isAllow == null) isAllow = false;
    allowNsfw = isAllow;
    if (isAllow) {
      // 如果启用，则排除并重写载入
      if (excludesTags.contains(nsfwTagValue)) {
        excludesTags.remove(nsfwTagValue);
        fetchPlatforms();
      }
    } else {
      // 没启用，添加排除标签并删除包含标签
      if (!excludesTags.contains(nsfwTagValue)) {
        excludesTags.add(nsfwTagValue);
        if (includeTags.contains(nsfwTagValue))
          includeTags.remove(nsfwTagValue);
        fetchPlatforms();
      }
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
    setState(() => _drawerIndex = index);
    Navigator.of(context).pop(); // 关闭抽屉
  }

  void _handleLibrariesFilter() {
    var fragment = _drawerItems[_drawerIndex].fragment;
    if (fragment is LibrariesFragment) {
      fragment
          .openFilter(context,
              includes: includeTags,
              excludes: excludesTags,
              allowNsfw: allowNsfw)
          .then((filters) {
        var includes = filters.item1;
        var excludes = filters.item2;

        setState(() {
          includeTags = includes;
          excludesTags = excludes;
        });
        fetchPlatforms();
      });
    }
  }

  Widget _buildBookshelfSortMenuView() {
    return PopupMenuButton<BookshelfSortBy>(
      tooltip: '修改排序方式',
      icon: Icon(Icons.sort),
      onSelected: updateBookshelfSortBy,
      itemBuilder: (BuildContext context) => [
        CheckedPopupMenuItem(
          checked: _bookshelfSortBy == BookshelfSortBy.readAt,
          enabled: _bookshelfSortBy != BookshelfSortBy.readAt,
          value: BookshelfSortBy.readAt,
          child: Text('上次阅读时间'),
        ),
        CheckedPopupMenuItem(
          checked: _bookshelfSortBy == BookshelfSortBy.insertedAt,
          enabled: _bookshelfSortBy != BookshelfSortBy.insertedAt,
          value: BookshelfSortBy.insertedAt,
          child: Text('最初添加时间'),
        ),
      ],
    );
  }

  void updateBookshelfSortBy(BookshelfSortBy sortBy) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(bookshelfSortByKey, sortBy.value());
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
              tooltip: '打开过滤菜单',
              icon: Icon(Icons.filter_list),
              onPressed: _handleLibrariesFilter)
        ],
      ),
      DrawerItem('浏览历史', Icons.history, HistoriesFragment()),
    ];
  }

  Route _createGlobalSearchRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SearchPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    initDrawerItems();
    var drawerListView = <Widget>[];
    for (var i = 0; i < _drawerItems.length; i++) {
      var d = _drawerItems[i];
      drawerListView.add(new ListTile(
        leading: new Icon(d.iconData),
        title: new Text(d.title),
        selected: i == _drawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: '打开导航菜单',
            );
          },
        ),
        title: Text(_drawerItems[_drawerIndex].title),
        actions: [
          IconButton(
            tooltip: '打开全局搜索',
            icon: Icon(Icons.search),
            onPressed: () =>
                Navigator.of(context).push(_createGlobalSearchRoute()),
          ),
          ..._drawerItems[_drawerIndex].actions
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header,
            Column(
              children: drawerListView,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('设置'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage()),
              ).then((_) => fetchAllowNsfw()), // 设置页面返回后刷新可能变更的数据
            ),
          ],
        ),
      ),
      body: _drawerItems[_drawerIndex].fragment,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:quiver/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fragments/libraries.dart';
import 'fragments/bookshelf.dart';
import 'fragments/books_update.dart';
import 'fragments/histories.dart';
import 'pages/base_page.dart';
import 'pages/settings.dart';
import 'pages/settings.dart' show startPageKey;

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
  String title;
  IconData iconData;
  Widget fragment;

  DrawerItem(this.title, this.iconData, this.fragment);
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

  final drawerItems = [
    DrawerItem('我的书架', Icons.class_, BookshelfFragment()),
    DrawerItem('书架更新', Icons.fiber_new, BooksUpdateFragment()),
    DrawerItem('图书仓库', Icons.store, LibrariesFragment()),
    DrawerItem('浏览历史', Icons.history, HistoriesFragment()),
  ];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const headerLogoSize = 65.0;

class _MyHomePageState extends State<MyHomePage> {
  int _selectedDrawerIndex = 0;

  @override
  void initState() {
    fetchLockedDrawerIndex();
    super.initState();
  }

  void fetchLockedDrawerIndex() async {
    var prefs = await SharedPreferences.getInstance();
    var lockedKey = prefs.getString(startPageKey);
    int index = 0;
    if (lockedKey != null && lockedKey != 'default') {
      var drawerItemName = startPages[lockedKey];
      for (var i = 0; i < widget.drawerItems.length; i++) {
        if (widget.drawerItems[i].title == drawerItemName) {
          index = i;
          break;
        }
      }
    }
    setState(() => _selectedDrawerIndex = index);
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

  @override
  Widget build(BuildContext context) {
    var drawerOptions = <Widget>[];
    for (var i = 0; i < widget.drawerItems.length; i++) {
      var d = widget.drawerItems[i];
      drawerOptions.add(new ListTile(
        leading: new Icon(d.iconData),
        title: new Text(d.title),
        selected: i == _selectedDrawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drawerItems[_selectedDrawerIndex].title),
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
      body: widget.drawerItems[_selectedDrawerIndex].fragment,
    );
  }
}

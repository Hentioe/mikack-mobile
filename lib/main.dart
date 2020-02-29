import 'package:flutter/material.dart';
import 'fragments/libraries.dart';

void main() => runApp(MyApp());

const primaryColor = Colors.deepOrange;
const secondaryColor = Colors.deepOrangeAccent;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

class DrawerItem {
  String title;
  IconData iconData;
  Widget fragment;

  DrawerItem(this.title, this.iconData, this.fragment);
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  final drawerItems = [
    DrawerItem('我的书架', Icons.class_, Text('')),
    DrawerItem('书架更新', Icons.history, Text('')),
    DrawerItem('图书仓库', Icons.store, LibrariesFragment()),
    DrawerItem('浏览历史', Icons.history, Text('')),
  ];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const headerLogoSize = 65.0;

class _MyHomePageState extends State<MyHomePage> {
  int _selectedDrawerIndex = 0;
  final _header = DrawerHeader(
    decoration: BoxDecoration(color: secondaryColor),
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
              onTap: () {},
            ),
          ],
        ),
      ),
      body: widget.drawerItems[_selectedDrawerIndex].fragment,
    );
  }
}

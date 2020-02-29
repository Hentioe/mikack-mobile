import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart' as mikack;

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
      home: MyHomePage(title: '我的书架'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const headerLogoSize = 65.0;

class _MyHomePageState extends State<MyHomePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header,
            ListTile(
              leading: Icon(Icons.book),
              title: Text('我的书架'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('书架更新'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.rss_feed),
              title: Text('平台列表'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('浏览历史'),
              onTap: () {},
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
    );
  }
}

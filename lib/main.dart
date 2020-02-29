import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart' as mikack;

void main() => runApp(MyApp());

const _primaryColor = Colors.deepOrange;
const _secondaryColor = Colors.deepOrangeAccent;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mikack Mobile',
      theme: ThemeData(
        // This is the theme
        primarySwatch: _primaryColor,
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

class _MyHomePageState extends State<MyHomePage> {
  var _platforms = mikack.platforms();

  final _header = DrawerHeader(
    decoration: BoxDecoration(color: _secondaryColor),
    child: const Text(
      'MIKACK',
      style: TextStyle(color: Colors.white, fontSize: 22),
    ),
  );

  List<Widget> _buildListViewChild() {
    List<Widget> list = [_header];
    list.addAll(_platforms.map((p) => ListTile(
          leading: Icon(Icons.folder_open),
          title: Text(p.name),
        )));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Text("Hello Mikack!"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: _buildListViewChild(),
        ),
      ),
    );
  }
}

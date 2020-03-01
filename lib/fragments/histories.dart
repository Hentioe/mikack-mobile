import 'package:flutter/material.dart';
import 'package:mikack/src/models.dart' as models;

class HistoriesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: Center(
        child: Text('没有阅读记录',
            style: TextStyle(fontSize: 18, color: Colors.grey[400])),
      ),
    );
  }
}

class MainView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  void initState() {
    // TODO: 读取浏览记录
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HistoriesView();
  }
}

class HistoriesFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainView();
  }
}

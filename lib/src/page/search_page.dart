import 'package:flutter/material.dart';

import '../blocs.dart';
import '../widget/series_system_ui.dart';

class SearchPage2 extends StatefulWidget {
  final BuildContext appContext;

  SearchPage2({this.appContext});

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage2> {
  final TextEditingController editingController = TextEditingController();
  final bloc = SearchBloc();

  @override
  void initState() {
    bloc.add(SearchInitEvent());
    super.initState();
  }

  @override
  void dispose() {
    editingController.dispose();
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SeriesSystemUI(
      child: Text('新搜索页面，实现中……'),
    );
  }
}

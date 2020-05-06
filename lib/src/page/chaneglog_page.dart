import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../widget/series_system_ui.dart';
import '../blocs.dart';

class ChangelogPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  final ChangelogBloc bloc = ChangelogBloc();

  @override
  void initState() {
    bloc.add(ChangelogRequestEvent());
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TextStyle(color: Colors.grey[600], fontSize: 13.5);
    return SeriesSystemUI(
      child: Scaffold(
        appBar: AppBar(
          title: Text('更新日志'),
        ),
        body: BlocListener<ChangelogBloc, ChangelogState>(
          bloc: bloc,
          condition: (prevState, state) =>
              prevState != bloc.initialState &&
              prevState is ChangelogLoadedState &&
              state is ChangelogLoadedState &&
              prevState.error != state.error &&
              state.error.failed,
          listener: (ctx, state) {
            var stateSnapshot = state as ChangelogLoadedState;
            Fluttertoast.showToast(msg: stateSnapshot.error.message);
          },
          child: BlocBuilder<ChangelogBloc, ChangelogState>(
            bloc: bloc,
            builder: (ctx, state) {
              var castedState = state as ChangelogLoadedState;
              if (castedState.error.failed)
                return Center(
                  child: RaisedButton(
                      child: Text('重试'),
                      onPressed: () => bloc.add(ChangelogRequestEvent())),
                );
              if (castedState.loading)
                return Center(
                  child: CircularProgressIndicator(),
                );
              return Scrollbar(
                child: ListView(
                  children: castedState.changelog.map((c) {
                    return ExpansionTile(
                      title: Text(
                        c.release.tagName,
                        style: TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                          DateFormat('yyyy年MM月dd日').format(c.release.createdAt),
                          style: subtitleStyle),
                      children: [
                        Markdown(
                          data: c.release.body,
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 12.5, color: Colors.black),
                          ),
                        )
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

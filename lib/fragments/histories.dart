import 'package:flutter/material.dart';
import 'package:mikack_mobile/fragments/bookshelf.dart';
import 'package:mikack_mobile/helper/chrome.dart';
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:mikack_mobile/store.dart';
import '../pages/read.dart';
import '../ext.dart';

class HistoriesView extends StatelessWidget {
  HistoriesView(this.histories, {this.handleRemove, this.handleContinue});

  final List<History> histories;
  final void Function(History) handleRemove;
  final void Function(History) handleContinue;

  Widget _buildEmptyView() {
    return Center(
      child: Text(
        '没有阅读记录',
        style: TextStyle(fontSize: 18, color: Colors.grey[400]),
      ),
    );
  }

  final cardShape = const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.all(Radius.circular(1)));

  Widget _buildListView() {
    return ListView(
      children: histories
          .map(
            (h) => Card(
              shape: cardShape,
              elevation: 1.5,
              child: Row(
                children: [
                  Image.network(
                    h.cover,
                    headers: h.headers,
                    fit: BoxFit.cover,
                    height: 120,
                    width: 90,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            h.title,
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Wrap(
                            children: [
                              Text(
                                '${h.source.name}',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        ButtonBar(
                          buttonPadding: EdgeInsets.zero,
                          alignment: MainAxisAlignment.start,
                          children: [
                            FlatButton(
                              child: const Text(
                                '移除',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              onPressed: () => handleRemove(h),
                            ),
                            FlatButton(
                              child: const Text(
                                '继续阅读',
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                              onPressed: () => handleContinue(h),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget view;
    if (histories.length == 0)
      view = _buildEmptyView();
    else
      view = _buildListView();
    return Scrollbar(
      child: view,
    );
  }
}

class MainView extends StatefulWidget {
  MainView() : super(key: UniqueKey());

  @override
  State<StatefulWidget> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  List _histories = <History>[];

  @override
  void initState() {
    // 读取浏览记录
    fetchHistories();
    super.initState();
  }

  void removeHistory(History history) async {
    await deleteHistory(history.id);
    fetchHistories();
  }

  void openHistory(History history) async {
    var platform =
        platformList.firstWhere((p) => p.domain == history.source.domain);
    if (platform != null) {
      setNavigationBarColor(readingBackgroundColor);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReadPage(platform, history.asComic(), history.asChapter()),
        ),
      ).then((_) => setSystemUI(primaryColor: primaryColor));
    }
  }

  void fetchHistories() async {
    var histories = await findHistories();
    for (History history in histories) {
      var source = await getSource(id: history.sourceId);
      if (source == null) {
        source = Source(name: '已失效的图源');
      } else {
        var platform =
            platformList.firstWhere((p) => p.domain == source.domain);
        history.headers = platform.buildBaseHeaders();
      }
      history.source = source;
    }
    setState(() => _histories = histories);
  }

  @override
  Widget build(BuildContext context) {
    return HistoriesView(
      _histories,
      handleRemove: removeHistory,
      handleContinue: openHistory,
    );
  }
}

class HistoriesFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainView();
  }
}

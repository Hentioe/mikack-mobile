import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs.dart';
import '../values.dart';
import '../../store.dart';
import '../platform_list.dart';
import '../helper/chrome.dart';
import '../page/read_page.dart';

const _historiesCoverWidth = 90.0;
const _historiesCoverHeight = _historiesCoverWidth / coverRatio;

class HistoriesFragment2 extends StatelessWidget {
  Function() _handleRemove(BuildContext context, History history) =>
      () => BlocProvider.of<HistoriesBloc>(context)
          .add(HistoriesRemoveEvent(history: history));

  Function() _handleOpenHistory(BuildContext context, History history) =>
      () async {
        var platform =
            platformList.firstWhere((p) => p.domain == history.source.domain);
        if (platform != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadPage(
                platform: platform,
                comic: history.asComic(),
                initChapterReadAt: 0,
                chapters: [history.asChapter()],
              ),
            ),
          ).then((_) {
            // 返回后恢复系统 UI 并重新请求数据
            restoreStatusBarColor();
            showSystemUI();
            BlocProvider.of<HistoriesBloc>(context)
                .add(HistoriesRequestEvent());
          });
        }
      };

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

  Widget _buildListView(BuildContext context, List<History> histories) {
    return ListView(
      children: histories
          .map(
            (history) => Card(
              shape: cardShape,
              elevation: 1.5,
              child: Row(
                children: [
                  ExtendedImage.network(
                    history.cover,
                    headers: history.headers,
                    fit: BoxFit.cover,
                    height: _historiesCoverHeight,
                    width: _historiesCoverWidth,
                    cache: true,
                    loadStateChanged: (state) {
                      switch (state.extendedImageLoadState) {
                        case LoadState.failed:
                          return Center(
                            child: Text(
                              '无图',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                          ); // 加载失败显示标题文本
                          break;
                        default:
                          return null;
                          break;
                      }
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            history.title,
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
                                '${history.source.name}',
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
                              onPressed: _handleRemove(context, history),
                            ),
                            FlatButton(
                              child: const Text(
                                '继续阅读',
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                              onPressed: _handleOpenHistory(context, history),
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
    return BlocBuilder<HistoriesBloc, HistoriesState>(
      builder: (context, state) {
        var castedState = state as HistoriesLoadedState;
        if (castedState.histories.isEmpty)
          return _buildEmptyView();
        else
          return Scrollbar(
            child: _buildListView(context, castedState.histories),
          );
      },
    );
  }
}

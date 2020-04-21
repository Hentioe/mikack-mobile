import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikack/models.dart';

import '../platform_list.dart';
import '../blocs.dart';
import '../page/comic_page.dart';
import '../../store.dart';
import '../widget/comics_view.dart';
import '../widget/text_hint.dart';
import '../ext.dart';

class _CenterHint extends StatelessWidget {
  _CenterHint(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return ListView(
          children: [
            Container(
              height: constraints.maxHeight,
              child: TextHint(title),
            )
          ],
        );
      },
    );
  }
}

class UpdatesFragment2 extends StatelessWidget {
  Future<void> Function() _handleRefresh(BuildContext context) => () async =>
      BlocProvider.of<UpdatesBloc>(context).add(UpdatesRequestEvent.remote());

  Future<void> Function() _handleStopRefresh(BuildContext context) =>
      () async => BlocProvider.of<UpdatesBloc>(context)
          .add(UpdatesRequestEvent.stopRefresh());

  void Function(Comic) _handleOpenComicPage(BuildContext context) =>
      (Comic comic) async {
        var favorites = await findFavorites();
        var favorite = favorites.firstWhere((f) => f.address == comic.url);
        if (favorite == null) {
          Fluttertoast.showToast(msg: '收藏已不存在了');
          return;
        }
        var source = await getSource(id: favorite.sourceId);
        if (source == null) {
          Fluttertoast.showToast(msg: '图源已不存在了');
          return;
        }
        var platform =
            platformList.firstWhere((p) => p.domain == source.domain);
        if (platform == null) {
          Fluttertoast.showToast(msg: '已不支持这个平台了哦');
          return;
        }
        comic.headers = platform.buildBaseHeaders();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComicPage(
              initPageIndex: 1,
              platform: platform,
              comic: comic,
              appContext: context,
            ),
          ),
        ).then((_) => BlocProvider.of<UpdatesBloc>(context)
            .add(UpdatesRequestEvent.local()));
      };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: BlocBuilder<UpdatesBloc, UpdatesState>(
        builder: (context, state) {
          if (state is UpdatesLocalLoadedState) {
            // 来自本地数据
            if (state.viewItems.length == 0)
              return _CenterHint('下拉检查更新');
            else
              return Scrollbar(
                child: ComicsView(
                  state.viewItems,
                  showBadge: true,
                  showPlatform: true,
                  onTap: _handleOpenComicPage(context),
                ),
              );
          }
          var remoteState = state as UpdatesRemoteLoadedState;
          var children = <Widget>[];
          // 主体内容
          if (!remoteState.isCompleted &&
              (remoteState.progress == 0 || remoteState.viewItems.length == 0))
            children.add(_CenterHint('正在检查更新…'));
          else if (remoteState.isCompleted && remoteState.viewItems.length == 0)
            children.add(_CenterHint('暂未发现更新'));
          else
            children.add(Scrollbar(
              child: ComicsView(
                remoteState.viewItems,
                showBadge: true,
                showPlatform: true,
                onTap: _handleOpenComicPage(context),
              ),
            ));
          // 加载进度指示器
          if (!remoteState.isCompleted) {
            if (remoteState.progress > 0)
              children.add(Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                    value: remoteState.progress / remoteState.total),
              ));
            else
              children.add(Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ));
          }
          // 停止更新浮动按钮
          if (!remoteState.isCompleted)
            children.add(Positioned(
              bottom: 15,
              right: 15,
              child: FloatingActionButton(
                tooltip: '停止更新',
                child: Icon(Icons.stop),
                onPressed: _handleStopRefresh(context),
              ),
            ));
          return Stack(
            children: children,
          );
        },
      ),
      onRefresh: _handleRefresh(context),
    );
  }
}

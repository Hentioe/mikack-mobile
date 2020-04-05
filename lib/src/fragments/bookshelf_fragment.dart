import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikack/models.dart';

import '../blocs.dart';
import '../platform_list.dart';
import '../../widgets/comics_view.dart';
import '../../store.dart';
import '../../pages/comic.dart';
import '../../ext.dart';

final _defaultTextStyle = TextStyle(fontSize: 18, color: Colors.grey[500]);
const _hintTextFontSize = 16.0;
const _hintButtonFontWeight = FontWeight.bold;
final _hintTextStyle =
    TextStyle(fontSize: _hintTextFontSize, color: Colors.grey[600]);
final _librariesHintButtonTextStyle = TextStyle(
    fontSize: _hintTextFontSize,
    color: Colors.greenAccent,
    fontWeight: _hintButtonFontWeight);
final _globalSearchHintButtonTextStyle = TextStyle(
    fontSize: _hintTextFontSize,
    color: Colors.purpleAccent,
    fontWeight: _hintButtonFontWeight);

class BookshelfFragment2 extends StatelessWidget {
  final void Function() openLibrariesPage;
  final void Function() openGlobalSearchPage;

  BookshelfFragment2({
    @required this.openLibrariesPage,
    @required this.openGlobalSearchPage,
  });

  void Function(Comic comic) _handleOpenComicPage(
    BuildContext context,
    List<Favorite> favorites,
  ) =>
      (Comic comic) async {
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
            builder: (context) => ComicPage(platform, comic),
          ),
        ).then((_) => BlocProvider.of<BookshelfBloc>(context)
            .add(BookshelfRequestEvent.sortByDefault()));
      };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookshelfBloc, BookshelfState>(
        builder: (context, state) {
      var loadedState = state as BookshelfLoadedState;

      if (loadedState.viewItems.length == 0)
        return Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '书架空空如也',
                style: _defaultTextStyle,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '您可以来',
                    style: _hintTextStyle,
                  ),
                  MaterialButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      '图书仓库',
                      style: _librariesHintButtonTextStyle,
                    ),
                    onPressed: openLibrariesPage,
                  ),
                  Text(
                    '看看或',
                    style: _hintTextStyle,
                  ),
                  MaterialButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      '全局搜索',
                      style: _globalSearchHintButtonTextStyle,
                    ),
                    onPressed: openGlobalSearchPage,
                  ),
                  Text(
                    '找找',
                    style: _hintTextStyle,
                  ),
                ],
              )
            ],
          ),
        );
      return ComicsView(
        loadedState.viewItems,
        showPlatform: true,
        onTap: _handleOpenComicPage(context, loadedState.favorites),
      );
    });
  }
}

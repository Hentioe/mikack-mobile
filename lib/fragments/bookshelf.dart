import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/store.dart';
import '../widgets/comics_view.dart';
import '../ext.dart';
import '../pages/comic.dart';

final List<models.Platform> platformList = platforms();

class BooksView extends StatelessWidget {
  BooksView(
    this.comics, {
    this.handleCancelFavorite,
    this.handleOpen,
  });

  final void Function(models.Comic) handleCancelFavorite;
  final List<models.Comic> comics;
  final Function(models.Comic) handleOpen;

  @override
  Widget build(BuildContext context) {
    if (comics.length == 0)
      return Center(
        child: Text(
          '书架空空如也',
          style: TextStyle(fontSize: 18, color: Colors.grey[400]),
        ),
      );
    return Scrollbar(
      child: ComicsView(
        comics,
        enableFavorite: true,
        handleFavorite: (models.Comic comic, bool isCancel) =>
            {if (isCancel) handleCancelFavorite(comic)},
        favoriteAddresses: comics.map((c) => c.url).toList(),
        onTap: handleOpen,
      ),
    );
  }
}

class MainView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  List<Favorite> _favorites = [];

  @override
  void initState() {
    // 读取并更新书架
    fetchFavorites();
    super.initState();
  }

  void fetchFavorites() async {
    var favorites = await findFavorites();
    for (var i = 0; i < favorites.length; i++) {
      var source = await getSource(id: favorites[i].sourceId);
      favorites[i].source = source;
    }
    setState(() => _favorites = favorites);
  }

  void _handleCancelFavorite(models.Comic comic) async {
    await deleteFavorite(address: comic.url);
    setState(() {
      _favorites.removeWhere((f) => f.address == comic.url);
    });
  }

  List<models.Comic> comicsAttachHeaders() {
    return _favorites.map((f) {
      var comic = f.toComic();
      var platform =
          platformList.firstWhere((p) => p.domain == f.source.domain);
      comic.headers = platform.buildBaseHeaders();
      return comic;
    }).toList();
  }

  void _openComicPage(models.Comic comic) async {
    var favorite = _favorites.firstWhere((f) => f.address == comic.url);
    if (favorite == null) {
      // TODO: 收藏已不存在了
    }
    var source = await getSource(id: favorite.sourceId);
    if (source == null) {
      // TODO: 图源已不存在了
    }
    var platform =
        findPlatforms([], []).firstWhere((p) => p.domain == source.domain);
    if (platform == null) {
      // TODO: 已不支持这个平台了哦
    }
    comic.headers = platform.buildBaseHeaders();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicPage(platform, comic),
      ),
    ).then((_) => fetchFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return BooksView(
      comicsAttachHeaders(),
      handleCancelFavorite: _handleCancelFavorite,
      handleOpen: _openComicPage,
    );
  }
}

class BookshelfFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MainView();
  }
}

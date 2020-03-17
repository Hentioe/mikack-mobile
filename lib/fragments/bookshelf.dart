import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart' as models;
import 'package:mikack_mobile/store.dart';
import '../widgets/comics_view.dart';
import '../ext.dart';
import '../pages/comic.dart';

final List<models.Platform> platformList = platforms();

enum BookshelfSortBy { readAt, insertedAt }

const _readAt = 'read_at';
const _insertedAt = 'inserted_at';

extension BookshelfSortByExt on BookshelfSortBy {
  String value() {
    switch (this) {
      case BookshelfSortBy.readAt:
        return _readAt;
      case BookshelfSortBy.insertedAt:
        return _insertedAt;
      default:
        return _readAt;
    }
  }
}

BookshelfSortBy parseBookshelfSortBy(String value,
    {BookshelfSortBy orValue = BookshelfSortBy.readAt}) {
  switch (value) {
    case _readAt:
      return BookshelfSortBy.readAt;
    case _insertedAt:
      return BookshelfSortBy.insertedAt;
    default:
      return orValue;
  }
}

class BooksView extends StatelessWidget {
  BooksView(
    this.comics, {
    this.handleCancelFavorite,
    this.handleOpen,
  });

  final void Function(models.Comic) handleCancelFavorite;
  final List<ComicViewItem> comics;
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
      child: ComicsView(comics, showPlatform: true, onTap: handleOpen),
    );
  }
}

class MainView extends StatefulWidget {
  MainView({this.sortBy}) : super(key: UniqueKey());

  final BookshelfSortBy sortBy;

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
    var favorites = await findFavorites(sortBy: widget.sortBy);
    for (var i = 0; i < favorites.length; i++) {
      var source = await getSource(id: favorites[i].sourceId);
      favorites[i].source = source;
    }
    if (mounted) setState(() => _favorites = favorites);
  }

  void _handleCancelFavorite(models.Comic comic) async {
    await deleteFavorite(address: comic.url);
    setState(() {
      _favorites.removeWhere((f) => f.address == comic.url);
    });
  }

  List<ComicViewItem> makeViewItems() {
    return _favorites.map((f) {
      var comic = f.toComic();
      var platform =
          platformList.firstWhere((p) => p.domain == f.source.domain);
      comic.headers = platform.buildBaseHeaders();
      return comic.toViewItem(platform: platform);
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
      makeViewItems(),
      handleCancelFavorite: _handleCancelFavorite,
      handleOpen: _openComicPage,
    );
  }
}

class BookshelfFragment extends StatelessWidget {
  BookshelfFragment({this.sortBy = BookshelfSortBy.readAt});

  final BookshelfSortBy sortBy;

  @override
  Widget build(BuildContext context) {
    return MainView(sortBy: sortBy);
  }
}

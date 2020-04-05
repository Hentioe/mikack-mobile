import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bookshelf_event.dart';
import 'bookshelf_state.dart';
import '../models.dart';
import '../../store.dart';
import '../../ext.dart';
import '../platform_list.dart';
import '../../main.dart' show bookshelfSortByKey;

class BookshelfBloc extends Bloc<BookshelfEvent, BookshelfState> {
  @override
  BookshelfState get initialState => BookshelfLoadedState(
        favorites: const [],
        viewItems: const [],
        sortBy: null,
      );

  @override
  Stream<BookshelfState> mapEventToState(BookshelfEvent event) async* {
    switch (event.runtimeType) {
      case BookshelfRequestEvent: // 请求数据
        var castedEvent = event as BookshelfRequestEvent;
        var prefs = await SharedPreferences.getInstance();
        var sortBy = castedEvent.sortBy;
        if (sortBy == null)
          sortBy = parseBookshelfSortBy(prefs.getString(bookshelfSortByKey));
        else
          prefs.setString(bookshelfSortByKey, sortBy.value());

        yield await getLoadedState(sortBy);
        break;
    }
  }

  Future<BookshelfLoadedState> getLoadedState(BookshelfSortBy sortBy) async {
    var favorites = await findFavorites(sortBy: sortBy);
    for (var i = 0; i < favorites.length; i++) {
      var source = await getSource(id: favorites[i].sourceId);
      favorites[i].source = source;
    }
    var viewItems = favorites.map((f) {
      var comic = f.toComic();
      var platform =
          platformList.firstWhere((p) => p.domain == f.source.domain);
      comic.headers = platform.buildBaseHeaders();
      return comic.toViewItem(platform: platform);
    }).toList();

    return BookshelfLoadedState(
      favorites: favorites,
      viewItems: viewItems,
      sortBy: sortBy,
    );
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}

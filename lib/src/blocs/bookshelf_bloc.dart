import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bookshelf_event.dart';
import 'bookshelf_state.dart';
import '../models.dart';
import '../../store.dart';
import '../ext.dart';
import '../platform_list.dart';
import '../../main.dart' show bookshelfSortByKey;

class BookshelfBloc extends Bloc<BookshelfEvent, BookshelfState> {
  @override
  BookshelfState get initialState => BookshelfLoadedState(
        favorites: const [],
        viewItems: const [],
        sortBy: null,
      );

  BookshelfSort lastSortBy;

  @override
  Stream<BookshelfState> mapEventToState(BookshelfEvent event) async* {
    switch (event.runtimeType) {
      case BookshelfRequestEvent: // 请求数据
        var castedEvent = event as BookshelfRequestEvent;
        var sortBy = castedEvent.sortBy;
        if (sortBy == null) {
          if (lastSortBy == null) {
            // 初次默认排序，读取排序配置
            var prefs = await SharedPreferences.getInstance();
            sortBy = parseBookshelfSort(prefs.getString(bookshelfSortByKey));
            lastSortBy = sortBy;
          } else // 直接返回上次排序方式
            sortBy = lastSortBy;
        } else {
          // 设置排序方式
          var prefs = await SharedPreferences.getInstance();
          prefs.setString(bookshelfSortByKey, sortBy.value());
          lastSortBy = sortBy;
        }

        yield await getLoadedState(sortBy);
        break;
    }
  }

  Future<BookshelfLoadedState> getLoadedState(BookshelfSort sortBy) async {
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

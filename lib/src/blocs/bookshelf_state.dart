import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../widget/comics_view.dart' show ComicViewItem;
import '../../store/models.dart';
import '../models.dart';

abstract class BookshelfState extends Equatable {
  @override
  List<Object> get props => [];
}

class BookshelfLoadedState extends BookshelfState {
  final List<Favorite> favorites;
  final List<ComicViewItem> viewItems;
  final BookshelfSortBy sortBy;

  BookshelfLoadedState({
    @required this.favorites,
    @required this.viewItems,
    @required this.sortBy,
  });

  @override
  List<Object> get props => [favorites, viewItems, sortBy];
}

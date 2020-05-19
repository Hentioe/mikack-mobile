import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../widget/comics_view.dart' show ComicViewItem;
import '../../store/models.dart';
import '../models.dart';

abstract class BookshelvesState extends Equatable {
  @override
  List<Object> get props => [];
}

class BookshelvesLoadedState extends BookshelvesState {
  final List<Favorite> favorites;
  final List<ComicViewItem> viewItems;
  final BookshelvesSort sortBy;

  BookshelvesLoadedState({
    @required this.favorites,
    @required this.viewItems,
    @required this.sortBy,
  });

  @override
  List<Object> get props => [favorites, viewItems, sortBy];
}

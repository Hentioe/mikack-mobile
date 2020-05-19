import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../models.dart';

abstract class BookshelvesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class BookshelvesRequestEvent extends BookshelvesEvent {
  final BookshelvesSort sortBy;

  BookshelvesRequestEvent({@required this.sortBy});

  @override
  List<Object> get props => [sortBy];

  factory BookshelvesRequestEvent.sortByReadAt() =>
      BookshelvesRequestEvent(sortBy: BookshelvesSort.readAt);

  factory BookshelvesRequestEvent.sortByInsertedAt() =>
      BookshelvesRequestEvent(sortBy: BookshelvesSort.insertedAt);

  factory BookshelvesRequestEvent.sortByDefault() =>
      BookshelvesRequestEvent(sortBy: null);
}

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../models.dart';

abstract class BookshelfEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class BookshelfRequestEvent extends BookshelfEvent {
  final BookshelfSort sortBy;

  BookshelfRequestEvent({@required this.sortBy});

  @override
  List<Object> get props => [sortBy];

  factory BookshelfRequestEvent.sortByReadAt() =>
      BookshelfRequestEvent(sortBy: BookshelfSort.readAt);

  factory BookshelfRequestEvent.sortByInsertedAt() =>
      BookshelfRequestEvent(sortBy: BookshelfSort.insertedAt);

  factory BookshelfRequestEvent.sortByDefault() =>
      BookshelfRequestEvent(sortBy: null);
}

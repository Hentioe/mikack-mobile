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

parseBookshelfSortBy(
  String value, {
  BookshelfSortBy orValue = BookshelfSortBy.readAt,
}) {
  switch (value) {
    case _readAt:
      return BookshelfSortBy.readAt;
    case _insertedAt:
      return BookshelfSortBy.insertedAt;
    default:
      return orValue;
  }
}

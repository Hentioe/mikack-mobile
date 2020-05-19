enum BookshelvesSort { readAt, insertedAt }

const _readAt = 'read_at';
const _insertedAt = 'inserted_at';

extension BookshelvesSortByExt on BookshelvesSort {
  String value() {
    switch (this) {
      case BookshelvesSort.readAt:
        return _readAt;
      case BookshelvesSort.insertedAt:
        return _insertedAt;
      default:
        return _readAt;
    }
  }
}

parseBookshelvesSort(
  String value, {
  BookshelvesSort orValue = BookshelvesSort.readAt,
}) {
  switch (value) {
    case _readAt:
      return BookshelvesSort.readAt;
    case _insertedAt:
      return BookshelvesSort.insertedAt;
    default:
      return orValue;
  }
}

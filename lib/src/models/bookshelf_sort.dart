enum BookshelfSort { readAt, insertedAt }

const _readAt = 'read_at';
const _insertedAt = 'inserted_at';

extension BookshelfSortByExt on BookshelfSort {
  String value() {
    switch (this) {
      case BookshelfSort.readAt:
        return _readAt;
      case BookshelfSort.insertedAt:
        return _insertedAt;
      default:
        return _readAt;
    }
  }
}

parseBookshelfSort(
  String value, {
  BookshelfSort orValue = BookshelfSort.readAt,
}) {
  switch (value) {
    case _readAt:
      return BookshelfSort.readAt;
    case _insertedAt:
      return BookshelfSort.insertedAt;
    default:
      return orValue;
  }
}

import 'package:equatable/equatable.dart';

import '../values.dart';
import '../exceptions.dart';

class StartPageItem extends Equatable {
  final String key;

  StartPageItem(this.key)
      : assert(
          key == kDefaultPage ||
              key == kBookshelfPage ||
              key == kBooksUpdatePage ||
              key == kLibrariesPage ||
              key == kHistoriesPage,
        );

  @override
  List<Object> get props => [key];

  @override
  String toString() {
    switch (key) {
      case kDefaultPage:
        return '系统默认';
      case kBookshelfPage:
        return '我的书架';
      case kBooksUpdatePage:
        return '书架更新';
      case kLibrariesPage:
        return '图书仓库';
      case kHistoriesPage:
        return '浏览历史';
      default:
        throw UnknownException('Unknown start page');
    }
  }
}

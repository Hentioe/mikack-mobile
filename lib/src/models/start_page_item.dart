import 'package:equatable/equatable.dart';

import '../values.dart';
import '../exceptions.dart';

class StartPageItem extends Equatable {
  final String key;

  StartPageItem(this.key)
      : assert(
          key == vDefaultPage ||
              key == vBookshelfPage ||
              key == vBooksUpdatePage ||
              key == vLibrariesPage ||
              key == vHistoriesPage,
        );

  @override
  List<Object> get props => [key];

  @override
  String toString() {
    switch (key) {
      case vDefaultPage:
        return '系统默认';
      case vBookshelfPage:
        return '我的书架';
      case vBooksUpdatePage:
        return '书架更新';
      case vLibrariesPage:
        return '图书仓库';
      case vHistoriesPage:
        return '浏览历史';
      default:
        throw UnknownException('Unknown start page');
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:mikack/models.dart';

import '../ext.dart';

abstract class LibrariesState extends Equatable {
  @override
  List<Object> get props => [];
}

class LibrariesGroupedListState extends LibrariesState {
  LibrariesGroupedListState({
    @required this.fixedList,
    @required this.filteredList,
  });

  final List<Platform> fixedList;
  final List<Platform> filteredList;

  /// 从过滤列表中排除已固定的列表
  List<Platform> get fixedHiddenFilteredList =>
      [...filteredList]..removeWhere((p) => fixedList.containsDomain(p.domain));

  @override
  List<Object> get props => [fixedList, filteredList];

  LibrariesGroupedListState copyWith(
      {List<Platform> fixedList, List<Platform> filteredList}) {
    return LibrariesGroupedListState(
      fixedList: fixedList ?? this.fixedList,
      filteredList: filteredList ?? this.filteredList,
    );
  }
}

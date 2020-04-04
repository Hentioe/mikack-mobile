import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:mikack/models.dart';

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

  @override
  List<Object> get props => [fixedList, filteredList];

  LibrariesGroupedListState copyWith(
      {List<Platform> fixedList, List<Platform> filteredList}) {
    return LibrariesGroupedListState(
      fixedList: fixedList ?? this.fixedList,
      filteredList: filteredList ?? this.filteredList,
    );
  }

  int allCount() => fixedList.length + filteredList.length;
}

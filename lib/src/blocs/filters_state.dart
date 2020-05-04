import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

abstract class FiltersState extends Equatable {}

class FiltersLoadedState extends FiltersState {
  final bool isAllowNsfw;
  final Set<int> includes;
  final Set<int> excludes;

  FiltersLoadedState({
    @required this.isAllowNsfw,
    @required this.includes,
    @required this.excludes,
  });

  @override
  List<Object> get props => [isAllowNsfw, includes, excludes];

  FiltersLoadedState copyWith({
    bool isAllowNsfw,
    Set<int> includes,
    Set<int> excludes,
  }) =>
      FiltersLoadedState(
        isAllowNsfw: isAllowNsfw ?? this.isAllowNsfw,
        includes: includes ?? this.includes,
        excludes: excludes ?? this.excludes,
      );
}

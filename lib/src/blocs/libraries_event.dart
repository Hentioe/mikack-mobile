import 'package:equatable/equatable.dart';

abstract class LibrariesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LibrariesFiltersUpdatedEvent extends LibrariesEvent {
  LibrariesFiltersUpdatedEvent({
    this.includes = const <int>[],
    this.excludes = const <int>[],
  });

  final List<int> includes;
  final List<int> excludes;

  @override
  List<Object> get props => [includes, excludes];
}

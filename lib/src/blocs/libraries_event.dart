import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart' as models;

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

class LibrariesFixedUpdatedEvent extends LibrariesEvent {
  LibrariesFixedUpdatedEvent({
    @required this.platform,
    @required this.filteredList,
    @required this.fromFixed,
  });

  final models.Platform platform;
  final List<models.Platform> filteredList;
  final bool fromFixed;

  @override
  List<Object> get props => [platform, filteredList, fromFixed];
}

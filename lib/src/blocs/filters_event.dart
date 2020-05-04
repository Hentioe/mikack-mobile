import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import 'libraries_bloc.dart';

abstract class FiltersEvent extends Equatable {}

class FiltersRequestEvent extends FiltersEvent {
  final LibrariesBloc historiesBloc;

  FiltersRequestEvent({this.historiesBloc});

  @override
  List<Object> get props => [historiesBloc];
}

enum FiltersUpdateAction { removed, added }
enum FiltersUpdateFrom { includes, excludes }

class FiltersUpdatedEvent extends FiltersEvent {
  final FiltersUpdateAction action;
  final FiltersUpdateFrom from;
  final int value;
  final LibrariesBloc historiesBloc;

  FiltersUpdatedEvent({
    @required this.action,
    @required this.from,
    @required this.value,
    this.historiesBloc,
  });

  @override
  List<Object> get props => [action, from, value, historiesBloc];
}

class FiltersAllowNsfwUpdatedEvent extends FiltersEvent {
  final bool isAllow;
  final LibrariesBloc historiesBloc;

  FiltersAllowNsfwUpdatedEvent({@required this.isAllow, this.historiesBloc});

  @override
  List<Object> get props => [isAllow, historiesBloc];
}

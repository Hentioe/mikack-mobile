import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:mikack/models.dart';

abstract class LibrariesState extends Equatable {
  @override
  List<Object> get props => [];
}

class LibrariesFilteredState extends LibrariesState {
  LibrariesFilteredState({@required this.list});

  final List<Platform> list;

  @override
  List<Object> get props => [list];
}

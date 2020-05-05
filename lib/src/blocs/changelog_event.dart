import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../models.dart';

abstract class ChangelogEvent extends Equatable {}

class ChangelogRequestEvent extends ChangelogEvent {
  @override
  List<Object> get props => [];
}

class ChangelogLoadedEvent extends ChangelogEvent {
  final List<Change> changelog;

  ChangelogLoadedEvent({@required this.changelog});

  @override
  List<Object> get props => [changelog];
}

class ChangelogErrorOccurred extends ChangelogEvent {
  final String message;

  ChangelogErrorOccurred({@required this.message});

  @override
  List<Object> get props => [message];
}

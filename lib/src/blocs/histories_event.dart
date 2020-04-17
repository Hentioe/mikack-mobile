import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../../store.dart';

class HistoriesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class HistoriesRequestEvent extends HistoriesEvent {
  @override
  List<Object> get props => [];
}

class HistoriesRemoveEvent extends HistoriesEvent {
  final History history;

  HistoriesRemoveEvent({@required this.history});

  @override
  List<Object> get props => [history];
}

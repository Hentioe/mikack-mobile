import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../../store.dart';

class HistoriesState extends Equatable {
  @override
  List<Object> get props => [];
}

class HistoriesLoadedState extends HistoriesState {
  final List<History> histories;

  HistoriesLoadedState({@required this.histories});

  @override
  List<Object> get props => [histories];

  HistoriesLoadedState copyWith({List<History> histories}) {
    return HistoriesLoadedState(histories: histories ?? this.histories);
  }
}

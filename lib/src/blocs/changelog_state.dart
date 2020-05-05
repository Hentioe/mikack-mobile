import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../models.dart';

abstract class ChangelogState extends Equatable {}

class ChangelogLoadedState extends ChangelogState {
  final ErrorWrapper error;
  final bool loading;
  final String currentVersion;
  final List<Change> changelog;

  ChangelogLoadedState({
    this.error = noneError,
    this.loading = false,
    this.currentVersion,
    @required this.changelog,
  });

  @override
  List<Object> get props => [error, loading, currentVersion, changelog];

  ChangelogLoadedState copyWith({
    ErrorWrapper error,
    bool loading,
    String currentVersion,
    List<Change> changelog,
  }) =>
      ChangelogLoadedState(
        error: error ?? this.error,
        loading: loading ?? this.loading,
        currentVersion: currentVersion ?? this.currentVersion,
        changelog: changelog ?? this.changelog,
      );
}

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart';

class ComicState extends Equatable {
  @override
  List<Object> get props => [];
}

class ComicLoadedState extends ComicState {
  final int tabIndex;
  final error;
  final Comic comic;
  final bool isFavorite;
  final bool reversed;
  final readHistoryAddresses;
  final String lastReadAt;

  ComicLoadedState({
    @required this.tabIndex,
    this.error = false,
    @required this.comic,
    @required this.isFavorite,
    this.reversed = false,
    this.readHistoryAddresses = const <String>[],
    this.lastReadAt,
  });

  @override
  List<Object> get props =>
      [tabIndex, error, comic, isFavorite, reversed, readHistoryAddresses];

  ComicLoadedState copyWith({
    int tabIndex,
    bool error,
    Comic comic,
    bool isFavorite,
    bool reversed,
    List<String> readHistoryAddresses,
    String lastReadAt,
  }) {
    return ComicLoadedState(
      tabIndex: tabIndex ?? this.tabIndex,
      error: error ?? this.error,
      comic: comic ?? this.comic,
      isFavorite: isFavorite ?? this.isFavorite,
      reversed: reversed ?? this.reversed,
      readHistoryAddresses: readHistoryAddresses ?? this.readHistoryAddresses,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}

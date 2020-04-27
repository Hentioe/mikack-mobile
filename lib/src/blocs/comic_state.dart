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
  final int columns;
  final List<String> readHistoryAddresses;
  final String lastReadAt;
  final bool isShowToolBar;
  final bool isShowFavoriteButton;

  ComicLoadedState({
    @required this.tabIndex,
    this.error = false,
    @required this.comic,
    @required this.isFavorite,
    this.reversed = false,
    @required this.columns,
    this.readHistoryAddresses = const <String>[],
    this.lastReadAt,
    @required this.isShowToolBar,
    @required this.isShowFavoriteButton,
  });

  @override
  List<Object> get props => [
        tabIndex,
        error,
        comic,
        isFavorite,
        reversed,
        columns,
        readHistoryAddresses,
        lastReadAt,
        isShowToolBar,
        isShowFavoriteButton,
      ];

  ComicLoadedState copyWith({
    int tabIndex,
    bool error,
    Comic comic,
    bool isFavorite,
    bool reversed,
    int columns,
    List<String> readHistoryAddresses,
    String lastReadAt,
    bool isShowToolBar,
    bool isShowFavoriteButton,
  }) {
    return ComicLoadedState(
      tabIndex: tabIndex ?? this.tabIndex,
      error: error ?? this.error,
      comic: comic ?? this.comic,
      isFavorite: isFavorite ?? this.isFavorite,
      reversed: reversed ?? this.reversed,
      columns: columns ?? this.columns,
      readHistoryAddresses: readHistoryAddresses ?? this.readHistoryAddresses,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isShowToolBar: isShowToolBar ?? this.isShowToolBar,
      isShowFavoriteButton: isShowFavoriteButton ?? this.isShowFavoriteButton,
    );
  }
}

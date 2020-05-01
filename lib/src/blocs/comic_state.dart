import 'package:flutter/material.dart';
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
  final int layoutColumns;
  final List<String> readHistoryAddresses;
  final String lastReadAt;
  final bool isShowToolBar;
  final bool isShowFavoriteButton;
  final bool isShowAppBarTitle;
  final Color appBarColor;

  ComicLoadedState({
    @required this.tabIndex,
    this.error = false,
    @required this.comic,
    @required this.isFavorite,
    this.reversed = false,
    @required this.layoutColumns,
    this.readHistoryAddresses = const <String>[],
    this.lastReadAt,
    @required this.isShowToolBar,
    @required this.isShowFavoriteButton,
    @required this.isShowAppBarTitle,
    @required this.appBarColor,
  });

  @override
  List<Object> get props => [
        tabIndex,
        error,
        comic,
        isFavorite,
        reversed,
        layoutColumns,
        readHistoryAddresses,
        lastReadAt,
        isShowToolBar,
        isShowFavoriteButton,
        isShowAppBarTitle,
        appBarColor,
      ];

  ComicLoadedState copyWith({
    int tabIndex,
    bool error,
    Comic comic,
    bool isFavorite,
    bool reversed,
    int layoutColumns,
    List<String> readHistoryAddresses,
    String lastReadAt,
    bool isShowToolBar,
    bool isShowFavoriteButton,
    bool isShowAppBarTitle,
    Color appBarColor,
  }) {
    return ComicLoadedState(
      tabIndex: tabIndex ?? this.tabIndex,
      error: error ?? this.error,
      comic: comic ?? this.comic,
      isFavorite: isFavorite ?? this.isFavorite,
      reversed: reversed ?? this.reversed,
      layoutColumns: layoutColumns ?? this.layoutColumns,
      readHistoryAddresses: readHistoryAddresses ?? this.readHistoryAddresses,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isShowToolBar: isShowToolBar ?? this.isShowToolBar,
      isShowFavoriteButton: isShowFavoriteButton ?? this.isShowFavoriteButton,
      isShowAppBarTitle: isShowAppBarTitle ?? this.isShowAppBarTitle,
      appBarColor: appBarColor ?? this.appBarColor,
    );
  }
}

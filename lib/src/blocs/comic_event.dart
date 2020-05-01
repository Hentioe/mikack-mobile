import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart';

abstract class ComicEvent extends Equatable {}

class ComicLoadedEvent extends ComicEvent {
  final Comic comic;

  ComicLoadedEvent({@required this.comic});

  @override
  List<Object> get props => [comic];
}

class ComicFetchErrorEvent extends ComicEvent {
  @override
  List<Object> get props => [];
}

class ComicRetryEvent extends ComicEvent {
  @override
  List<Object> get props => [];
}

class ComicTabChangedEvent extends ComicEvent {
  final int index;

  ComicTabChangedEvent({@required this.index});

  @override
  List<Object> get props => [index];
}

class ComicRequestEvent extends ComicEvent {
  @override
  List<Object> get props => [];
}

class ComicReverseEvent extends ComicEvent {
  @override
  List<Object> get props => [];
}

class ComicFavoriteEvent extends ComicEvent {
  final bool isCancel;

  ComicFavoriteEvent({this.isCancel});

  @override
  List<Object> get props => [isCancel];
}

class ComicReadHistoriesUpdateEvent extends ComicEvent {
  @override
  List<Object> get props => [];
}

enum ComicReadingMarkType { readOne, readBefore, unreadOne }

class ComicReadingMarkUpdateEvent extends ComicEvent {
  final ComicReadingMarkType markType;
  final Chapter chapter;
  final List<Chapter> chapters;

  ComicReadingMarkUpdateEvent({
    @required this.markType,
    this.chapter,
    this.chapters,
  });

  @override
  List<Object> get props => [markType, chapter, chapters];
}

class ComicReadingMarkCleanRequestEvent extends ComicEvent {
  @override
  List<Object> get props => [];
}

class ComicChapterColumnsChangedEvent extends ComicEvent {
  final int layoutColumns;

  ComicChapterColumnsChangedEvent({@required this.layoutColumns});

  @override
  List<Object> get props => [layoutColumns];
}

class ComicVisibilityUpdateEvent extends ComicEvent {
  final bool showToolBar;
  final bool showFavoriteButton;
  final bool showAppBarTitle;

  ComicVisibilityUpdateEvent(
      {this.showToolBar, this.showFavoriteButton, this.showAppBarTitle});

  @override
  List<Object> get props => [showToolBar, showFavoriteButton, showAppBarTitle];
}

class ComicAppBarBackgroundChangedEvent extends ComicEvent {
  final Color color;

  ComicAppBarBackgroundChangedEvent({@required this.color});

  @override
  List<Object> get props => [color];
}

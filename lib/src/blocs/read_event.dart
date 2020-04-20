import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart' as models;

abstract class ReadEvent extends Equatable {}

class ReadCreatePageIteratorEvent extends ReadEvent {
  final models.Chapter chapter;

  ReadCreatePageIteratorEvent({@required this.chapter});

  @override
  List<Object> get props => [chapter];
}

class ReadChapterLoadedEvent extends ReadEvent {
  final models.Chapter chapter;
  final models.PageIterator pageIterator;

  ReadChapterLoadedEvent({@required this.chapter, @required this.pageIterator});

  @override
  List<Object> get props => [chapter, pageIterator];
}

class ReadPageLoadedEvent extends ReadEvent {
  final String page;

  ReadPageLoadedEvent({@required this.page});

  @override
  List<Object> get props => [page];
}

class ReadNextPageEvent extends ReadEvent {
  final int page;
  final bool isPreFetch;
  final bool isChangeCurrentPage;

  ReadNextPageEvent({
    @required this.page,
    this.isPreFetch = true,
    this.isChangeCurrentPage = true,
  });

  @override
  List<Object> get props => [page, isPreFetch, isChangeCurrentPage];
}

class ReadPrevPageEvent extends ReadEvent {
  @override
  List<Object> get props => [];
}

class ReadSettingsRequestEvent extends ReadEvent {
  @override
  List<Object> get props => [];
}

class ReadToolbarDisplayStatusChangedEvent extends ReadEvent {
  @override
  List<Object> get props => [];
}

class ReadCurrentPageForceChangedEvent extends ReadEvent {
  final int page;

  ReadCurrentPageForceChangedEvent({@required this.page});

  @override
  List<Object> get props => [page];
}

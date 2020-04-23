import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart' as models;

abstract class ReadEvent extends Equatable {}

class ReadCreatePageIteratorEvent extends ReadEvent {
  final int chapterReadAt;
  final models.Chapter chapter;

  ReadCreatePageIteratorEvent(
      {@required this.chapterReadAt, @required this.chapter});

  @override
  List<Object> get props => [chapterReadAt, chapter];
}

class ReadChapterLoadedEvent extends ReadEvent {
  final int chapterReadAt;
  final models.Chapter chapter;
  final models.PageIterator pageIterator;

  ReadChapterLoadedEvent({
    @required this.chapterReadAt,
    @required this.chapter,
    @required this.pageIterator,
  });

  @override
  List<Object> get props => [chapterReadAt, chapter, pageIterator];
}

class ReadPageLoadedEvent extends ReadEvent {
  final int pageNum;
  final String page;
  final bool isMakeUp;

  ReadPageLoadedEvent(
      {@required this.pageNum, @required this.page, this.isMakeUp});

  @override
  List<Object> get props => [pageNum, page, isMakeUp];
}

class ReadNextPageEvent extends ReadEvent {
  final int page;
  final int preLoading;

  ReadNextPageEvent({
    @required this.page,
    @required this.preLoading,
  });

  @override
  List<Object> get props => [page, preLoading];
}

class ReadMakeUpPageEvent extends ReadEvent {
  final int page;

  ReadMakeUpPageEvent({@required this.page}) : assert(page != null);

  @override
  List<Object> get props => [page];
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

class ReadFreeEvent extends ReadEvent {
  final models.PageIterator pageIterator;

  ReadFreeEvent({@required this.pageIterator});

  @override
  List<Object> get props => [pageIterator];
}

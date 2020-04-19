import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../widget/comics_view.dart' show ComicViewItem;

abstract class IndexEvent extends Equatable {}

class IndexRequestEvent extends IndexEvent {
  final int page;

  IndexRequestEvent({@required this.page});

  @override
  List<Object> get props => [page];
}

class IndexSearchEvent extends IndexEvent {
  final String keywords;
  final int page;

  IndexSearchEvent({@required this.keywords, @required this.page});

  @override
  List<Object> get props => [keywords, page];
}

class IndexLoadedEvent extends IndexEvent {
  final List<ComicViewItem> comicViewItems;

  IndexLoadedEvent({@required this.comicViewItems});

  @override
  List<Object> get props => [comicViewItems];
}

class IndexViewModeChangedEvent extends IndexEvent {
  final bool isViewList;

  IndexViewModeChangedEvent({@required this.isViewList});

  @override
  List<Object> get props => [isViewList];
}

class IndexErrorOccurredEvent extends IndexEvent {
  final String message;

  IndexErrorOccurredEvent({@required this.message});

  @override
  List<Object> get props => [message];
}

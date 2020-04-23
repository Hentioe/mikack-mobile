import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../widget/comics_view.dart' show ComicViewItem;

abstract class IndexState extends Equatable {}

class IndexLoadedState extends IndexState {
  final bool error;
  final String errorMessage;
  final bool isFetching;
  final int currentPage;
  final String currentKeywords;
  final List<ComicViewItem> comicViewItems;
  final bool isViewList;
  final bool mayBeEnding;

  IndexLoadedState({
    this.error = false,
    this.errorMessage,
    @required this.isFetching,
    this.currentPage = 1,
    this.currentKeywords,
    @required this.comicViewItems,
    @required this.isViewList,
    this.mayBeEnding = false,
  });

  @override
  List<Object> get props => [
        error,
        errorMessage,
        isFetching,
        currentPage,
        currentKeywords,
        comicViewItems,
        isViewList,
        mayBeEnding,
      ];

  IndexLoadedState copyWith({
    bool error,
    String errorMessage,
    bool isFetching,
    int currentPage,
    String currentKeywords,
    List<ComicViewItem> comicViewItems,
    bool isViewList,
    bool mayBeEnding,
  }) =>
      IndexLoadedState(
        error: error ?? this.error,
        errorMessage: errorMessage ?? this.errorMessage,
        isFetching: isFetching ?? this.isFetching,
        currentPage: currentPage ?? this.currentPage,
        currentKeywords: currentKeywords ?? this.currentKeywords,
        comicViewItems: comicViewItems ?? this.comicViewItems,
        isViewList: isViewList ?? this.isViewList,
        mayBeEnding: mayBeEnding ?? this.mayBeEnding,
      );
}

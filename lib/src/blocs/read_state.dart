import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart' as models;

abstract class ReadState extends Equatable {}

class ReadLoadedState extends ReadState {
  final bool error;
  final bool isShowToolbar;
  final models.Chapter chapter;
  final models.PageIterator pageIterator;
  final bool isLoading;
  final int currentPage;
  final List<String> pages;

  ReadLoadedState({
    this.error = false,
    @required this.isShowToolbar,
    this.chapter,
    this.pageIterator,
    @required this.isLoading,
    @required this.currentPage,
    @required this.pages,
  });

  @override
  List<Object> get props => [
        error,
        isShowToolbar,
        chapter,
        pageIterator,
        isLoading,
        currentPage,
        pages
      ];

  ReadLoadedState copyWith({
    bool error,
    bool isShowToolbar,
    models.Chapter chapter,
    models.PageIterator pageIterator,
    bool isLoading,
    int currentPage,
    List<String> pages,
  }) =>
      ReadLoadedState(
        error: error ?? this.error,
        isShowToolbar: isShowToolbar ?? this.isShowToolbar,
        chapter: chapter ?? this.chapter,
        pageIterator: pageIterator ?? this.pageIterator,
        isLoading: isLoading ?? this.isLoading,
        currentPage: currentPage ?? this.currentPage,
        pages: pages ?? this.pages,
      );
}

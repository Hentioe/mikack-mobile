import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart' as models;

abstract class ReadState extends Equatable {}

class ReadLoadedState extends ReadState {
  final bool error;
  final bool isLeftHandMode;
  final bool isShowToolbar;
  final models.Chapter chapter;
  final models.PageIterator pageIterator;
  final bool isLoading;
  final int currentPage;
  final List<String> pages;
  final int preFetchAt;

  ReadLoadedState({
    this.error = false,
    @required this.isLeftHandMode,
    @required this.isShowToolbar,
    this.chapter,
    this.pageIterator,
    @required this.isLoading,
    @required this.currentPage,
    @required this.pages,
    this.preFetchAt = 0,
  });

  @override
  List<Object> get props => [
        error,
        isLeftHandMode,
        isShowToolbar,
        chapter,
        pageIterator,
        isLoading,
        currentPage,
        pages,
        preFetchAt,
      ];

  ReadLoadedState copyWith({
    bool error,
    bool isLeftHandMode,
    bool isShowToolbar,
    models.Chapter chapter,
    models.PageIterator pageIterator,
    bool isLoading,
    int currentPage,
    List<String> pages,
    int preFetchAt,
  }) =>
      ReadLoadedState(
        error: error ?? this.error,
        isLeftHandMode: isLeftHandMode ?? this.isLeftHandMode,
        isShowToolbar: isShowToolbar ?? this.isShowToolbar,
        chapter: chapter ?? this.chapter,
        pageIterator: pageIterator ?? this.pageIterator,
        isLoading: isLoading ?? this.isLoading,
        currentPage: currentPage ?? this.currentPage,
        pages: pages ?? this.pages,
        preFetchAt: preFetchAt ?? this.preFetchAt,
      );
}

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart' as models;

import '../models.dart';

abstract class ReadState extends Equatable {}

class ReadLoadedState extends ReadState {
  final ErrorWrapper createIteratorError;
  final ReadingModeType readingMode;
  final bool isLeftHandMode;
  final int preLoading;
  final bool preCaching;
  final bool isShowToolbar;
  final int chapterReadAt;
  final models.Chapter chapter;
  final models.PageIterator pageIterator;
  final bool isLoading;
  final int currentPage;
  final List<String> pages;
  final int preFetchAt;

  ReadLoadedState({
    this.createIteratorError = noneError,
    @required this.readingMode,
    @required this.isLeftHandMode,
    @required this.preLoading,
    @required this.preCaching,
    @required this.isShowToolbar,
    @required this.chapterReadAt,
    this.chapter,
    this.pageIterator,
    @required this.isLoading,
    @required this.currentPage,
    @required this.pages,
    this.preFetchAt = 0,
  });

  @override
  List<Object> get props => [
        createIteratorError,
        readingMode,
        isLeftHandMode,
        preLoading,
        preCaching,
        isShowToolbar,
        chapterReadAt,
        chapter,
        pageIterator,
        isLoading,
        currentPage,
        pages,
        preFetchAt,
      ];

  ReadLoadedState copyWith({
    ErrorWrapper createIteratorError,
    ReadingModeType readingMode,
    bool isLeftHandMode,
    int preLoading,
    bool preCaching,
    bool isShowToolbar,
    int chapterReadAt,
    models.Chapter chapter,
    models.PageIterator pageIterator,
    bool isLoading,
    int currentPage,
    List<String> pages,
    int preFetchAt,
  }) =>
      ReadLoadedState(
        createIteratorError: createIteratorError ?? this.createIteratorError,
        readingMode: readingMode ?? this.readingMode,
        isLeftHandMode: isLeftHandMode ?? this.isLeftHandMode,
        preLoading: preLoading ?? this.preLoading,
        preCaching: preCaching ?? this.preCaching,
        isShowToolbar: isShowToolbar ?? this.isShowToolbar,
        chapterReadAt: chapterReadAt ?? this.chapterReadAt,
        chapter: chapter ?? this.chapter,
        pageIterator: pageIterator ?? this.pageIterator,
        isLoading: isLoading ?? this.isLoading,
        currentPage: currentPage ?? this.currentPage,
        pages: pages ?? this.pages,
        preFetchAt: preFetchAt ?? this.preFetchAt,
      );
}

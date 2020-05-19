import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack/models.dart';

import '../widget/comics_view.dart';
import '../values.dart';

abstract class SearchState extends Equatable {}

class SearchLoadedState extends SearchState {
  final String keywords;
  final bool isResultView;
  final Set<int> includesTags;
  final Set<int> excludesTags;
  final List<Platform> filteredSources;
  final LinkedHashMap<Platform, List<ComicViewItem>> groupedResult;
  final Set<Platform> excludesSources;
  final int clearKeywordsOpeInc;

  SearchLoadedState({
    this.keywords,
    @required this.isResultView,
    @required this.includesTags,
    @required this.excludesTags,
    @required this.filteredSources,
    @required this.groupedResult,
    @required this.excludesSources,
    this.clearKeywordsOpeInc = vInitOpeInc,
  });

  @override
  List<Object> get props => [
        keywords,
        isResultView,
        includesTags,
        excludesTags,
        filteredSources,
        groupedResult,
        excludesSources,
        clearKeywordsOpeInc,
      ];

  SearchLoadedState copyWith({
    String keywords,
    bool isResultView,
    Set<int> includesTags,
    Set<int> excludesTags,
    List<Platform> filteredSources,
    LinkedHashMap<Platform, List<ComicViewItem>> groupedResult,
    Set<Platform> excludesSources,
    int clearKeywordsOpeInc,
  }) =>
      SearchLoadedState(
        keywords: keywords ?? this.keywords,
        isResultView: isResultView ?? this.isResultView,
        includesTags: includesTags ?? this.includesTags,
        excludesTags: excludesTags ?? this.excludesTags,
        filteredSources: filteredSources ?? this.filteredSources,
        groupedResult: groupedResult ?? this.groupedResult,
        excludesSources: excludesSources ?? this.excludesSources,
        clearKeywordsOpeInc: clearKeywordsOpeInc ?? this.clearKeywordsOpeInc,
      );
}

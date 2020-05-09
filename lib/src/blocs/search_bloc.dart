import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:mikack_mobile/src/values.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  @override
  SearchState get initialState => SearchLoadedState(
        isResultView: false,
        includesTags: Set(),
        excludesTags: Set.from([vNsfwTagIntValue]),
        filteredSources: const [],
        excludesSources: Set(),
        groupedResult: LinkedHashMap(),
      );

  @override
  Stream<SearchState> mapEventToState(SearchEvent event) async* {
    switch (event.runtimeType) {
      case SearchInitEvent: // 初始化事件
        // 检测 NSFW 设置
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var isAllowNsfw = prefs.getBool(kAllowNsfw) ?? dAllowNsfw;
        if (isAllowNsfw)
          yield (state as SearchLoadedState).copyWith(excludesTags: Set());
        break;
    }
  }
}

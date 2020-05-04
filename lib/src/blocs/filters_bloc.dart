import 'package:bloc/bloc.dart';
import 'package:mikack_mobile/src/values.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'filters_event.dart';
import 'filters_state.dart';
import 'libraries_event.dart';

class FiltersBloc extends Bloc<FiltersEvent, FiltersState> {
  @override
  FiltersState get initialState => FiltersLoadedState(
        isAllowNsfw: false,
        includes: Set(),
        excludes: Set()..add(vNsfwTagIntValue),
      );

  @override
  Stream<FiltersState> mapEventToState(FiltersEvent event) async* {
    switch (event.runtimeType) {
      case FiltersRequestEvent: // 请求过滤数据
        var castedEvent = event as FiltersRequestEvent;
        if (state != initialState) break;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var isAllowNsfw = prefs.getBool(kAllowNsfw) ?? false;
        add(FiltersAllowNsfwUpdatedEvent(
            isAllow: isAllowNsfw, historiesBloc: castedEvent.historiesBloc));
        break;

      case FiltersUpdatedEvent: // 过滤条件更新
        var castedEvent = event as FiltersUpdatedEvent;
        var castedState = state as FiltersLoadedState;

        switch (castedEvent.from) {
          case FiltersUpdateFrom.includes:
            // 去重
            var isExcludesExists =
                castedState.excludes.contains(castedEvent.value);
            Set<int> excludes =
                isExcludesExists ? Set.from(castedState.excludes) : null;
            Set<int> includes = Set.from(castedState.includes);
            if (castedEvent.action == FiltersUpdateAction.added) {
              excludes?.remove(castedEvent.value);
              includes.add(castedEvent.value);
            } else
              includes.remove(castedEvent.value);

            yield (state as FiltersLoadedState)
                .copyWith(includes: includes, excludes: excludes);
            break;
          case FiltersUpdateFrom.excludes:
            // 去重
            var isIncludesExists =
                castedState.includes.contains(castedEvent.value);
            Set<int> includes =
                isIncludesExists ? Set.from(castedState.includes) : null;
            Set<int> excludes = Set.from(castedState.excludes);
            if (castedEvent.action == FiltersUpdateAction.added) {
              includes?.remove(castedEvent.value);
              excludes.add(castedEvent.value);
            } else
              excludes.remove(castedEvent.value);

            yield (state as FiltersLoadedState)
                .copyWith(excludes: excludes, includes: includes);
            break;
        }
        // 通过仓库页面更新
        var stateSnapshot = state as FiltersLoadedState;
        castedEvent.historiesBloc?.add(LibrariesFiltersUpdatedEvent(
          includes: stateSnapshot.includes.toList(),
          excludes: stateSnapshot.excludes.toList(),
        ));
        break;
      case FiltersAllowNsfwUpdatedEvent:
        var castedEvent = event as FiltersAllowNsfwUpdatedEvent;

        var action = castedEvent.isAllow
            ? FiltersUpdateAction.removed
            : FiltersUpdateAction.added;
        // 更新过滤条件
        add(FiltersUpdatedEvent(
          from: FiltersUpdateFrom.excludes,
          value: vNsfwTagIntValue,
          action: action,
          historiesBloc: castedEvent.historiesBloc,
        ));
        yield (state as FiltersLoadedState)
            .copyWith(isAllowNsfw: castedEvent.isAllow);
        break;
    }
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(error);
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}

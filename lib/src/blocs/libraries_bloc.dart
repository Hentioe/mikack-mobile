import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart';
import 'libraries_event.dart';
import 'libraries_state.dart';

import '../../ext.dart';

class LibrariesBloc extends Bloc<LibrariesEvent, LibrariesState> {
  @override
  LibrariesState get initialState =>
      LibrariesGroupedListState(fixedList: const [], filteredList: const []);

  @override
  Stream<LibrariesState> mapEventToState(LibrariesEvent event) async* {
    switch (event.runtimeType) {
      case LibrariesFiltersUpdatedEvent: // 过滤条件更新
        var castedEvent = (event as LibrariesFiltersUpdatedEvent);
        var filteredList = findPlatforms(
          castedEvent.includes.map((v) => Tag(v, '')).toList(),
          castedEvent.excludes.map((v) => Tag(v, '')).toList(),
        );
        if (state is LibrariesGroupedListState) {
          var castedState = state as LibrariesGroupedListState;
          // 删除已固定的内容
          filteredList.removeWhere(
              (p) => castedState.fixedList.containsDomain(p.domain));
          yield castedState.copyWith(filteredList: filteredList);
        } else {
          // 从数据库查找固定列表
          // TODO: 查库
          yield LibrariesGroupedListState(
              fixedList: [], filteredList: filteredList);
        }
        break;
      case LibrariesFixedUpdatedEvent: // 已固定列表更新
        var castedEvent = (event as LibrariesFixedUpdatedEvent);
        if (state is LibrariesGroupedListState) {
          var castedState = state as LibrariesGroupedListState;
          var filteredList = [...castedState.filteredList];
          var fixedList = [...castedState.fixedList];
          var targetPlatform = castedEvent.platform;
          if (!castedEvent.fromFixed) {
            // 固定平台
            // TODO: 更新数据库
            fixedList.add(targetPlatform);
            filteredList.remove(targetPlatform);
          } else {
            // 移除固定
            // TODO: 更新数据
            fixedList.remove(targetPlatform);
            filteredList.add(targetPlatform);
          }
          yield castedState.copyWith(
              fixedList: fixedList, filteredList: filteredList);
        }
        break;
    }
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}

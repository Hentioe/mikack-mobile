import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart';
import 'package:mikack_mobile/store.dart';
import 'libraries_event.dart';
import 'libraries_state.dart';

import '../platform_list.dart';
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
          // 如果固定列表为空，查询图源
          List<Platform> fixedList = [...castedState.fixedList];
          if (fixedList.length == 0) {
            // 从数据库查找已固定的图源列表
            var fixedSources = await findSources(isFixed: true);
            // 从全部平台中匹配对应的数据
            fixedList = platformList
                .where((p) => fixedSources.containsDomain(p.domain))
                .toList();
          }

          yield castedState.copyWith(
              fixedList: fixedList, filteredList: filteredList);
        }
        break;
      case LibrariesFixedUpdatedEvent: // 已固定列表更新
        var castedEvent = (event as LibrariesFixedUpdatedEvent);
        if (state is LibrariesGroupedListState) {
          var castedState = state as LibrariesGroupedListState;
          var filteredList = [...castedState.filteredList];
          var fixedList = [...castedState.fixedList];
          var targetPlatform = castedEvent.platform;
          var source = await targetPlatform.toSavedSource();
          if (!castedEvent.fromFixed) {
            // 固定平台
            await updateSource(source..isFixed = true);
            fixedList.add(targetPlatform);
          } else {
            // 移除固定
            await updateSource(source..isFixed = false);
            fixedList.remove(targetPlatform);
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

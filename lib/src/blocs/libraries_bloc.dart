import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mikack/mikack.dart';
import 'package:mikack/models.dart';
import 'libraries_event.dart';
import 'libraries_state.dart';

class LibrariesBloc extends Bloc<LibrariesEvent, LibrariesState> {
  @override
  LibrariesState get initialState => LibrariesFilteredState(list: const []);

  @override
  Stream<LibrariesState> mapEventToState(LibrariesEvent event) async* {
    switch (event.runtimeType) {
      case LibrariesFiltersUpdatedEvent: // 根据条件过滤平台列表
        var casted = (event as LibrariesFiltersUpdatedEvent);
        var list = findPlatforms(
          casted.includes.map((v) => Tag(v, '')).toList(),
          casted.excludes.map((v) => Tag(v, '')).toList(),
        );
        yield LibrariesFilteredState(list: list);
        break;
    }
  }
}

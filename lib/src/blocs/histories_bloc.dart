import 'package:bloc/bloc.dart';

import 'histories_event.dart';
import 'histories_state.dart';
import '../../store.dart';
import '../platform_list.dart';
import '../../ext.dart';

class HistoriesBloc extends Bloc<HistoriesEvent, HistoriesState> {
  @override
  HistoriesState get initialState => HistoriesLoadedState(histories: const []);

  @override
  Stream<HistoriesState> mapEventToState(HistoriesEvent event) async* {
    switch (event.runtimeType) {
      case HistoriesRequestEvent: // 请求数据
        yield HistoriesLoadedState(histories: await getHistories());
        break;
      case HistoriesRemoveEvent: // 删除数据
        var castedEvent = event as HistoriesRemoveEvent;
        var castedState = state as HistoriesLoadedState;
        await deleteHistory(id: castedEvent.history.id);
        var histories = [...castedState.histories];
        histories.remove(castedEvent.history);
        yield castedState.copyWith(histories: histories);
        break;
    }
  }

  Future<List<History>> getHistories() async {
    var histories = await findHistories();
    for (History history in histories) {
      var source = await getSource(id: history.sourceId);
      if (source == null) {
        source = Source(name: '已失效的图源');
      } else {
        var platform =
            platformList.firstWhere((p) => p.domain == source.domain);
        history.headers = platform.buildBaseHeaders();
      }
      history.source = source;
    }
    return histories;
  }
}

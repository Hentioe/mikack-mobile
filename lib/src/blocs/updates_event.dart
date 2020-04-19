import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:mikack_mobile/src/widget/comics_view.dart';

abstract class UpdatesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

enum UpdatesRequestEventTypes {
  localRequest,
  remoteRequest,
  stopRefreshRequest
}

class UpdatesRequestEvent extends UpdatesEvent {
  UpdatesRequestEvent({this.type});

  final UpdatesRequestEventTypes type;

  @override
  List<Object> get props => [type];

  factory UpdatesRequestEvent.local() =>
      UpdatesRequestEvent(type: UpdatesRequestEventTypes.localRequest);

  factory UpdatesRequestEvent.remote() =>
      UpdatesRequestEvent(type: UpdatesRequestEventTypes.remoteRequest);

  factory UpdatesRequestEvent.stopRefresh() =>
      UpdatesRequestEvent(type: UpdatesRequestEventTypes.stopRefreshRequest);
}

class UpdatesLoadedEvent extends UpdatesEvent {
  final ComicViewItem viewItem;

  UpdatesLoadedEvent({@required this.viewItem});

  @override
  List<Object> get props => [viewItem];
}

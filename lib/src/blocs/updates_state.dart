import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../widget/comics_view.dart' show ComicViewItem;

class UpdatesState extends Equatable {
  @override
  List<Object> get props => [];
}

class UpdatesLocalLoadedState extends UpdatesState {
  UpdatesLocalLoadedState({@required this.viewItems});

  final List<ComicViewItem> viewItems;

  @override
  List<Object> get props => [viewItems];
}

class UpdatesRemoteLoadedState extends UpdatesState {
  UpdatesRemoteLoadedState({
    @required this.viewItems,
    @required this.total,
    this.progress = 0,
  });

  final List<ComicViewItem> viewItems;
  final int total;
  final int progress;

  @override
  List<Object> get props => [viewItems, total, progress];

  bool get isCompleted => total == progress;

  UpdatesRemoteLoadedState pushWith(ComicViewItem viewItem) => copyWith(
      viewItems: [viewItem, ...this.viewItems], progress: this.progress + 1);

  UpdatesRemoteLoadedState progressIncrement() =>
      copyWith(progress: this.progress + 1);

  /// 提前完成数据装载
  /// 此方法直接将总数等于当前进度
  UpdatesRemoteLoadedState completedAhead() => copyWith(total: this.progress);

  UpdatesRemoteLoadedState copyWith(
      {List<ComicViewItem> viewItems, int total, int progress}) {
    return UpdatesRemoteLoadedState(
      viewItems: viewItems ?? this.viewItems,
      total: total ?? this.total,
      progress: progress ?? this.progress,
    );
  }
}

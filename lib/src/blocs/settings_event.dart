import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

import '../models.dart';

abstract class SettingsEvent extends Equatable {}

class SettingsRequestEvent extends SettingsEvent {
  @override
  List<Object> get props => [];
}

class SettingsStartPageChangedEvent extends SettingsEvent {
  final StartPageItem startPage;

  SettingsStartPageChangedEvent({@required this.startPage});

  @override
  List<Object> get props => [startPage];
}

class ReadingModeChangedEvent extends SettingsEvent {
  final ReadingModeItem readingMode;

  ReadingModeChangedEvent({@required this.readingMode});

  @override
  List<Object> get props => [readingMode];
}

enum SettingsSwitchType { leftHand, allowNsfw, reverseChapters }

class SettingsSwitchedEvent extends SettingsEvent {
  final SettingsSwitchType switchType;
  final bool changedValue;

  SettingsSwitchedEvent(
      {@required this.switchType, @required this.changedValue});

  @override
  List<Object> get props => [switchType, changedValue];
}

enum SettingsCleanupType { histories, favorites, cachedImages }

class SettingsCleanupRequestEvent extends SettingsEvent {
  final SettingsCleanupType cleanupType;

  SettingsCleanupRequestEvent({@required this.cleanupType});

  @override
  List<Object> get props => [cleanupType];
}

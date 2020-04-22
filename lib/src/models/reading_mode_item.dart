import 'package:equatable/equatable.dart';

import '../values.dart';
import '../exceptions.dart';

class ReadingModeItem extends Equatable {
  final String key;

  ReadingModeItem(this.key)
      : assert(key == kLeftToRight || key == kTopToBottom || key == kPaperRoll);

  @override
  List<Object> get props => [key];

  @override
  String toString() {
    switch (key) {
      case kLeftToRight:
        return '从左到右';
      case kTopToBottom:
        return '从上到下';
      case kPaperRoll:
        return '卷纸模式';
      default:
        throw UnknownException('Unknown reading mode');
    }
  }
}

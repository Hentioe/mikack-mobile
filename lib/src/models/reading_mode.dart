import 'package:equatable/equatable.dart';

import '../values.dart';
import '../exceptions.dart';

final unknownReadingException = UnknownException('Unknown reading mode');

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
        throw unknownReadingException;
    }
  }

  ReadingModeType type() {
    switch (key) {
      case kLeftToRight:
        return ReadingModeType.leftToRight;
      case kTopToBottom:
        return ReadingModeType.topToBottom;
      case kPaperRoll:
        return ReadingModeType.paperRoll;
      default:
        throw unknownReadingException;
    }
  }
}

enum ReadingModeType { leftToRight, topToBottom, paperRoll }

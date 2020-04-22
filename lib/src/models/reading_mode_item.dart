import 'package:equatable/equatable.dart';

import '../values.dart';
import '../exceptions.dart';

class ReadingModeItem extends Equatable {
  final String key;

  ReadingModeItem(this.key)
      : assert(key == vLeftToRight || key == vTopToBottom || key == vPaperRoll);

  @override
  List<Object> get props => [key];

  @override
  String toString() {
    switch (key) {
      case vLeftToRight:
        return '从左到右';
      case vTopToBottom:
        return '从上到下';
      case vPaperRoll:
        return '卷纸模式';
      default:
        throw UnknownException('Unknown reading mode');
    }
  }
}

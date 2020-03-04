import 'package:tuple/tuple.dart';

Tuple2<String, List<dynamic>> makeCondition(Map<String, dynamic> conditions) {
  for (MapEntry<String, dynamic> cond in conditions.entries) {
    if (cond.value != null) {
      return Tuple2('${cond.key} = ?', [cond.value]);
    }
  }
  return null;
}

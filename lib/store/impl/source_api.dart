import '../../store.dart';
import '../models.dart';
import '../helper.dart';

Future<void> insertSource(Source source) async {
  final db = await database();
  final id = await db.insert(Source.tableName, source.toMap());
  source.id = id;
}

Future<List<Source>> findSources({bool isFixed}) async {
  final db = await database();

  String where;
  var whereArgs = <dynamic>[];

  if (isFixed != null) {
    where = 'is_fixed = ?';
    if (isFixed)
      whereArgs.add(1);
    else
      whereArgs.add(0);
  }

  final List<Map<String, dynamic>> maps = await db.query(
    Source.tableName,
    where: where,
    whereArgs: whereArgs,
  );

  return maps.map((map) => Source.fromMap(map)).toList();
}

Future<Source> getSource({int id, String domain}) async {
  final db = await database();

  var cond = makeSingleCondition({'id': id, 'domain': domain});
  final List<Map<String, dynamic>> maps = await db.query(
    Source.tableName,
    where: cond.item1,
    whereArgs: cond.item2,
    limit: 1,
  );
  if (maps.isEmpty) return null;

  return maps.map((map) => Source.fromMap(map)).toList().first;
}

Future<void> updateSource(Source source) async {
  final db = await database();

  await db.update(
    Source.tableName,
    source.toMap(),
    where: 'id = ?',
    whereArgs: [source.id],
  );
}

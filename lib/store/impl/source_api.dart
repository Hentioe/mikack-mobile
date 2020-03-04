import '../../store.dart';
import '../models.dart';
import '../helper.dart';

Future<void> insertSource(Source source) async {
  final db = await database();
  final id = await db.insert(Source.tableName, source.toMap());
  source.id = id;
}

Future<List<Source>> findSources() async {
  final db = await database();

  final List<Map<String, dynamic>> maps = await db.query(Source.tableName);

  return maps.map((map) => Source.fromMap(map)).toList();
}

Future<Source> getSource({int id, String domain}) async {
  final db = await database();

  var cond = makeCondition({'id': id, 'domain': domain});
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

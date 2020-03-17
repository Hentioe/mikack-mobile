import 'package:sqflite/sqflite.dart';

import '../../store.dart';
import '../models.dart';
import '../helper.dart';

Future<void> insertHistory(History historiy) async {
  final db = await database();
  await db.insert(History.tableName, historiy.toMap());
}

Future<List<History>> findHistories() async {
  final db = await database();

  final List<Map<String, dynamic>> maps =
  await db.query(History.tableName, orderBy: 'datetime(updated_at) DESC');

  return maps.map((map) => History.fromMap(map)).toList();
}

Future<History> getHistory({int id, String address}) async {
  final db = await database();

  var cond = makeCondition({'id': id, 'address': address});
  final List<Map<String, dynamic>> maps = await db.query(
    History.tableName,
    where: cond.item1,
    whereArgs: cond.item2,
    limit: 1,
  );
  if (maps.isEmpty) return null;

  return maps
      .map((map) => History.fromMap(map))
      .toList()
      .first;
}

Future<void> updateHistory(History historiy) async {
  final db = await database();

  historiy.updateAt = DateTime.now();
  await db.update(
    History.tableName,
    historiy.toMap(),
    where: 'id = ?',
    whereArgs: [historiy.id],
  );
}

Future<void> deleteHistory(id) async {
  final db = await database();

  var cond = makeCondition({'id': id});
  await db.delete(
    History.tableName,
    where: cond.item1,
    whereArgs: cond.item2,
  );
}

Future<void> deleteAllHistories() async {
  final db = await database();
  await db.delete(History.tableName);
}

Future<int> getHistoriesTotal() async {
  final db = await database();

  return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${History.tableName}'));
}
import '../../store.dart';
import '../models.dart';
import '../helper.dart';

Future<void> insertFavorite(Favorite favorite) async {
  final db = await database();
  var id = await db.insert(Favorite.tableName, favorite.toMap());
  favorite.id = id;
}

Future<List<Favorite>> findFavorites() async {
  final db = await database();

  final List<Map<String, dynamic>> maps = await db.query(Favorite.tableName,
      orderBy: 'datetime(last_read_time) DESC');

  return maps.map((map) => Favorite.fromMap(map)).toList();
}

Future<Favorite> getFavorite({int id, String address}) async {
  final db = await database();

  var cond = makeCondition({'id': id, 'address': address});
  final List<Map<String, dynamic>> maps = await db.query(
    Favorite.tableName,
    where: cond.item1,
    whereArgs: cond.item2,
    limit: 1,
  );
  if (maps.isEmpty) return null;

  return maps.map((map) => Favorite.fromMap(map)).toList().first;
}

Future<void> updateFavorite(Favorite favorite) async {
  final db = await database();

  await db.update(
    Favorite.tableName,
    favorite.toMap(),
    where: 'id = ?',
    whereArgs: [favorite.id],
  );
}

Future<void> deleteFavorite({int id, String address}) async {
  final db = await database();

  var cond = makeCondition({'id': id, 'address': address});
  await db.delete(
    Favorite.tableName,
    where: cond.item1,
    whereArgs: cond.item2,
  );
}

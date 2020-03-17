import 'package:mikack_mobile/fragments/bookshelf.dart';
import 'package:sqflite/sqflite.dart';

import '../../store.dart';
import '../models.dart';
import '../helper.dart';

Future<void> insertFavorite(Favorite favorite) async {
  final db = await database();
  var id = await db.insert(Favorite.tableName, favorite.toMap());
  favorite.id = id;
}

Future<List<Favorite>> findFavorites(
    {BookshelfSortBy sortBy = BookshelfSortBy.readAt}) async {
  final db = await database();

  var column = 'last_read_time'; // 默认上次阅读时间
  switch (sortBy) {
    case BookshelfSortBy.readAt:
      break;
    case BookshelfSortBy.insertedAt:
      column = 'inserted_at';
  }

  final List<Map<String, dynamic>> maps =
      await db.query(Favorite.tableName, orderBy: 'datetime($column) DESC');

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

  favorite.updatedAt = DateTime.now();
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

Future<void> deleteAllFavorites() async {
  final db = await database();
  await db.delete(Favorite.tableName);
}

Future<int> getFavoritesTotal() async {
  final db = await database();

  return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${Favorite.tableName}'));
}

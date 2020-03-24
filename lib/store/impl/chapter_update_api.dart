import '../../store.dart';

Future<void> insertChapterUpdate(ChapterUpdate chapterUpdate) async {
  final db = await database();
  await db.insert(ChapterUpdate.tableName, chapterUpdate.toMap());
}

Future<List<ChapterUpdate>> findChapterUpdates() async {
  final db = await database();

  final List<Map<String, dynamic>> maps =
      await db.query(ChapterUpdate.tableName);

  return maps.map((map) => ChapterUpdate.fromMap(map)).toList();
}

Future<void> deleteAllChapterUpdates() async {
  final db = await database();
  await db.delete(ChapterUpdate.tableName);
}

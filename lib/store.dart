import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
export './store/impl.dart';
export './store/models.dart';

const dbFile = 'mikack.db';

Future<Database> database() async {
  var databasePath = await getDatabasesPath();
  return openDatabase(
    join(databasePath, dbFile),
    onCreate: (db, version) async {
      await db.execute(
          'CREATE TABLE sources(id INTEGER PRIMARY KEY AUTOINCREMENT, domain TEXT NOT NULL, name TEXT NOT NULL);');
      await db.execute(
          'CREATE UNIQUE INDEX sources_domain_idx ON sources (domain);');
      await db.execute('CREATE TABLE histories('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'source_id INTEGER NOT NULL,'
          'title TEXT NOT NULL,'
          'home_url TEXT NOT NULL,'
          'address TEXT NOT NULL,'
          'cover TEXT,'
          'inserted_at TEXT NOT NULL,'
          'updated_at TEXT NOT NULL,'
          'FOREIGN KEY(source_id) REFERENCES sources(id)'
          ');');
      await db.execute(
          'CREATE UNIQUE INDEX histories_address_dex ON histories (address);');
      await db.execute('CREATE TABLE favorites('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'source_id INTEGER NOT NULL,'
          'last_read_history_id INTEGER,'
          'name TEXT NOT NULL,'
          'address TEXT NOT NULL,'
          'cover TEXT,'
          'inserted_chapters_count INTEGER NOT NULL DEFAULT 0,'
          'latest_chapters_count INTEGER NOT NULL DEFAULT 0,'
          'last_read_time TEXT NOT NULL,'
          'inserted_at TEXT NOT NULL,'
          'updated_at TEXT NOT NULL,'
          'FOREIGN KEY(source_id) REFERENCES sources(id),'
          'FOREIGN KEY(last_read_history_id) REFERENCES histories(id)'
          ');');
      await db.execute(
          'CREATE UNIQUE INDEX favorites_address_dex ON favorites (address);');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      switch (oldVersion) {
        case 1:
          // 创建 updated_at 列
          await db.execute('ALTER TABLE histories ADD updated_at TEXT');
          break;
        case 2:
          // 创建 home_url 列
          await db.execute('ALTER TABLE histories ADD home_url TEXT');
      }
    },
    version: 3,
  );
}

Future<void> dangerouslyDestory() async {
  var databasePath = await getDatabasesPath();
  return deleteDatabase(join(databasePath, dbFile));
}

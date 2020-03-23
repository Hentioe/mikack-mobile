import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
export './store/impl.dart';
export './store/models.dart';

const dbFile = 'mikack.db';

const latestSourceTableStructure =
    'id INTEGER PRIMARY KEY AUTOINCREMENT, domain TEXT NOT NULL, name TEXT NOT NULL';

const latestHistoryTableStructure = 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
    'source_id INTEGER NOT NULL,' // 图源 ID
    'title TEXT NOT NULL,' // 标题
    'home_url TEXT NOT NULL,' // 主页链接
    'address TEXT NOT NULL,' // 地址
    'cover TEXT,' // 封面
    'displayed INTEGER NOT NULL,' // 显示状态
    'inserted_at TEXT NOT NULL,' // 插入时间
    'updated_at TEXT NOT NULL,' // 更新时间
    'CHECK (displayed IN (0,1)),' // 确保 `显示状态` 为布尔值
    'FOREIGN KEY(source_id) REFERENCES sources(id)';

const latestFavoriteTableStructure = 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
    'source_id INTEGER NOT NULL,' // 图源 ID
    'name TEXT NOT NULL,' // 名称（章节标题）
    'address TEXT NOT NULL,' // 地址
    'cover TEXT,' // 封面
    'inserted_chapters_count INTEGER NOT NULL DEFAULT 0,' // 插入时的章节数量
    'latest_chapters_count INTEGER NOT NULL DEFAULT 0,' // 最新的章节数量
    'last_read_time TEXT NOT NULL,' // 上次阅读时间
    'inserted_at TEXT NOT NULL,' // 插入时间
    'updated_at TEXT NOT NULL,' // 更新时间
    'FOREIGN KEY(source_id) REFERENCES sources(id)';

List<String> tableStructureMigrationSqlGen(
  String tableName,
  String tableStructure, {
  columns: const ['*'],
}) {
  var newTableName = '${tableName}_new_tmp_name';
  var columnsStr = columns.join(',');
  return [
    // 创建最新结构的临时表（包含检查约束）
    'CREATE TABLE $newTableName($tableStructure);',
    // 复制数据
    'INSERT INTO $newTableName SELECT $columnsStr FROM $tableName;',
    // 删除旧表
    'DROP TABLE $tableName;',
    // 更新临时表名
    'ALTER TABLE $newTableName RENAME TO $tableName;'
  ];
}

Future<void> multiExecInTrans(Transaction tnx, List<String> sqls) async {
  for (String sql in sqls) {
    await tnx.execute(sql);
  }
}

Future<Database> database() async {
  var databasePath = await getDatabasesPath();
  return openDatabase(
    join(databasePath, dbFile),
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys=ON;'); // 启用外键
    },
    onCreate: (db, version) async {
      await db.transaction((tnx) async {
        await multiExecInTrans(tnx, [
          // 创建图源表
          'CREATE TABLE sources($latestSourceTableStructure);',
          // 创建图源表字段索引
          'CREATE UNIQUE INDEX sources_domain_idx ON sources (domain);',
          // 创建阅读历史表
          'CREATE TABLE histories($latestHistoryTableStructure);',
          // 创建阅读历史表字段索引
          'CREATE UNIQUE INDEX histories_address_dex1 ON histories (address);',
          // 创建收藏表
          'CREATE TABLE favorites($latestFavoriteTableStructure);',
          // 创建收藏表字段索引
          'CREATE UNIQUE INDEX favorites_address_dex ON favorites (address);',
        ]);
      });
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      switch (oldVersion) {
        case 1:
          // 给阅读历史添加更新时间
          await db.execute('ALTER TABLE histories ADD updated_at TEXT;');
          break;
        case 2:
          // 给阅读历史添加主页链接
          await db.execute('ALTER TABLE histories ADD home_url TEXT;');
          break;
        case 3:
          // 给阅读历史添加显示状态，并将已存在的数据设为显示（值为 1）
          await db.transaction((tnx) async {
            await multiExecInTrans(tnx, [
              // 添加`显示状态`列
              'ALTER TABLE histories ADD displayed INTEGER NULL;',
              // 填补空数据
              'UPDATE histories SET displayed = 1;',
              // 迁移表结构（包含非空和检查约束）
              ...tableStructureMigrationSqlGen(
                  'histories', latestHistoryTableStructure),
            ]);
          });
          break;
        case 4:
          await db.transaction((tnx) async {
            await multiExecInTrans(tnx, [
              // 迁移表结构（删除收藏中对历史记录的关联）
              ...tableStructureMigrationSqlGen(
                  'favorites', latestFavoriteTableStructure,
                  columns: [
                    'id',
                    'source_id',
                    'name',
                    'address',
                    'cover',
                    'inserted_chapters_count',
                    'latest_chapters_count',
                    'last_read_time',
                    'inserted_at',
                    'updated_at',
                  ]),
            ]);
          });
          break;
      }
    },
    version: 5,
  );
}

Future<void> dangerouslyDestory() async {
  var databasePath = await getDatabasesPath();
  return deleteDatabase(join(databasePath, dbFile));
}

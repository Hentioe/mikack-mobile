import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
export './store/impl.dart';
export './store/models.dart';

const dbFile = 'mikack.db';

// 来源表结构
const latestSourceTableStructure = 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
    'domain TEXT NOT NULL,' // 域名
    'name TEXT NOT NULL,' // 名称
    'is_fixed INTEGER NOT NULL,' // 是否固定
    'CHECK (is_fixed IN (0,1))'; // 确保 `is_fixed` 为布尔值

// 阅读历史表结构
const latestHistoryTableStructure = 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
    'source_id INTEGER NOT NULL,' // 来源 ID
    'title TEXT NOT NULL,' // 标题
    'home_url TEXT NOT NULL,' // 主页链接
    'address TEXT NOT NULL,' // 地址
    'cover TEXT,' // 封面
    'displayed INTEGER NOT NULL,' // 显示状态
    'inserted_at TEXT NOT NULL,' // 插入时间
    'updated_at TEXT NOT NULL,' // 更新时间
    'last_read_page INTEGER,' // 上次阅读页面（页码）
    'CHECK (displayed IN (0,1)),' // 确保 `显示状态` 为布尔值
    'FOREIGN KEY(source_id) REFERENCES sources(id)';

// 书架收藏表结构
const latestFavoriteTableStructure = 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
    'source_id INTEGER NOT NULL,' // 来源 ID
    'name TEXT NOT NULL,' // 名称（章节标题）
    'address TEXT NOT NULL,' // 地址
    'cover TEXT,' // 封面
    'latest_chapters_count INTEGER NOT NULL DEFAULT 0,' // 最新章节数量
    'last_read_time TEXT NOT NULL,' // 上次阅读时间
    'inserted_at TEXT NOT NULL,' // 插入时间
    'updated_at TEXT NOT NULL,' // 更新时间
    'FOREIGN KEY(source_id) REFERENCES sources(id)';

// 章节更新表结构
const latestChapterUpdateStructure = 'home_url TEXT PRIMARY KEY,' // 主页链接，主键
    'chapters_count INTEGER NOT NULL,' // 章节数量
    'inserted_at TEXT NOT NULL'; // 插入时间

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
    'ALTER TABLE $newTableName RENAME TO $tableName;',
  ];
}

Future<void> multiExecInTrans(
    Transaction tnx, List<String> sqlStatements) async {
  for (String sql in sqlStatements) {
    await tnx.execute(sql);
  }
}

Future<Database> database() async {
  var databasePath = await getDatabasesPath();
  return openDatabase(
    join(databasePath, dbFile),
    onCreate: (db, version) async {
      await db.transaction((tnx) async {
        await multiExecInTrans(tnx, [
          // 创建来源表
          'CREATE TABLE sources($latestSourceTableStructure);',
          // 创建来源表字段索引
          'CREATE UNIQUE INDEX sources_domain_idx ON sources (domain);',
          // 创建阅读历史表
          'CREATE TABLE histories($latestHistoryTableStructure);',
          // 创建阅读历史表字段索引
          'CREATE UNIQUE INDEX histories_address_dex1 ON histories (address);',
          // 创建收藏表
          'CREATE TABLE favorites($latestFavoriteTableStructure);',
          // 创建收藏表字段索引
          'CREATE UNIQUE INDEX favorites_address_dex ON favorites (address);',
          // 创建章节更新记录表
          'CREATE TABLE chapter_updates($latestChapterUpdateStructure);',
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
              // 迁移收藏表结构（包含对历史记录关联的删除）
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
        case 5:
          await db.transaction((tnx) async {
            await multiExecInTrans(tnx, [
              // 迁移收藏表结构（包含对`inserted_chapters_count`列的删除）
              ...tableStructureMigrationSqlGen(
                  'favorites', latestFavoriteTableStructure,
                  columns: [
                    'id',
                    'source_id',
                    'name',
                    'address',
                    'cover',
                    'latest_chapters_count',
                    'last_read_time',
                    'inserted_at',
                    'updated_at',
                  ]),
              // 创建章节更新记录表
              'CREATE TABLE chapter_updates($latestChapterUpdateStructure);',
            ]);
          });
          break;
        case 6:
          // 给来源添加“是否固定”字段，并将已存在的数据设为否（值为 0）
          await db.transaction((tnx) async {
            await multiExecInTrans(tnx, [
              // 添加`显示状态`列
              'ALTER TABLE sources ADD is_fixed INTEGER NULL;',
              // 填补空数据
              'UPDATE sources SET is_fixed = 0;',
              // 迁移表结构（包含非空和检查约束）
              ...tableStructureMigrationSqlGen(
                  'sources', latestSourceTableStructure),
            ]);
          });
          break;
        case 7:
          // 给阅读历史添加上次阅读页面
          await db.execute('ALTER TABLE histories ADD last_read_page INTEGER;');
          break;
      }
    },
    version: 8,
  );
}

Future<void> dangerouslyDestroy() async {
  var databasePath = await getDatabasesPath();
  return deleteDatabase(join(databasePath, dbFile));
}

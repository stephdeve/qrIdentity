import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:qr_identity/models/scan_record.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();

  static const _dbFile = 'qr_identity.db';
  static const _table = 'scan_records';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = '${docs.path}/$_dbFile';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            json TEXT NOT NULL,
            scanned_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertScan(ScanRecord record) async {
    final db = await database;
    return db.insert(_table, record.toMap());
  }

  Future<List<ScanRecord>> getScans() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'datetime(scanned_at) DESC');
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  Future<int> deleteScan(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }
}

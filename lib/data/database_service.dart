import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _db;
  Future<Database> get db async => _db ??= await openDatabase(
        join(await getDatabasesPath(), 'fizika_v1.db'),
        version: 2,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await db.execute(
            '''CREATE TABLE attempts(attempt_id TEXT PRIMARY KEY, question_id TEXT NOT NULL, lesson_id TEXT NOT NULL,difficulty TEXT NOT NULL, correct INTEGER NOT NULL, timestamp_local TEXT NOT NULL,selected_option_id TEXT, error_category TEXT, attempt_mode TEXT NOT NULL)''',
          );
          await db.execute(
            '''CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)''',
          );
          await db.insert('settings', {
            'key': 'current_unlock_order',
            'value': '10',
          });
          await db.execute(
            '''CREATE TABLE test_history(test_id TEXT PRIMARY KEY, timestamp_local TEXT NOT NULL, scope_json TEXT NOT NULL, focus TEXT NOT NULL, total INTEGER NOT NULL, correct INTEGER NOT NULL, percent INTEGER NOT NULL)''',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              '''CREATE TABLE test_history(test_id TEXT PRIMARY KEY, timestamp_local TEXT NOT NULL, scope_json TEXT NOT NULL, focus TEXT NOT NULL, total INTEGER NOT NULL, correct INTEGER NOT NULL, percent INTEGER NOT NULL)''',
            );
          }
        },
      );
  Future<void> clearProgress() async {
    final database = await db;
    await database.delete('attempts');
  }
}

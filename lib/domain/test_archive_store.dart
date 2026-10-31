import 'dart:convert';

import '../data/database_service.dart';

class TestArchiveEntry {
  const TestArchiveEntry({
    required this.id,
    required this.timestamp,
    required this.scope,
    required this.focus,
    required this.total,
    required this.correct,
    required this.percent,
  });

  final String id;
  final DateTime timestamp;
  final List<String> scope;
  final String focus;
  final int total;
  final int correct;
  final int percent;

  factory TestArchiveEntry.fromMap(Map<String, Object?> row) {
    return TestArchiveEntry(
      id: row['test_id']! as String,
      timestamp: DateTime.parse(row['timestamp_local']! as String),
      scope: (jsonDecode(row['scope_json']! as String) as List)
          .map((e) => e.toString())
          .toList(),
      focus: row['focus']! as String,
      total: row['total']! as int,
      correct: row['correct']! as int,
      percent: row['percent']! as int,
    );
  }
}

class TestArchiveStore {
  static final DatabaseService _databaseService = DatabaseService();

  static Future<void> save({
    required List<String> scope,
    required String focus,
    required int total,
    required int correct,
  }) async {
    final now = DateTime.now();
    final db = await _databaseService.db;
    await db.insert('test_history', {
      'test_id': 'test_${now.microsecondsSinceEpoch}',
      'timestamp_local': now.toIso8601String(),
      'scope_json': jsonEncode(scope),
      'focus': focus,
      'total': total,
      'correct': correct,
      'percent': total == 0 ? 0 : (100 * correct / total).round(),
    });
  }

  static Future<List<TestArchiveEntry>> all() async {
    final db = await _databaseService.db;
    final rows = await db.query('test_history', orderBy: 'timestamp_local DESC');
    return rows.map(TestArchiveEntry.fromMap).toList();
  }
}

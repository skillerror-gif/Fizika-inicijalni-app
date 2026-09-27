import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ProgressAttempt {
  const ProgressAttempt({
    required this.questionId,
    required this.subdomain,
    required this.correct,
    required this.difficulty,
    required this.createdAt,
  });
  final String questionId, subdomain, difficulty;
  final bool correct;
  final int createdAt;
}

class ProgressSummary {
  const ProgressSummary({
    required this.subdomain,
    required this.attempts,
    required this.uniqueQuestions,
    required this.weightedScore,
    required this.recentCorrect,
    required this.state,
  });
  final String subdomain, state;
  final int attempts, uniqueQuestions, recentCorrect;
  final double weightedScore;
  bool get isWeak => state == 'targeted';
}

class ProgressStore {
  static Database? _db;
  static Future<Database> database() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'fizika_progress_v1.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE attempts(id INTEGER PRIMARY KEY AUTOINCREMENT, question_id TEXT NOT NULL, subdomain TEXT NOT NULL, correct INTEGER NOT NULL, difficulty TEXT NOT NULL, created_at INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE INDEX idx_attempt_subdomain ON attempts(subdomain, created_at DESC)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          const migration = <String, String>{
            'Релативност кретања': 'KIN-01',
            'Пут и померај': 'KIN-02',
            'Средња векторска брзина': 'KIN-03',
            'Референтни системи': 'KIN-08',
            'Предмет, методе и задаци физике': 'UVF-01',
            'Физичке величине, мерење и SI јединице': 'UVF-02',
            'Скаларне и векторске физичке величине': 'UVF-03',
          };
          for (final e in migration.entries) {
            await db.update(
              'attempts',
              {'subdomain': e.value},
              where: 'subdomain=?',
              whereArgs: [e.key],
            );
          }
        }
      },
    );
    return _db!;
  }

  static Future<void> record({
    required String questionId,
    required String subdomain,
    required bool correct,
    String difficulty = 'basic',
  }) async {
    final db = await database();
    await db.insert('attempts', {
      'question_id': questionId,
      'subdomain': subdomain,
      'correct': correct ? 1 : 0,
      'difficulty': difficulty,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<ProgressAttempt>> recent(
    String subdomain, {
    int limit = 12,
  }) async {
    final db = await database();
    final rows = await db.query(
      'attempts',
      where: 'subdomain=?',
      whereArgs: [subdomain],
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return rows
        .map(
          (r) => ProgressAttempt(
            questionId: r['question_id'] as String,
            subdomain: r['subdomain'] as String,
            correct: (r['correct'] as int) == 1,
            difficulty: r['difficulty'] as String,
            createdAt: r['created_at'] as int,
          ),
        )
        .toList();
  }

  static Future<List<String>> subdomains() async {
    final db = await database();
    final rows = await db.rawQuery(
      'SELECT DISTINCT subdomain FROM attempts ORDER BY subdomain',
    );
    return rows.map((r) => r['subdomain'] as String).toList();
  }
}

class AdaptiveEngine {
  static double _difficultyWeight(String d) => d == 'advanced'
      ? 1.5
      : d == 'intermediate'
          ? 1.25
          : 1.0;
  static double _recencyWeight(int newestIndex) => newestIndex < 4
      ? 1.0
      : newestIndex < 8
          ? 0.85
          : 0.70;
  static ProgressSummary evaluate(
    String subdomain,
    List<ProgressAttempt> newestFirst,
  ) {
    final a = newestFirst.take(12).toList();
    final unique = a.map((e) => e.questionId).toSet().length;
    var num = 0.0, den = 0.0;
    for (var i = 0; i < a.length; i++) {
      final w = _difficultyWeight(a[i].difficulty) * _recencyWeight(i);
      den += w;
      if (a[i].correct) num += w;
    }
    final score = den == 0 ? 0.0 : 100 * num / den;
    final recent5 = a.take(5).toList();
    final recentCorrect = recent5.where((x) => x.correct).length;
    final recentUnique = recent5.map((e) => e.questionId).toSet().length;
    String state = 'insufficient';
    if (a.length >= 5 && unique >= 3) {
      if (score < 60) {
        state = 'targeted';
      } else if (score < 75) {
        state = 'consolidation';
      } else if (a.length >= 8 &&
          unique >= 4 &&
          recentCorrect >= 4 &&
          recentUnique >= 3) {
        state = 'stable';
      } else {
        state = 'consolidation';
      }
    }
    return ProgressSummary(
      subdomain: subdomain,
      attempts: a.length,
      uniqueQuestions: unique,
      weightedScore: score,
      recentCorrect: recentCorrect,
      state: state,
    );
  }

  static Future<List<ProgressSummary>> all() async {
    final ids = await ProgressStore.subdomains();
    final out = <ProgressSummary>[];
    for (final id in ids) {
      out.add(evaluate(id, await ProgressStore.recent(id)));
    }
    return out;
  }
}

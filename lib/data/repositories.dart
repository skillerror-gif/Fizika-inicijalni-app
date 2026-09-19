import '../domain/models.dart';
abstract class QuestionRepository { Future<List<Question>> eligibleQuestions({required int currentUnlock,String? lessonId}); }
abstract class ProgressRepository { Future<void> saveAttempt(Attempt attempt); Future<List<Attempt>> attemptsForLesson(String lessonId,{int limit=12}); Future<void> clearLocalProgress(); }
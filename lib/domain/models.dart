enum Difficulty { basic, intermediate, advanced }

enum PracticeState { insufficientData, targetedPractice, consolidation, stable }

class Question {
  const Question({
    required this.id,
    required this.lessonId,
    required this.unlockOrder,
    required this.difficulty,
    required this.stem,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
    required this.published,
    required this.scientificPass,
    required this.adaptiveEnabled,
    required this.metadataComplete,
  });
  final String id, lessonId, stem, correctOptionId, explanation;
  final int unlockOrder;
  final Difficulty difficulty;
  final Map<String, String> options;
  final bool published, scientificPass, adaptiveEnabled, metadataComplete;
}

class Attempt {
  const Attempt({
    required this.id,
    required this.questionId,
    required this.lessonId,
    required this.difficulty,
    required this.correct,
    required this.at,
    this.errorCategory,
  });
  final String id, questionId, lessonId;
  final Difficulty difficulty;
  final bool correct;
  final DateTime at;
  final String? errorCategory;
}

class LessonDiagnosis {
  const LessonDiagnosis(
    this.state,
    this.score,
    this.attemptCount,
    this.uniqueQuestions, {
    this.errorSignal,
  });
  final PracticeState state;
  final double? score;
  final int attemptCount, uniqueQuestions;
  final String? errorSignal;
}

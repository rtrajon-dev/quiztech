import 'package:hive_flutter/hive_flutter.dart';

/// Thin wrapper over the Hive `quiz_progress` box.
///
/// Two logical maps live inside the box:
///  - `all_quizzes`  → ongoing/started quizzes keyed by quiz id
///  - `all_scores`   → completed-attempt history keyed by quiz id
class QuizStorageService {
  static const String boxName = 'quiz_progress';

  Box get box => Hive.box(boxName);

  /// Opens the Hive box. Call once during app bootstrap.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  Map<String, dynamic> getAllScores() {
    final raw = box.get('all_scores');
    return (raw is Map) ? Map<String, dynamic>.from(raw) : {};
  }

  Map<String, dynamic> getAllQuizzes() {
    final raw = box.get('all_quizzes', defaultValue: {});
    return (raw is Map) ? Map<String, dynamic>.from(raw) : {};
  }

  List<MapEntry<String, dynamic>> getSortedScoresDescending() {
    final allScores = getAllScores();

    final sortedEntries = allScores.entries.toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(
              (a.value as List).last['date']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(
              (b.value as List).last['date']?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

    return sortedEntries;
  }

  Future<void> addScore({
    required String quizId,
    required int score,
    required int attempted,
    required int total,
  }) async {
    final allScores = getAllScores();

    final newScoreData = {
      'score': score,
      'attempted': attempted,
      'total': total,
      'date': DateTime.now().toIso8601String(),
    };

    final quizScores = (allScores[quizId] as List<dynamic>?)?.toList() ?? [];
    quizScores.add(newScoreData);
    allScores[quizId] = quizScores;

    await box.put('all_scores', allScores);
  }
}

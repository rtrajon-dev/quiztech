import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quiztech/app/di/app_providers.dart';

/// Holds the quiz score history (latest-first), mirroring the original
/// ScoreProvider. Backed by the Hive `quiz_progress` box.
class ScoreViewModel extends Notifier<List<MapEntry<String, dynamic>>> {
  @override
  List<MapEntry<String, dynamic>> build() {
    return ref.read(quizStorageServiceProvider).getSortedScoresDescending();
  }

  List<MapEntry<String, dynamic>> get scores => state;

  void loadScores() {
    state = ref.read(quizStorageServiceProvider).getSortedScoresDescending();
  }
}

final scoreViewModelProvider =
    NotifierProvider<ScoreViewModel, List<MapEntry<String, dynamic>>>(
  ScoreViewModel.new,
);

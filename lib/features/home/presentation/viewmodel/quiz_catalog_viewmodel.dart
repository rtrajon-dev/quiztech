import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:quiztech/app/di/app_providers.dart';
import 'package:quiztech/features/quiz/data/quiz_dummy_data.dart';
import 'package:quiztech/features/quiz/domain/models/quiz_model.dart';

/// UI state for the home quiz catalog.
class QuizCatalogState {
  final String selectedCategoryId;
  final String searchText;
  final List<Map<String, dynamic>> allPlayedQuizzes;

  const QuizCatalogState({
    this.selectedCategoryId = 'popular',
    this.searchText = '',
    this.allPlayedQuizzes = const [],
  });

  QuizCatalogState copyWith({
    String? selectedCategoryId,
    String? searchText,
    List<Map<String, dynamic>>? allPlayedQuizzes,
  }) {
    return QuizCatalogState(
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchText: searchText ?? this.searchText,
      allPlayedQuizzes: allPlayedQuizzes ?? this.allPlayedQuizzes,
    );
  }
}

/// Drives the home screen: category/search filtering, ongoing-quiz tracking,
/// and the background expiry checker that auto-submits timed-out quizzes.
class QuizCatalogViewModel extends Notifier<QuizCatalogState> {
  late final Box _quizBox;
  Timer? _expiryCheckTimer;
  VoidCallback? _boxListener;

  @override
  QuizCatalogState build() {
    _quizBox = ref.read(quizStorageServiceProvider).box;

    _boxListener = _refreshData;
    _quizBox.listenable().addListener(_boxListener!);
    _startPeriodicExpiryCheck();

    ref.onDispose(() {
      _expiryCheckTimer?.cancel();
      if (_boxListener != null) {
        _quizBox.listenable().removeListener(_boxListener!);
      }
    });

    return QuizCatalogState(allPlayedQuizzes: _readPlayedQuizzes());
  }

  // ── Derived data ──────────────────────────────────────────────

  List<QuizSummary> get filteredQuizzes {
    return quizSummaries
        .where((q) =>
            q.categoryId == state.selectedCategoryId &&
            q.title.toLowerCase().contains(state.searchText.toLowerCase()))
        .toList();
  }

  Set<String> get ongoingQuizIds => Set<String>.from(
        (_quizBox.get('all_quizzes', defaultValue: {}) as Map)
            .keys
            .cast<String>(),
      );

  Set<String> get playedQuizIds => Set<String>.from(
        (_quizBox.get('all_scores', defaultValue: {}) as Map)
            .keys
            .cast<String>(),
      );

  String getQuizImage(String quizId) {
    try {
      final quiz = quizSummaries.firstWhere((q) => q.id == quizId);
      return quiz.imageAsset.isNotEmpty
          ? quiz.imageAsset
          : 'assets/placeholder.png';
    } catch (_) {
      return 'assets/placeholder.png';
    }
  }

  // ── Intents ───────────────────────────────────────────────────

  void setSearchText(String value) {
    var categoryId = state.selectedCategoryId;
    if (value.isEmpty) {
      categoryId = 'popular';
    } else {
      try {
        final matchingQuiz = quizSummaries.firstWhere(
            (q) => q.title.toLowerCase().contains(value.toLowerCase()));
        categoryId = matchingQuiz.categoryId;
      } catch (_) {
        // No quiz found, keep current category.
      }
    }
    state = state.copyWith(searchText: value, selectedCategoryId: categoryId);
  }

  void setSelectedCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  Future<void> startQuiz(QuizDetail quizDetail) async {
    final allQuizzes = Map<String, dynamic>.from(
        _quizBox.get('all_quizzes', defaultValue: {}) as Map);

    final existingData = allQuizzes[quizDetail.id];

    if (existingData == null || existingData['scoreAdded'] == true) {
      allQuizzes[quizDetail.id] = {
        'startTime': DateTime.now().toIso8601String(),
        'currentQuestionIndex': 0,
        'selectedAnswers': <String, String>{},
        'scoreAdded': false,
      };
      await _quizBox.put('all_quizzes', allQuizzes);
    }
    // If a quiz is already ongoing, let the user continue it.
  }

  Future<void> removeQuiz(String quizId) async {
    final all = Map<String, dynamic>.from(
        _quizBox.get('all_quizzes', defaultValue: {}) as Map);

    if (all.containsKey(quizId)) {
      all.remove(quizId);
      await _quizBox.put('all_quizzes', all);
      loadAllPlayedQuizzes();
    }
  }

  void loadAllPlayedQuizzes() {
    state = state.copyWith(allPlayedQuizzes: _readPlayedQuizzes());
  }

  // ── Internals ─────────────────────────────────────────────────

  void _refreshData() {
    loadAllPlayedQuizzes();
  }

  List<Map<String, dynamic>> _readPlayedQuizzes() {
    final allSaved = Map<String, dynamic>.from(
        _quizBox.get('all_quizzes', defaultValue: {}) as Map);
    final List<Map<String, dynamic>> loaded = [];

    allSaved.forEach((quizId, savedData) {
      try {
        final quizDetail = quizDetails.firstWhere((q) => q.id == quizId);
        if (savedData['currentQuestionIndex'] < quizDetail.questions.length) {
          loaded.add({
            'quizDetail': quizDetail,
            'currentQuestionIndex': savedData['currentQuestionIndex'] ?? 0,
            'selectedAnswers':
                Map<String, String>.from(savedData['selectedAnswers'] ?? {}),
            'startTime': savedData['startTime'],
          });
        }
      } catch (e) {
        debugPrint('Quiz not found for ID: $quizId');
      }
    });

    return loaded;
  }

  void _startPeriodicExpiryCheck() {
    _expiryCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkExpiredQuizzes();
    });
  }

  Future<void> _checkExpiredQuizzes() async {
    final all = Map<String, dynamic>.from(
        _quizBox.get('all_quizzes', defaultValue: {}) as Map);
    bool changed = false;

    for (var entry in all.entries) {
      final quizId = entry.key;
      final savedData = Map<String, dynamic>.from(entry.value);

      if (savedData['scoreAdded'] == true) continue;

      QuizDetail? quizDetail;
      try {
        quizDetail = quizDetails.firstWhere((q) => q.id == quizId);
      } catch (_) {
        continue;
      }

      if (savedData['startTime'] == null) continue;

      final startTime = DateTime.parse(savedData['startTime']);
      final durationMinutes = int.tryParse(
              quizDetail.duration.replaceAll(RegExp(r'[^0-9]'), '')) ??
          30;
      final expiry = startTime.add(Duration(minutes: durationMinutes));

      if (DateTime.now().isBefore(expiry)) continue;

      final selectedAnswers =
          Map<String, String>.from(savedData['selectedAnswers'] ?? {});
      int correctCount = 0;
      for (var q in quizDetail.questions) {
        if (selectedAnswers[q.id] == q.correctOptionId) correctCount++;
      }

      final allScores = Map<String, dynamic>.from(
          _quizBox.get('all_scores', defaultValue: {}) as Map);
      final scoreData = {
        'score': correctCount,
        'attempted': selectedAnswers.length,
        'total': quizDetail.totalQuestions,
        'date': DateTime.now().toIso8601String(),
      };

      if (!allScores.containsKey(quizId)) allScores[quizId] = [];
      allScores[quizId].add(scoreData);
      await _quizBox.put('all_scores', allScores);

      savedData['scoreAdded'] = true;
      all[quizId] = savedData;
      changed = true;
    }

    if (changed) {
      await _quizBox.put('all_quizzes', all);
      loadAllPlayedQuizzes();
    }
  }
}

final quizCatalogViewModelProvider =
    NotifierProvider<QuizCatalogViewModel, QuizCatalogState>(
  QuizCatalogViewModel.new,
);

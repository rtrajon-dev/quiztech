import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quiztech/core/services/quiz_storage_service.dart';

/// Shared, app-wide singletons exposed to the Riverpod graph.
final quizStorageServiceProvider = Provider<QuizStorageService>((ref) {
  return QuizStorageService();
});

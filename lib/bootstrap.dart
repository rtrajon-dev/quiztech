import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quiztech/app/app.dart';
import 'package:quiztech/core/services/quiz_storage_service.dart';

/// Initializes platform bindings and local storage, then boots the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the Hive box used for quiz progress + scores.
  await QuizStorageService.init();

  runApp(
    const ProviderScope(
      child: QuizTechApp(),
    ),
  );
}

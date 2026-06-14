import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:quiztech/app/router/app_router.dart';
import 'package:quiztech/app/theme/app_theme.dart';

class QuizTechApp extends ConsumerWidget {
  const QuizTechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'QuizTech',
          theme: AppTheme.light,
          routerConfig: router,
        );
      },
    );
  }
}

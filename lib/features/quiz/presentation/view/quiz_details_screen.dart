import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:quiztech/app/router/app_routes.dart';
import 'package:quiztech/app/theme/app_colors.dart';
import 'package:quiztech/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:quiztech/features/home/presentation/viewmodel/quiz_catalog_viewmodel.dart';
import 'package:quiztech/features/quiz/domain/models/quiz_model.dart';

class QuizDetailsScreen extends ConsumerStatefulWidget {
  final QuizDetail quizDetail;
  const QuizDetailsScreen({super.key, required this.quizDetail});

  @override
  ConsumerState<QuizDetailsScreen> createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends ConsumerState<QuizDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final catalog = ref.watch(quizCatalogViewModelProvider.notifier);
    final user = auth.user?['user'];
    final profileImg = (user?['profileImg'] ?? '').toString();
    final quiz = widget.quizDetail;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          "Quiz Details",
          style: TextStyle(
            fontSize: 18.sp,
            fontFamily: 'Ubuntu',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage:
                  profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
              child: profileImg.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.blueGrey)
                  : null,
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 120.h),
              // Quiz Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontFamily: 'Ubuntu',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "get 100 points",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontFamily: 'Ubuntu',
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 5.w),
                        Text(
                          "4.8",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontFamily: 'Ubuntu',
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15.h),
              // White section
              Container(
                width: double.infinity,
                height: 729.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                ),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),
                      Text(
                        "Brief Explanation about this quiz",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: 'Ubuntu',
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Column(
                        children: [
                          _buildInfoItem(
                            "${quiz.totalQuestions} questions",
                            "10 points for a correct answer",
                            Icons.help_outline,
                          ),
                          SizedBox(height: 15.h),
                          _buildInfoItem(
                            quiz.duration,
                            "Total duration of the quiz",
                            Icons.timer_outlined,
                          ),
                          SizedBox(height: 15.h),
                          _buildInfoItem(
                            "Win ${quiz.pointsPerCorrect} stars",
                            "Answer all questions correctly",
                            Icons.star_border,
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                      Text(
                        "Please read the text below carefully so you can understand it",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Ubuntu',
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: quiz.rules.map((rule) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                    radius: 3.r,
                                    backgroundColor: Colors.black),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    rule,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: 'Ubuntu',
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 40.h),
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: Builder(
                          builder: (context) {
                            final quizId = widget.quizDetail.id;
                            final isOngoing =
                                catalog.ongoingQuizIds.contains(quizId);
                            final hasBeenPlayed =
                                catalog.playedQuizIds.contains(quizId);
                            final buttonText = isOngoing
                                ? "Continue Quiz"
                                : (hasBeenPlayed ? "Play Again" : "Start Quiz");
                            final buttonColor = isOngoing
                                ? Colors.green
                                : (hasBeenPlayed
                                    ? Colors.orange
                                    : Colors.blue);
                            return ElevatedButton(
                              onPressed: () async {
                                await catalog.startQuiz(widget.quizDetail);
                                if (context.mounted) {
                                  context
                                      .push(AppRoutes.quizPlay,
                                          extra: widget.quizDetail)
                                      .then((_) {
                                    if (context.mounted) context.pop();
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: Text(
                                buttonText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontFamily: 'Ubuntu',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundColor: Colors.black,
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: 'Ubuntu',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: 'Ubuntu',
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:quiztech/app/router/app_routes.dart';
import 'package:quiztech/features/home/presentation/viewmodel/quiz_catalog_viewmodel.dart';
import 'package:quiztech/features/quiz/domain/models/quiz_model.dart';
import 'package:quiztech/features/score/presentation/viewmodel/score_viewmodel.dart';

/// Horizontal card for an in-progress quiz: shows the live countdown and lets
/// the user resume or discard it. Submission on time-out is handled in the
/// background by [QuizCatalogViewModel].
class ContinueQuizCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> quizData;
  final String quizImage;

  const ContinueQuizCard({
    super.key,
    required this.quizData,
    required this.quizImage,
  });

  @override
  ConsumerState<ContinueQuizCard> createState() => _ContinueQuizCardState();
}

class _ContinueQuizCardState extends ConsumerState<ContinueQuizCard> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _isTimeOver = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    final quizDetail = widget.quizData['quizDetail'] as QuizDetail;
    final startTimeString = widget.quizData['startTime'];

    if (startTimeString == null) {
      if (mounted) setState(() => _isTimeOver = true);
      return;
    }

    final startTime = DateTime.tryParse(startTimeString) ?? DateTime.now();
    final durationMinutes =
        int.tryParse(quizDetail.duration.replaceAll(RegExp(r'[^0-9]'), '')) ??
            30;
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final newRemaining = endTime.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _remaining = newRemaining;
        _isTimeOver = _remaining.isNegative;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.read(quizCatalogViewModelProvider.notifier);
    final quizDetail = widget.quizData['quizDetail'] as QuizDetail;
    final selectedAnswers =
        Map<String, String>.from(widget.quizData['selectedAnswers']);

    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    final buttonText =
        _isTimeOver ? "Time Over! Score Submitted" : "Continue Quiz";

    return Container(
      width: 270.w,
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Image + Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.asset(
                      widget.quizImage,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey,
                        child: const Icon(Icons.quiz, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quizDetail.title,
                        style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(children: [
                        const Icon(Icons.book, size: 14, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                            "${selectedAnswers.length}/${quizDetail.totalQuestions} Questions",
                            style: TextStyle(
                                fontSize: 13.sp, color: Colors.grey[600])),
                      ]),
                      Row(children: [
                        const Icon(Icons.timer, size: 14, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          _isTimeOver ? "00:00" : "$minutes:$seconds",
                          style: TextStyle(
                              color: _isTimeOver
                                  ? Colors.redAccent
                                  : Colors.red[300],
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                    ],
                  ),
                ),
                // Delete button
                GestureDetector(
                  onTap: () async {
                    await catalog.removeQuiz(quizDetail.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("${quizDetail.title} removed.")));
                    }
                  },
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 36.h,
              child: ElevatedButton(
                onPressed: _isTimeOver
                    ? null
                    : () {
                        context
                            .push(AppRoutes.quizPlay, extra: quizDetail)
                            .then((_) {
                          catalog.loadAllPlayedQuizzes();
                          ref.read(scoreViewModelProvider.notifier).loadScores();
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTimeOver ? Colors.grey[400] : Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                      color: _isTimeOver ? Colors.redAccent : Colors.white,
                      fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:quiztech/app/theme/app_colors.dart';
import 'package:quiztech/core/services/quiz_storage_service.dart';
import 'package:quiztech/features/quiz/domain/models/quiz_model.dart';
import 'package:quiztech/features/quiz/presentation/viewmodel/sound_viewmodel.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  final QuizDetail quizDetail;
  const QuizPlayScreen({super.key, required this.quizDetail});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  final player = AudioPlayer();

  String feedbackText = "";
  Color feedbackColor = Colors.blue;
  bool isCorrect = false;

  Timer? countdownTimer;
  int remainingSeconds = 60;
  bool timeUp = false;

  int currentQuestionIndex = 0;
  Set<String> answeredQuestions = {};
  Map<String, String> selectedAnswers = {}; // questionId -> optionId

  Box get _box => Hive.box(QuizStorageService.boxName);

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _startTimer();
  }

  @override
  void dispose() {
    player.stop();
    player.dispose();
    countdownTimer?.cancel();
    super.dispose();
  }

  void playCorrectSound() {
    if (ref.read(soundViewModelProvider)) {
      player.play(AssetSource('correct.wav'));
    }
  }

  void playWrongSound() {
    if (ref.read(soundViewModelProvider)) {
      player.play(AssetSource('wrong.wav'));
    }
  }

  void playScoreSound() {
    if (ref.read(soundViewModelProvider)) {
      player.play(AssetSource('score.wav'));
    }
  }

  void _startTimer() {
    countdownTimer?.cancel();
    remainingSeconds = 60;
    timeUp = false;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          timeUp = true;
          feedbackColor = Colors.red;

          final currentQ = widget.quizDetail.questions[currentQuestionIndex];

          if (!answeredQuestions.contains(currentQ.id)) {
            answeredQuestions.add(currentQ.id);

            feedbackText =
                "Time's up! Correct answer: ${currentQ.options.firstWhere((o) => o.id == currentQ.correctOptionId).text}\nNext Q in 3";

            _saveProgress();
          }
        });

        int nextCountdown = 3;
        Timer.periodic(const Duration(seconds: 1), (nextTimer) {
          nextCountdown--;
          if (nextCountdown > 0) {
            setState(() {
              feedbackText =
                  "Time's up! Correct answer: ${widget.quizDetail.questions[currentQuestionIndex].options.firstWhere((o) => o.id == widget.quizDetail.questions[currentQuestionIndex].correctOptionId).text}\nNext Q in $nextCountdown";
            });
          } else {
            nextTimer.cancel();
            setState(() {
              feedbackText = "";
              if (currentQuestionIndex <
                  widget.quizDetail.questions.length - 1) {
                currentQuestionIndex++;
                timeUp = false;
                _startTimer();
              }
            });
          }
        });
      }
    });
  }

  void _loadProgress() {
    final allProgress = Map<String, dynamic>.from(
      _box.get('all_quizzes', defaultValue: {}) as Map,
    );

    final savedData = allProgress[widget.quizDetail.id];

    if (savedData != null) {
      setState(() {
        currentQuestionIndex = savedData['currentQuestionIndex'] ?? 0;
        selectedAnswers =
            Map<String, String>.from(savedData['selectedAnswers'] ?? {});
        answeredQuestions = selectedAnswers.keys.toSet();
      });
    }
  }

  void _saveProgress() async {
    final allProgress = Map<String, dynamic>.from(
      _box.get('all_quizzes', defaultValue: {}) as Map,
    );

    // Preserve startTime/scoreAdded set when the quiz was started.
    final existing = Map<String, dynamic>.from(
        (allProgress[widget.quizDetail.id] as Map?) ?? {});
    existing['currentQuestionIndex'] = currentQuestionIndex;
    existing['selectedAnswers'] = selectedAnswers;
    allProgress[widget.quizDetail.id] = existing;

    await _box.put('all_quizzes', allProgress);
  }

  void _clearProgressForQuiz(String quizId) async {
    final allProgress = Map<String, dynamic>.from(
      _box.get('all_quizzes', defaultValue: {}) as Map,
    );

    allProgress.remove(quizId);
    await _box.put('all_quizzes', allProgress);
  }

  /// Saves the current progress and leaves the quiz, confirming to the user
  /// that they can resume it later (and that it is time-limited).
  void _saveAndExit() {
    _saveProgress();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Saved! Resume this quiz from Home before the timer runs out.",
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quizDetail;
    final currentQuestion = quiz.questions[currentQuestionIndex];

    final allAnswered = (answeredQuestions.length == quiz.questions.length);
    final isFirst = currentQuestionIndex == 0;
    final isLast = currentQuestionIndex == quiz.questions.length - 1;
    final currentAnswered =
        selectedAnswers.containsKey(currentQuestion.id) ||
            answeredQuestions.contains(currentQuestion.id);

    final disablePrevBtn = isFirst ||
        !allAnswered ||
        (!answeredQuestions.contains(currentQuestion.id) && !timeUp);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _saveAndExit,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        title: Text(
          quiz.title,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Ubuntu',
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Container(
              width: 72.w,
              height: 28.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.black),
                  SizedBox(width: 4.w),
                  Text(
                    "${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontSize: 14.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
              SizedBox(height: 100.h),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 760.h),
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
                      _buildProgressRow(quiz),
                      SizedBox(height: 24.h),
                      // Animate the question + options between questions so the
                      // transition feels fluid instead of snapping.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (currentChild, previousChildren) => Stack(
                          alignment: Alignment.topLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.12, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(currentQuestionIndex),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 60,
                              child: Text(
                                currentQuestion.text,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'Ubuntu',
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Column(
                              children: currentQuestion.options.map((option) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: GestureDetector(
                                    onTap: answeredQuestions
                                                .contains(currentQuestion.id) ||
                                            timeUp
                                        ? null
                                        : () {
                                            setState(() {
                                              selectedAnswers[
                                                      currentQuestion.id] =
                                                  option.id;
                                              answeredQuestions
                                                  .add(currentQuestion.id);

                                              if (option.id ==
                                                  currentQuestion
                                                      .correctOptionId) {
                                                isCorrect = true;
                                                feedbackText = "Correct!";
                                                feedbackColor = Colors.green;
                                                playCorrectSound();
                                              } else {
                                                isCorrect = false;
                                                feedbackText =
                                                    "Wrong! Correct answer: ${currentQuestion.options.firstWhere((o) => o.id == currentQuestion.correctOptionId).text}";
                                                feedbackColor = Colors.red;
                                                playWrongSound();
                                              }

                                              _saveProgress();
                                              countdownTimer?.cancel();

                                              Future.delayed(
                                                  const Duration(seconds: 3),
                                                  () {
                                                if (mounted) {
                                                  setState(() {
                                                    feedbackText = "";
                                                  });
                                                }
                                              });
                                            });
                                          },
                                    child:
                                        _buildOption(option, currentQuestion),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40.h),
                      AnimatedOpacity(
                        opacity: feedbackText.isNotEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          height: 60.h,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          margin: EdgeInsets.only(top: 12.h),
                          decoration: BoxDecoration(
                            color: feedbackText.isNotEmpty
                                ? (isCorrect
                                    ? Colors.green.shade100
                                    : Colors.red.shade100)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (feedbackText.isNotEmpty)
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel_outlined,
                                  color: isCorrect ? Colors.green : Colors.red,
                                  size: 20.r,
                                ),
                              if (feedbackText.isNotEmpty) SizedBox(width: 6.w),
                              Expanded(
                                child: Builder(builder: (context) {
                                  if (feedbackText.startsWith("Time's up!")) {
                                    final parts = feedbackText.split("\n");
                                    return RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontFamily: 'Ubuntu',
                                          fontWeight: FontWeight.w600,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "${parts[0]}\n",
                                            style: const TextStyle(
                                                color: Colors.red),
                                          ),
                                          TextSpan(
                                            text:
                                                parts.length > 1 ? parts[1] : "",
                                            style: const TextStyle(
                                                color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      feedbackText.isNotEmpty
                                          ? feedbackText
                                          : " ",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontFamily: 'Ubuntu',
                                        fontWeight: FontWeight.w600,
                                        color: feedbackColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    );
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 80.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous Button
                          GestureDetector(
                            onTap: disablePrevBtn
                                ? null
                                : () {
                                    setState(() {
                                      feedbackText = "";
                                      currentQuestionIndex--;
                                    });
                                  },
                            child: CircleAvatar(
                              radius: 22.r,
                              backgroundColor: disablePrevBtn
                                  ? AppColors.grey
                                  : Colors.blue,
                              child: Image.asset(
                                'assets/prevbtn.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          // Submit Button
                          SizedBox(
                            width: 195.w,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: allAnswered && isLast
                                  ? () => _submitQuiz(quiz)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: allAnswered && isLast
                                    ? Colors.white
                                    : Colors.grey.shade300,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                  side: BorderSide(
                                    color: allAnswered && isLast
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Text(
                                "Submit Quiz",
                                style: TextStyle(
                                  color: allAnswered && isLast
                                      ? Colors.blue
                                      : Colors.grey,
                                  fontSize: 16.sp,
                                  fontFamily: 'Ubuntu',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Next Button
                          GestureDetector(
                            onTap: (currentAnswered && !isLast)
                                ? () {
                                    setState(() {
                                      feedbackText = "";
                                      currentQuestionIndex++;
                                      timeUp = false;
                                    });

                                    final nextQuestionId = widget.quizDetail
                                        .questions[currentQuestionIndex].id;
                                    final nextAlreadyAnswered = selectedAnswers
                                        .containsKey(nextQuestionId);

                                    if (!nextAlreadyAnswered) {
                                      _startTimer();
                                    }
                                  }
                                : null,
                            child: CircleAvatar(
                              radius: 22.r,
                              backgroundColor: (currentAnswered && !isLast)
                                  ? Colors.blue
                                  : AppColors.grey,
                              child: Image.asset(
                                'assets/nextbtn.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Explicit "play later" affordance so users know they can
                      // leave and resume the quiz before its timer expires.
                      Center(
                        child: TextButton.icon(
                          onPressed: _saveAndExit,
                          icon: const Icon(Icons.bookmark_add_outlined,
                              color: Colors.blue),
                          label: Text(
                            "Save & Play Later",
                            style: TextStyle(
                              color: Colors.blue,
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),
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

  /// Progress Row (1, 2, 3, ...)
  final ScrollController scrollController = ScrollController();
  int _lastScrolledIndex = -1;

  Widget _buildProgressRow(QuizDetail quiz) {
    if (_lastScrolledIndex != currentQuestionIndex) {
      _lastScrolledIndex = currentQuestionIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final position = currentQuestionIndex * 60.0;
        if (scrollController.hasClients) {
          scrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return SizedBox(
      height: 70.h,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: quiz.questions.length,
        itemBuilder: (context, index) {
          final isActive = index == currentQuestionIndex;
          final isAnswered =
              selectedAnswers.containsKey(quiz.questions[index].id);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: isActive
                      ? Colors.blue
                      : (isAnswered ? Colors.green : AppColors.grey),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  width: 40.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue
                        : (isAnswered ? Colors.green : AppColors.grey),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Option tile
  Widget _buildOption(Option option, Question currentQuestion) {
    final selectedOptionId = selectedAnswers[currentQuestion.id];
    final isAnswered = answeredQuestions.contains(currentQuestion.id);

    Color getOptionColor() {
      if (!isAnswered) {
        return selectedOptionId == option.id ? Colors.blue : Colors.black;
      } else {
        if (option.id == currentQuestion.correctOptionId) {
          return Colors.green;
        } else if (option.id == selectedOptionId &&
            selectedOptionId != currentQuestion.correctOptionId) {
          return Colors.red;
        } else {
          return AppColors.grey;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: getOptionColor(),
            child: Text(
              option.label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              option.text,
              style: TextStyle(
                color: getOptionColor(),
                fontSize: 14.sp,
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Submit Logic
  void _submitQuiz(QuizDetail quiz) async {
    int correctCount = 0;
    for (var q in quiz.questions) {
      if (selectedAnswers[q.id] == q.correctOptionId) {
        correctCount++;
      }
    }
    final attempted = selectedAnswers.length;
    final total = quiz.questions.length;

    final allScores = Map<String, dynamic>.from(
        _box.get('all_scores', defaultValue: {}) as Map);

    final scoreData = {
      'score': correctCount,
      'attempted': attempted,
      'total': total,
      'date': DateTime.now().toIso8601String(),
    };

    allScores.putIfAbsent(quiz.id, () => []);
    allScores[quiz.id].add(scoreData);
    await _box.put('all_scores', allScores);

    _clearProgressForQuiz(quiz.id);
    if (mounted) _showResultDialog(correctCount, quiz);
  }

  void _showResultDialog(int score, QuizDetail quiz) {
    playScoreSound();

    final yourScore = score * quiz.pointsPerCorrect;
    final totalScore = quiz.questions.length * quiz.pointsPerCorrect;
    final percentage = (score / totalScore) * 100;

    String title;
    String emoji;
    Color titleColor;
    String message;

    if (percentage < 30) {
      title = "Keep Trying!";
      emoji = "😕";
      titleColor = Colors.red;
      message =
          "You scored below average. Don’t worry — every expert was once a beginner! Try again and you’ll improve!";
    } else if (percentage < 50) {
      title = "Good Effort!";
      emoji = "🙂";
      titleColor = Colors.orange;
      message =
          "You’re getting there! You performed better than many players. Keep practicing to reach the top!";
    } else if (percentage < 70) {
      title = "Very Good!";
      emoji = "😄";
      titleColor = Colors.blue;
      message =
          "Nice work! You scored above average. You’re better than 60% of players. Keep going!";
    } else if (percentage < 85) {
      title = "Excellent!";
      emoji = "🌟";
      titleColor = Colors.green;
      message =
          "Great job! You’re among the top performers! Keep learning and keep shining!";
    } else {
      title = "Outstanding!";
      emoji = "🏆";
      titleColor = Colors.purple;
      message =
          "You’re a champion! This is a brilliant score! You're in the top 10% of players — amazing!";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontFamily: 'Ubuntu',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your Score: $yourScore / $totalScore",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Ubuntu',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontFamily: 'Ubuntu',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Ubuntu',
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        context.pop(); // Leave the quiz screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Go to Home",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Ubuntu',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:quiztech/app/router/app_routes.dart';
import 'package:quiztech/app/theme/app_colors.dart';
import 'package:quiztech/core/services/quiz_storage_service.dart';
import 'package:quiztech/core/utils/score_utils.dart';
import 'package:quiztech/features/auth/presentation/viewmodel/auth_viewmodel.dart';

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user?['user'] ?? {};
    final userName = user['fullName'] ?? 'User';

    final box = Hive.box(QuizStorageService.boxName);

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['all_scores']),
      builder: (context, Box box, _) {
        final allScoresRaw = box.get('all_scores');
        final allScores = ScoreUtils.normalizeAllScores(allScoresRaw);
        final totalScore = ScoreUtils.calculateTotalScore(allScores);
        final entries = allScores.entries.toList();

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                child: Column(
                  children: [
                    // ── Scrollable area: header (circle + text) + score list ──
                    // The header scrolls up and away as the user scrolls the
                    // list, giving the list the full available height.
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 30.h),
                                _buildScoreCircle(totalScore),
                                SizedBox(height: 24.h),
                                Text(
                                  "Congratulations!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "Great job, $userName! You did it.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                              ],
                            ),
                          ),
                          if (entries.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  "No scores yet.",
                                  style: TextStyle(
                                      fontSize: 14.sp, color: Colors.white70),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final entry = entries[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 10.h),
                                    child: _buildScoreTile(entry),
                                  );
                                },
                                childCount: entries.length,
                              ),
                            ),
                          // Breathing room between the last item and the
                          // pinned buttons.
                          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                        ],
                      ),
                    ),

                    // ── Pinned footer: buttons never move ──
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Share feature coming soon!"),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text(
                          "Share",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.home),
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: const Text(
                          "Go to Home",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCircle(int totalScore) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 110.r,
            backgroundColor: Colors.indigo.shade700,
          ),
          CircleAvatar(
            radius: 86.r,
            backgroundColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Total Score",
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "$totalScore",
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTile(MapEntry<String, dynamic> entry) {
    final quizId = entry.key;
    final scoresListRaw = entry.value as List<dynamic>? ?? [];
    final latestData = scoresListRaw.isNotEmpty
        ? Map<String, dynamic>.from(scoresListRaw.last)
        : {};
    final score =
        (latestData['score'] is num) ? (latestData['score'] as num).toInt() : 0;
    final total =
        (latestData['total'] is num) ? (latestData['total'] as num).toInt() : 0;
    final date =
        DateTime.tryParse(latestData['date']?.toString() ?? '') ??
            DateTime.now();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A333333),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Quiz: $quizId",
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 4.h),
              Text(
                "${date.day}/${date.month}/${date.year}",
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ),
          Text(
            "$score / $total",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}

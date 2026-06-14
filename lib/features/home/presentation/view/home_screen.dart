import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:quiztech/app/router/app_routes.dart';
import 'package:quiztech/app/theme/app_colors.dart';
import 'package:quiztech/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:quiztech/features/home/presentation/viewmodel/quiz_catalog_viewmodel.dart';
import 'package:quiztech/features/home/presentation/widgets/completed_quiz_card.dart';
import 'package:quiztech/features/home/presentation/widgets/continue_quiz_card.dart';
import 'package:quiztech/features/quiz/data/quiz_dummy_data.dart';
import 'package:quiztech/features/quiz/domain/models/quiz_model.dart';
import 'package:quiztech/features/score/presentation/viewmodel/score_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh derived data after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoreViewModelProvider.notifier).loadScores();
      ref.read(quizCatalogViewModelProvider.notifier).loadAllPlayedQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final catalogState = ref.watch(quizCatalogViewModelProvider);
    final catalog = ref.read(quizCatalogViewModelProvider.notifier);

    final user = auth.user?['user'];
    final userName = user?['fullName'] ?? 'User';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 100.h),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello $userName",
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w400)),
                      SizedBox(height: 8.h),
                      Text("Let's test your knowledge",
                          style: TextStyle(
                              fontSize: 20.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      TextField(
                        onChanged: catalog.setSearchText,
                        decoration: InputDecoration(
                          hintText: "Search",
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 15.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Quiz catalog card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
                    child: Column(
                      children: [
                        Container(
                          width: 48.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        SizedBox(height: 15.h),

                        // ======= CATEGORY TABS =======
                        SizedBox(
                          height: 40.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cate = categories[index];
                              final isActive =
                                  cate.id == catalogState.selectedCategoryId;
                              return GestureDetector(
                                onTap: () =>
                                    catalog.setSelectedCategory(cate.id),
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.w),
                                  child: _buildCategory(cate.title, isActive),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // ======= QUIZ CARDS =======
                        Column(
                          children: catalog.filteredQuizzes.map((q) {
                            final isOngoing =
                                catalog.ongoingQuizIds.contains(q.id);
                            final isPlayed =
                                catalog.playedQuizIds.contains(q.id);
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: isOngoing
                                      ? null
                                      : () {
                                          final quizDetail =
                                              quizDetails.firstWhere(
                                                  (d) => d.id == q.id);
                                          context.push(AppRoutes.quizDetails,
                                              extra: quizDetail);
                                        },
                                  child: _buildQuizCard(
                                    title: q.title,
                                    questions: '${q.totalQuestions} Question',
                                    duration: q.duration,
                                    rating: q.rating,
                                    imageAsset: q.imageAsset,
                                    bordered: isPlayed,
                                    disabled: isOngoing,
                                  ),
                                ),
                                SizedBox(height: 15.h),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Quiz history
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(0.w),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A333333),
                        offset: Offset(0, 0),
                        blurRadius: 50,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quiz History",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Builder(
                          builder: (context) {
                            final scores = ref.watch(scoreViewModelProvider);
                            if (scores.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.h),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.emoji_events_outlined,
                                        size: 36.sp,
                                        color: Colors.blueAccent,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        "Your first quiz awaits!\nChallenge yourself & start learning!",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: [
                                for (var entry in scores)
                                  CompletedQuizCard(
                                    quizEntry: entry,
                                    quizSummaries: quizSummaries,
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 50.h, color: Colors.white),
                if (catalogState.allPlayedQuizzes.isNotEmpty)
                  Container(height: 200.h, color: Colors.white),
              ],
            ),
          ),
          // ======= CONTINUE QUIZ =======
          Positioned(
            bottom: 0.h,
            left: 10.w,
            right: 10.w,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(0, -20),
                    blurRadius: 55,
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 5.h),
                  if (catalogState.allPlayedQuizzes.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Continue Pending Quizzes",
                          style: TextStyle(
                              fontSize: 18.sp,
                              fontFamily: "Ubuntu",
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                  SizedBox(height: 15.h),
                  _buildContinueQuizzesList(catalogState, catalog),
                ],
              ),
            ),
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // ===== CATEGORY BUILDER =====
  Widget _buildCategory(String title, bool active) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: active ? Colors.blue : Colors.grey,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            fontFamily: "Ubuntu",
          ),
        ),
        Container(
          width: 48.w,
          height: 2.h,
          color: active ? Colors.blue : Colors.white,
        ),
      ],
    );
  }

  // ===== QUIZ CARD BUILDER =====
  Widget _buildQuizCard({
    required String title,
    required String questions,
    required String duration,
    required String rating,
    required String imageAsset,
    bool bordered = false,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 96.h,
            decoration: BoxDecoration(
              color: Colors.white,
              border: bordered ? Border.all(color: Colors.blue) : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A333333),
                  offset: Offset(10, 24),
                  blurRadius: 54,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Row(
                children: [
                  Container(
                    width: 72.w,
                    height: 72.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey,
                            child: const Icon(Icons.image, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 5.h),
                        Row(children: [
                          const Icon(Icons.book, color: Colors.grey, size: 16),
                          SizedBox(width: 5.w),
                          Text(questions,
                              style: TextStyle(
                                  fontSize: 13.sp, color: Colors.grey[700])),
                        ]),
                        Row(children: [
                          const Icon(Icons.timer, color: Colors.grey, size: 16),
                          SizedBox(width: 5.w),
                          Text(duration,
                              style: TextStyle(
                                  fontSize: 13.sp, color: Colors.grey[700])),
                        ]),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      SizedBox(width: 5.w),
                      Text(rating, style: TextStyle(fontSize: 14.sp)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Badge
          Positioned(
            top: 6.h,
            right: 6.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.orange.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                disabled ? 'Ongoing' : (bordered ? 'Played' : ''),
                style: TextStyle(
                  color: disabled ? Colors.orange : Colors.blue,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== CONTINUE QUIZ LIST =====
  Widget _buildContinueQuizzesList(
      QuizCatalogState state, QuizCatalogViewModel catalog) {
    if (state.allPlayedQuizzes.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 150.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final quizData = state.allPlayedQuizzes[index];
          final quizDetail = quizData['quizDetail'] as QuizDetail;
          return ContinueQuizCard(
            quizData: quizData,
            quizImage: catalog.getQuizImage(quizDetail.id),
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemCount: state.allPlayedQuizzes.length,
      ),
    );
  }
}

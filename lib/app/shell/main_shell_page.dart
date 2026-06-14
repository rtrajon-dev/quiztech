import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quiztech/app/shell/widgets/drawer_layout.dart';
import 'package:quiztech/app/theme/app_colors.dart';
import 'package:quiztech/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:quiztech/global_widgets/avatar_with_score.dart';

/// Tab shell for the main app. Navigation between Home / Score / Profile is
/// driven from the drawer (matching the original UX), while the underlying
/// [StatefulNavigationShell] keeps each branch's state alive.
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  double _appBarOpacity = 0.0;
  static const _titles = ['Home', 'Score', 'Profile'];

  void _goToBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user?['user'];
    final profileImg = (user?['profileImg'] ?? '').toString();
    final index = widget.navigationShell.currentIndex;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primaryGradient.colors.first
                    .withOpacity(_appBarOpacity),
                AppColors.primaryGradient.colors.last
                    .withOpacity(_appBarOpacity),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _titles[index],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AvatarWithScore(profileImg: profileImg),
              ),
            ],
          ),
        ),
      ),
      drawer: DrawerLayout(onItemSelected: _goToBranch),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            final offset = notification.metrics.pixels;
            setState(() {
              _appBarOpacity = (offset / 100).clamp(0.0, 1.0);
            });
          }
          return false;
        },
        child: widget.navigationShell,
      ),
    );
  }
}

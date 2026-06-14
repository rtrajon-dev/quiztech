import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quiztech/app/theme/app_colors.dart';
import 'package:quiztech/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:quiztech/features/quiz/presentation/viewmodel/sound_viewmodel.dart';

/// Navigation drawer: switches tabs, toggles sound, and signs out.
class DrawerLayout extends ConsumerWidget {
  final void Function(int) onItemSelected;

  const DrawerLayout({super.key, required this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user?['user'];
    final userName = user?['fullName'] ?? 'user';
    final profileImg = (user?['profileImg'] ?? '').toString();

    final soundOn = ref.watch(soundViewModelProvider);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
                  child: profileImg.isEmpty
                      ? const Icon(Icons.person,
                          size: 34, color: Colors.blueGrey)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello $userName",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _drawerItem(
            icon: Icons.home_outlined,
            title: "Home",
            onTap: () {
              Navigator.pop(context);
              onItemSelected(0);
            },
          ),
          _drawerItem(
            icon: Icons.scoreboard_outlined,
            title: "Score",
            onTap: () {
              Navigator.pop(context);
              onItemSelected(1);
            },
          ),
          _drawerItem(
            icon: Icons.person_outline,
            title: "Profile",
            onTap: () {
              Navigator.pop(context);
              onItemSelected(2);
            },
          ),
          const Divider(),
          SwitchListTile(
            value: soundOn,
            title: const Text("Sound"),
            secondary: const Icon(Icons.volume_up_outlined),
            onChanged: (value) {
              ref.read(soundViewModelProvider.notifier).toggleSound(value);
            },
          ),
          const Divider(),
          _drawerItem(
            icon: Icons.logout,
            title: "Logout",
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authViewModelProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}

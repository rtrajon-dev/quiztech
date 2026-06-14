import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:quiztech/app/theme/app_colors.dart';
import 'package:quiztech/features/auth/presentation/viewmodel/auth_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user?['user'];
    final profileImg = (user?['profileImg'] ?? '').toString();

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No user data found",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 100.h),
              // Header Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60.r,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
                      child: profileImg.isEmpty
                          ? Icon(Icons.person,
                              size: 60.r, color: Colors.blueGrey)
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      user['fullName'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      user['email'] ?? 'N/A',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey[200]),
                    ),
                    SizedBox(height: 25.h),
                  ],
                ),
              ),
              // Info Card
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account Details",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildInfoRow(
                        Icons.person, "Full Name", user['fullName'] ?? 'N/A'),
                    SizedBox(height: 12.h),
                    _buildInfoRow(Icons.email, "Email", user['email'] ?? 'N/A'),
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                        Icons.work_outline, "Role", user['role'] ?? 'N/A'),
                    SizedBox(height: 12.h),
                    _buildInfoRow(Icons.verified_user, "Status",
                        user['status'] ?? 'N/A'),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () =>
                        ref.read(authViewModelProvider.notifier).logout(),
                    label: Text(
                      "Logout",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import 'employee_avatar.dart';

class GreetingHeader extends StatelessWidget {
  final String name;
  final String employeeId;
  final String position;
  final String avatarInitials;
  final String? employeeFileName;
  final bool isDarkMode;

  const GreetingHeader({
    super.key,
    required this.name,
    required this.employeeId,
    required this.position,
    required this.avatarInitials,
    this.employeeFileName,
    this.isDarkMode = false,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return Icons.nightlight_round;
    } else if (hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      return Icons.wb_sunny_rounded;
    } else {
      return Icons.nightlight_round;
    }
  }

  Color _getGreetingIconColor() {
    final hour = DateTime.now().hour;
    if (hour < 6 || hour >= 18) {
      return const Color(0xFF6366F1); // Indigo for night
    } else if (hour < 12) {
      return const Color(0xFFF59E0B); // Amber for morning
    } else {
      return const Color(0xFFEF4444); // Red/Orange for afternoon
    }
  }

  String _getFirstName() {
    final parts = name.split(' ');
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF1E3A5F),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFF0EA5E9),
                  const Color(0xFF0284C7),
                ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with greeting and avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting with icon
                    Row(
                      children: [
                        Icon(
                          _getGreetingIcon(),
                          color: _getGreetingIconColor(),
                          size: 20.sp,
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: 2.seconds,
                              color: Colors.white.withOpacity(0.3),
                            ),
                        SizedBox(width: 8.w),
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // Name
                    Text(
                      _getFirstName(),
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Date
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            today,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: EmployeeAvatar(
                  employeeFileName: employeeFileName,
                  initials: avatarInitials,
                  size: 65.w,
                  fontSize: 24.sp,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Bottom row with position and employee ID
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                // Position
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.work_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Position',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              position,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30.h,
                  color: Colors.white.withOpacity(0.2),
                ),
                SizedBox(width: 12.w),
                // Employee ID
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.badge_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Employee ID',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              employeeId,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

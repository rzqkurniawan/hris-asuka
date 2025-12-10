import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

class QuickStatsRow extends StatelessWidget {
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final int leaveDays;
  final bool isDarkMode;

  const QuickStatsRow({
    super.key,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.leaveDays,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          label: 'Hadir',
          value: presentDays.toString(),
          color: const Color(0xFF10B981),
          delay: 0,
        ),
        SizedBox(width: 10.w),
        _buildStatCard(
          icon: Icons.schedule_rounded,
          label: 'Terlambat',
          value: lateDays.toString(),
          color: const Color(0xFFF59E0B),
          delay: 100,
        ),
        SizedBox(width: 10.w),
        _buildStatCard(
          icon: Icons.cancel_rounded,
          label: 'Absen',
          value: absentDays.toString(),
          color: const Color(0xFFEF4444),
          delay: 200,
        ),
        SizedBox(width: 10.w),
        _buildStatCard(
          icon: Icons.beach_access_rounded,
          label: 'Cuti',
          value: leaveDays.toString(),
          color: const Color(0xFF8B5CF6),
          delay: 300,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay))
          .slideY(begin: 0.3, end: 0),
    );
  }
}

class QuickStatsRowSimple extends StatelessWidget {
  final bool isDarkMode;

  const QuickStatsRowSimple({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // This is a placeholder that shows this month's stats
    // In real implementation, you would fetch this from API
    return const QuickStatsRow(
      presentDays: 18,
      lateDays: 2,
      absentDays: 0,
      leaveDays: 1,
      isDarkMode: false,
    );
  }
}

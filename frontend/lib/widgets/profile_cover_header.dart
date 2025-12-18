import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import 'employee_avatar.dart';

class ProfileCoverHeader extends StatelessWidget {
  final String name;
  final String employeeId;
  final String position;
  final String department;
  final String avatarInitials;
  final String? employeeFileName;
  final String workingPeriod;
  final String investmentAmount;
  final bool isDarkMode;
  final VoidCallback? onSettingsTap;

  const ProfileCoverHeader({
    super.key,
    required this.name,
    required this.employeeId,
    required this.position,
    this.department = '',
    required this.avatarInitials,
    this.employeeFileName,
    required this.workingPeriod,
    required this.investmentAmount,
    required this.isDarkMode,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : const Color(0xFF0C4A6E).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            // Gradient Background / Cover
            Container(
              height: 160.h,
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
                          const Color(0xFF0369A1),
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30.h,
                    right: -30.w,
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40.h,
                    left: -20.w,
                    child: Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20.h,
                    left: 30.w,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Settings Icon
                  if (onSettingsTap != null)
                    Positioned(
                      top: 12.h,
                      right: 12.w,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSettingsTap,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Container(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              margin: EdgeInsets.only(top: 100.h),
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
              child: Column(
                children: [
                  // Name and Position
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    position,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0EA5E9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      employeeId,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Stats Row
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Row(
                          children: [
                            // Working Period
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.work_history_rounded,
                                label: l10n.workingPeriod,
                                value: workingPeriod,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50.h,
                              color: isDarkMode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                            // Investment
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.savings_rounded,
                                label: l10n.investment,
                                value: investmentAmount,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Avatar (positioned in the middle)
            Positioned(
              top: 55.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: EmployeeAvatar(
                    employeeFileName: employeeFileName,
                    initials: avatarInitials,
                    size: 90.w,
                    fontSize: 32.sp,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
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
            fontSize: 14.sp,
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
            fontSize: 11.sp,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

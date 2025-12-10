import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_cover_header.dart';
import '../widgets/profile_menu_list.dart';
import '../constants/app_colors.dart';
import '../utils/page_transitions.dart';
import '../providers/auth_provider.dart';
import 'employee_data_screen.dart';
import 'family_data_screen.dart';
import 'position_history_screen.dart';
import 'training_history_screen.dart';
import 'work_experience_screen.dart';
import 'educational_history_screen.dart';
import 'check_clock_history_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              final name = user?.fullname ?? 'User';
              final employeeId = user?.employeeNumber ?? '---';
              final position = user?.position ?? 'Position';
              final avatarInitials = user?.initials ?? '?';
              final employeeFileName = user?.employeeFileName;

              final workingPeriod = user?.workingPeriod ?? '0Y 0M';
              final investmentAmount = user?.investmentAmount ?? 'Rp 0';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Profile Cover Header
                  ProfileCoverHeader(
                    name: name,
                    employeeId: employeeId,
                    position: position,
                    avatarInitials: avatarInitials,
                    employeeFileName: employeeFileName,
                    workingPeriod: workingPeriod,
                    investmentAmount: investmentAmount,
                    isDarkMode: isDarkMode,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.1, end: 0),

                  SizedBox(height: 24.h),

                  // Section Title
                  _buildSectionTitle(
                    'Menu Profil',
                    Icons.menu_rounded,
                    isDarkMode,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  SizedBox(height: 12.h),

                  // Profile Menu List with animations
                  ProfileMenuList(
                    isDarkMode: isDarkMode,
                    items: [
                      ProfileMenuItem(
                        icon: Icons.access_time_rounded,
                        title: 'Check Clock History',
                        subtitle: 'Attendance records',
                        color: const Color(0xFF0EA5E9),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const CheckClockHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.badge_rounded,
                        title: 'Employee Data',
                        subtitle: 'Personal information',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const EmployeeDataScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.people_rounded,
                        title: 'Family Data',
                        subtitle: 'Family members info',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const FamilyDataScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.trending_up_rounded,
                        title: 'Position History',
                        subtitle: 'Career progression',
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const PositionHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.card_membership_rounded,
                        title: 'Training History',
                        subtitle: 'Certifications & courses',
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const TrainingHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.work_rounded,
                        title: 'Work Experience',
                        subtitle: 'Previous employments',
                        color: const Color(0xFF14B8A6),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const WorkExperienceScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.school_rounded,
                        title: 'Educational History',
                        subtitle: 'Academic background',
                        color: const Color(0xFF6366F1),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const EducationalHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: 110.h), // Space for bottom nav
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF0EA5E9).withOpacity(0.2)
                : const Color(0xFF0EA5E9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0EA5E9),
            size: 18.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

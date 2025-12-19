import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_cover_header.dart';
import '../widgets/profile_menu_list.dart';
import '../constants/app_colors.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive_utils.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
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
    final isTablet = Responsive.isTablet(context);
    // Use fixed pixels for tablet, ScreenUtil for phone
    final horizontalPadding = isTablet
        ? Responsive.getHorizontalPadding(context)
        : 20.w;
    final verticalPadding = isTablet ? 20.0 : 20.h;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final l10n = AppLocalizations.of(context);
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

                  SizedBox(height: isTablet ? 24.0 : 24.h),

                  // Section Title - Profile Menu
                  _buildSectionTitle(
                    l10n.get('profile_menu'),
                    Icons.menu_rounded,
                    isDarkMode,
                    isTablet,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  SizedBox(height: isTablet ? 12.0 : 12.h),

                  // Profile Menu List with animations
                  ProfileMenuList(
                    isDarkMode: isDarkMode,
                    items: [
                      ProfileMenuItem(
                        icon: Icons.access_time_rounded,
                        title: l10n.get('check_clock_history'),
                        subtitle: l10n.get('attendance_records'),
                        color: AppColors.accent,
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
                        title: l10n.personalData,
                        subtitle: l10n.get('personal_info'),
                        color: AppColors.statusWork,
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
                        title: l10n.familyData,
                        subtitle: l10n.get('family_info'),
                        color: AppColors.statusLate,
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
                        title: l10n.positionHistory,
                        subtitle: l10n.get('career_progression'),
                        color: AppColors.statusLeave,
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
                        title: l10n.trainingHistory,
                        subtitle: l10n.get('certifications_courses'),
                        color: AppColors.statusSick,
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
                        title: l10n.workExperience,
                        subtitle: l10n.get('previous_employment'),
                        color: AppColors.teal,
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
                        title: l10n.educationHistory,
                        subtitle: l10n.get('academic_background'),
                        color: AppColors.statusPermission,
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

                  SizedBox(height: isTablet ? 110.0 : 110.h), // Space for bottom nav
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode, bool isTablet) {
    // Use fixed pixels for tablet, ScreenUtil for phone
    final containerPadding = isTablet ? 10.0 : 8.w;
    final borderRadius = isTablet ? 10.0 : 10.r;
    final iconSize = isTablet ? 20.0 : 18.sp;
    final spacingWidth = isTablet ? 10.0 : 10.w;
    final fontSize = isTablet ? 18.0 : 16.sp;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: iconSize,
          ),
        ),
        SizedBox(width: spacingWidth),
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

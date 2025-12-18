import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_cover_header.dart';
import '../widgets/profile_menu_list.dart';
import '../widgets/change_password_bottom_sheet.dart';
import '../constants/app_colors.dart';
import '../utils/page_transitions.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
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

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Consumer3<AuthProvider, LocaleProvider, ThemeProvider>(
            builder: (context, authProvider, localeProvider, themeProvider, child) {
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

                  SizedBox(height: 24.h),

                  // Section Title - Profile Menu
                  _buildSectionTitle(
                    l10n.get('profile_menu'),
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
                      ProfileMenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.changePassword,
                        subtitle: l10n.get('change_password_subtitle'),
                        color: AppColors.error,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showChangePasswordBottomSheet(context);
                        },
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: 24.h),

                  // Section Title - Settings
                  _buildSectionTitle(
                    l10n.settings,
                    Icons.settings_rounded,
                    isDarkMode,
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                  SizedBox(height: 12.h),

                  // Settings Menu
                  ProfileMenuList(
                    isDarkMode: isDarkMode,
                    items: [
                      ProfileMenuItem(
                        icon: Icons.language_rounded,
                        title: l10n.language,
                        subtitle: localeProvider.currentLanguageName,
                        color: AppColors.accent,
                        trailing: _buildLanguageSwitch(context, localeProvider, isDarkMode),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showLanguageDialog(context, localeProvider, isDarkMode);
                        },
                      ),
                      ProfileMenuItem(
                        icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        title: l10n.theme,
                        subtitle: isDarkMode ? l10n.darkMode : l10n.lightMode,
                        color: isDarkMode ? Colors.indigo : Colors.amber,
                        trailing: _buildThemeSwitch(context, themeProvider, isDarkMode),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          themeProvider.toggleTheme();
                        },
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 500.ms)
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
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
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

  Widget _buildLanguageSwitch(BuildContext context, LocaleProvider localeProvider, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localeProvider.isIndonesian ? 'ID' : 'EN',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.arrow_drop_down,
            color: AppColors.accent,
            size: 16.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context, ThemeProvider themeProvider, bool isDarkMode) {
    return Switch(
      value: isDarkMode,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        themeProvider.toggleTheme();
      },
      activeColor: AppColors.accent,
      activeTrackColor: AppColors.accent.withOpacity(0.3),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider, bool isDarkMode) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.language_rounded,
              color: AppColors.accent,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              l10n.language,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleProvider.supportedLocales.map((locale) {
            final isSelected = localeProvider.locale.languageCode == locale.languageCode;
            final languageName = LocaleProvider.languageNames[locale.languageCode] ?? locale.languageCode;

            return ListTile(
              onTap: () {
                HapticFeedback.lightImpact();
                localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.2)
                      : (isDarkMode ? AppColors.overlayDark : AppColors.overlayLight),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    locale.languageCode.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.accent : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ),
              title: Text(
                languageName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.accent
                      : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: AppColors.accent, size: 20.sp)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              tileColor: isSelected
                  ? AppColors.accent.withOpacity(0.1)
                  : Colors.transparent,
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/greeting_header.dart';
import '../widgets/attendance_status_box.dart';
import '../widgets/menu_grid.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/custom_dialog.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive_utils.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';
import 'overtime_list_screen.dart';
import 'employee_leave_list_screen.dart';
import 'pay_slip_screen.dart';
import 'attendance_summary_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AttendanceService _attendanceService = AttendanceService();
  MonthlySummary? _monthlySummary;
  bool _isLoadingStats = true;
  String? _statsError;
  String _statsMonthName = '';

  @override
  void initState() {
    super.initState();
    _loadMonthlyStats();
  }

  Future<void> _loadMonthlyStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      // Use previous month's data since current month data is still being updated
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      final summary = await _attendanceService.getAttendanceSummary(
        month: previousMonth.month,
        year: previousMonth.year,
      );

      if (mounted) {
        setState(() {
          _monthlySummary = summary;
          _statsMonthName = summary.monthName;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsError = e.toString();
          _isLoadingStats = false;
        });
      }
    }
  }

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
              final user = authProvider.user;
              final name = user?.fullname ?? 'User';
              final employeeId = user?.employeeNumber ?? '---';
              final position = user?.position ?? 'Position';
              final avatarInitials = user?.initials ?? '?';
              final employeeFileName = user?.employeeFileName;

              final l10n = AppLocalizations.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Greeting Header with animation
                  GreetingHeader(
                    name: name,
                    employeeId: employeeId,
                    position: position,
                    avatarInitials: avatarInitials,
                    employeeFileName: employeeFileName,
                    isDarkMode: isDarkMode,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.2, end: 0),

                  SizedBox(height: 20.h),

                  // Section Title - Quick Stats (Previous Month)
                  _buildSectionTitle(
                    _statsMonthName.isNotEmpty
                        ? l10n.get('statistics_month').replaceAll('{month}', _statsMonthName)
                        : l10n.get('last_month_statistics'),
                    Icons.bar_chart_rounded,
                    isDarkMode,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  SizedBox(height: 12.h),

                  // Quick Stats Row
                  _buildQuickStats(isDarkMode, l10n),

                  SizedBox(height: 24.h),

                  // Section Title - Today's Attendance
                  _buildSectionTitle(
                    l10n.todayAttendance,
                    Icons.access_time_rounded,
                    isDarkMode,
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                  SizedBox(height: 12.h),

                  // Attendance Status Box with integrated Check In/Out buttons
                  AttendanceStatusBox(
                    isDarkMode: isDarkMode,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 500.ms)
                      .slideX(begin: 0.1, end: 0),

                  SizedBox(height: 24.h),

                  // Section Title - Quick Access
                  _buildSectionTitle(
                    l10n.get('main_menu'),
                    Icons.apps_rounded,
                    isDarkMode,
                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

                  SizedBox(height: 12.h),

                  // Enhanced Menu Grid with animations
                  MenuGrid(
                    items: [
                      MenuGridItem(
                        icon: Icons.access_time_filled,
                        label: l10n.get('overtime_orders'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const OvertimeListScreen(),
                            ),
                          );
                        },
                      ),
                      MenuGridItem(
                        icon: Icons.beach_access,
                        label: l10n.get('employee_leave'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const EmployeeLeaveListScreen(),
                            ),
                          );
                        },
                      ),
                      MenuGridItem(
                        icon: Icons.receipt_long,
                        label: l10n.get('pay_slip_menu'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const PaySlipScreen(),
                            ),
                          );
                        },
                      ),
                      MenuGridItem(
                        icon: Icons.assignment_turned_in,
                        label: l10n.get('attendance_history_menu'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            SlideRightRoute(
                              page: const AttendanceSummaryPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 700.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: isTablet ? 100.0 : 100.h), // Space for bottom nav
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode) {
    final isTablet = Responsive.isTablet(context);
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

  Widget _buildQuickStats(bool isDarkMode, AppLocalizations l10n) {
    if (_isLoadingStats) {
      return Container(
        height: 100.h,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: SizedBox(
            width: 24.w,
            height: 24.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    }

    if (_statsError != null || _monthlySummary == null) {
      return GestureDetector(
        onTap: _loadMonthlyStats,
        child: Container(
          height: 100.h,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.statusAbsent.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: AppColors.statusAbsent,
                  size: 24.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.get('tap_to_retry'),
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return QuickStatsRow(
      presentDays: _monthlySummary!.masuk,
      lateDays: _monthlySummary!.terlambat,
      absentDays: _monthlySummary!.alpha,
      leaveDays: _monthlySummary!.cuti,
      isDarkMode: isDarkMode,
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    CustomDialog.show(
      context: context,
      title: l10n.get('coming_soon'),
      message: l10n.get('feature_coming_soon').replaceAll('{feature}', feature),
    );
  }
}

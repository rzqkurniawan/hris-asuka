import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../widgets/greeting_header.dart';
import '../widgets/attendance_status_box.dart';
import '../widgets/menu_grid.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/custom_dialog.dart';
import '../utils/page_transitions.dart';
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
                        ? 'Statistik $_statsMonthName'
                        : 'Statistik Bulan Lalu',
                    Icons.bar_chart_rounded,
                    isDarkMode,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  SizedBox(height: 12.h),

                  // Quick Stats Row
                  _buildQuickStats(isDarkMode),

                  SizedBox(height: 24.h),

                  // Section Title - Today's Attendance
                  _buildSectionTitle(
                    'Absensi Hari Ini',
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
                    'Menu Utama',
                    Icons.apps_rounded,
                    isDarkMode,
                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

                  SizedBox(height: 12.h),

                  // Enhanced Menu Grid with animations
                  MenuGrid(
                    items: [
                      MenuGridItem(
                        icon: Icons.access_time_filled,
                        label: 'Overtime\nOrders',
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
                        label: 'Employee\nLeave',
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
                        label: 'Pay\nSlip',
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
                        label: 'Attendance\nHistory',
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

                  SizedBox(height: 100.h), // Space for bottom nav
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

  Widget _buildQuickStats(bool isDarkMode) {
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF0EA5E9),
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
              color: const Color(0xFFEF4444).withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: const Color(0xFFEF4444),
                  size: 24.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tap to retry',
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
    HapticFeedback.lightImpact();
    CustomDialog.show(
      context: context,
      title: 'Coming Soon',
      message: '$feature feature will be available soon!',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../widgets/profile_header.dart';
import '../widgets/attendance_status_box.dart';
import '../widgets/menu_grid.dart';
import '../widgets/custom_dialog.dart';
import '../utils/page_transitions.dart';
import '../providers/auth_provider.dart';
import 'overtime_list_screen.dart';
import 'employee_leave_list_screen.dart';
import 'pay_slip_screen.dart';
import 'attendance_summary_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                  // Profile Header
                  ProfileHeader(
                    name: name,
                    employeeId: employeeId,
                    position: position,
                    avatarInitials: avatarInitials,
                    employeeFileName: employeeFileName,
                    isDarkMode: isDarkMode,
                  ),
              const SizedBox(height: 20),

              // Attendance Status Box
              AttendanceStatusBox(
                checkInTime: '08:00 AM',
                checkOutTime: '17:00 PM',
                status: AttendanceStatus.work,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 20),

              // Menu Grid
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
                      // Navigate to Pay Slip Screen
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
                    label: 'Attendance',
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
              ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              );
            },
          ),
        ),
      ),
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

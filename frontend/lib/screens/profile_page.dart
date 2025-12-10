import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/investment_box.dart';
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
          padding: const EdgeInsets.all(20),
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

                  // Investment Box
                  InvestmentBox(
                    workingPeriod: workingPeriod,
                    investmentAmount: investmentAmount,
                    isDarkMode: isDarkMode,
                  ),
              const SizedBox(height: 20),

              // Profile Menu List
              ProfileMenuList(
                isDarkMode: isDarkMode,
                items: [
                  ProfileMenuItem(
                    icon: Icons.badge,
                    title: 'Employee Data',
                    subtitle: 'Personal information',
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
                    icon: Icons.people,
                    title: 'Family Data',
                    subtitle: 'Family members info',
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
                    icon: Icons.work_history,
                    title: 'Position History',
                    subtitle: 'Career progression',
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
                    icon: Icons.card_membership,
                    title: 'Training History',
                    subtitle: 'Certifications & courses',
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
                    icon: Icons.work,
                    title: 'Work Experience',
                    subtitle: 'Previous employments',
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
                    icon: Icons.school,
                    title: 'Educational History',
                    subtitle: 'Academic background',
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
}

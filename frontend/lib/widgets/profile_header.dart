import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'employee_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String employeeId;
  final String position;
  final String avatarInitials;
  final String? employeeFileName;
  final bool isDarkMode;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.employeeId,
    required this.position,
    required this.avatarInitials,
    this.employeeFileName,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with photo or initials fallback
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryLight.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: EmployeeAvatar(
              employeeFileName: employeeFileName,
              initials: avatarInitials,
              size: 70.0,
              fontSize: 28.0,
              gradient: AppColors.secondaryGradientLight,
            ),
          ),
          const SizedBox(width: 15),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  employeeId,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  position,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryLight,
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee_leave_model.dart';
import '../constants/app_colors.dart';

class EmployeeLeaveCard extends StatelessWidget {
  final EmployeeLeave leave;
  final VoidCallback onTap;

  const EmployeeLeaveCard({
    super.key,
    required this.leave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd-MM-yyyy');

    // Determine style based on status
    final isPending = !leave.isApproved &&
        !(leave.status.toLowerCase().contains('reject') ||
            leave.status.toLowerCase().contains('tolak'));
    final isRejected = !leave.isApproved && !isPending;

    final badgeGradient = leave.isApproved
        ? AppColors.statusWorkGradient
        : isRejected
            ? AppColors.statusAbsentGradient
            : AppColors.statusLateGradient;

    final badgeIcon = leave.isApproved
        ? Icons.check_circle
        : isRejected
            ? Icons.cancel
            : Icons.access_time;

    final badgeText = leave.statusText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(
            left: BorderSide(
              color: leave.isApproved
                  ? AppColors.statusWork
                  : isRejected
                      ? AppColors.statusAbsent
                      : AppColors.statusLate,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Leave Number + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    leave.employeeLeaveNumber.isNotEmpty
                        ? leave.employeeLeaveNumber
                        : 'No Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: badgeGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        badgeIcon,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        leave.statusText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Leave Period
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${leave.dateBeginFormatted} - ${leave.dateEndFormatted}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Leave Category
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 14,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    leave.leaveCategoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Footer: Duration + View Details
            Container(
              padding: const EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color:
                        isDarkMode ? AppColors.surfaceDark : AppColors.mutedLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isDarkMode
                            ? AppColors.secondaryDark
                            : AppColors.secondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${leave.durationDays} Days',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.secondaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

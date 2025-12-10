import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

enum AttendanceStatus { work, late, absent, leave }

class AttendanceStatusBox extends StatelessWidget {
  final String checkInTime;
  final String checkOutTime;
  final AttendanceStatus status;
  final bool isDarkMode;

  const AttendanceStatusBox({
    super.key,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Attendance Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Time Grid
          Row(
            children: [
              Expanded(
                child: _buildTimeItem(
                  label: 'Check In',
                  time: checkInTime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeItem(
                  label: 'Check Out',
                  time: checkOutTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Status Badge
          _buildStatusBadge(),

          // Today Date
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 5),
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem({required String label, required String time}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            color: AppColors.secondaryLight,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    LinearGradient gradient;
    String statusText;
    String icon;

    switch (status) {
      case AttendanceStatus.work:
        gradient = AppColors.statusWorkGradient;
        statusText = 'WORK';
        icon = '✓';
        break;
      case AttendanceStatus.late:
        gradient = AppColors.statusLateGradient;
        statusText = 'LATE';
        icon = '⚠';
        break;
      case AttendanceStatus.absent:
        gradient = AppColors.statusAbsentGradient;
        statusText = 'ABSENT';
        icon = '✗';
        break;
      case AttendanceStatus.leave:
        gradient = AppColors.statusLeaveGradient;
        statusText = 'LEAVE';
        icon = '📅';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$icon $statusText',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/overtime_order.dart';
import '../constants/app_colors.dart';

class OvertimeOrderCard extends StatelessWidget {
  final OvertimeOrder order;
  final VoidCallback onTap;

  const OvertimeOrderCard({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusConfig = _StatusConfig.fromOrder(order);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: statusConfig.borderColor,
              width: 4,
            ),
          ),
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
            // Header: Order Number + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: statusConfig.badgeGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusConfig.icon,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.statusText,
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

            // Proposed Date
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
                Text(
                  'Proposed: ${DateFormat('MMM dd, yyyy').format(order.proposedDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Approval Status
            _buildApprovalRow(
              context,
              icon: order.approval1Name != null ? Icons.check_circle : Icons.remove_circle_outline,
              text: 'Approval 1: ${order.approval1Name ?? '-'}',
              isApproved: order.approval1Name != null,
            ),

            const SizedBox(height: 8),

            _buildApprovalRow(
              context,
              icon: order.approval2Name != null ? Icons.check_circle : Icons.remove_circle_outline,
              text: 'Approval 2: ${order.approval2Name ?? '-'}',
              isApproved: order.approval2Name != null,
            ),

            const SizedBox(height: 8),

            _buildApprovalRow(
              context,
              icon: order.verifiedBy != null ? Icons.check_circle : Icons.remove_circle_outline,
              text: order.verifiedBy != null
                  ? 'Verified By: ${order.verifiedBy}'
                  : 'Verified By: -',
              isApproved: order.verifiedBy != null,
            ),

            const SizedBox(height: 15),

            // Footer: Employee Count + View Details
            Container(
              padding: const EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDarkMode
                        ? AppColors.surfaceDark
                        : AppColors.mutedLight,
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
                        Icons.people,
                        size: 16,
                        color: AppColors.secondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${order.employeeCount} Employees',
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
                      const SizedBox(width: 4),
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

  Widget _buildApprovalRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool isApproved,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isApproved ? AppColors.statusWork : AppColors.statusAbsent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusConfig {
  final LinearGradient badgeGradient;
  final Color borderColor;
  final IconData icon;

  const _StatusConfig({
    required this.badgeGradient,
    required this.borderColor,
    required this.icon,
  });

  factory _StatusConfig.fromOrder(OvertimeOrder order) {
    if (order.isApproved) {
      return const _StatusConfig(
        badgeGradient: AppColors.statusWorkGradient,
        borderColor: AppColors.statusWork,
        icon: Icons.check_circle,
      );
    }

    if (order.isRejected) {
      return const _StatusConfig(
        badgeGradient: AppColors.statusAbsentGradient,
        borderColor: AppColors.statusAbsent,
        icon: Icons.cancel,
      );
    }

    return const _StatusConfig(
      badgeGradient: AppColors.statusLateGradient,
      borderColor: AppColors.statusLate,
      icon: Icons.access_time,
    );
  }
}

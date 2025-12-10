import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/overtime_order.dart';
import '../constants/app_colors.dart';

class ApprovalTimeline extends StatelessWidget {
  final OvertimeOrder order;

  const ApprovalTimeline({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.statusWork,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Approval Status',
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

          const SizedBox(height: 20),

          // Timeline Items
          _buildTimelineItem(
            title: 'Approval 1',
            isApproved: order.approval1Name != null,
            approverName: order.approval1Name,
            date: order.approval1Date,
            isLast: false,
            isDarkMode: isDarkMode,
          ),

          _buildTimelineItem(
            title: 'Approval 2',
            isApproved: order.approval2Approved,
            approverName: order.approval2Name,
            date: order.approval2Date,
            isLast: false,
            isDarkMode: isDarkMode,
          ),

          _buildTimelineItem(
            title: 'Verified',
            isApproved: order.verifiedBy != null,
            approverName: order.verifiedBy,
            date: order.verifiedDate,
            isLast: true,
            isDarkMode: isDarkMode,
            highlightLabel: 'Verified by',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required bool isApproved,
    String? approverName,
    DateTime? date,
    required bool isLast,
    required bool isDarkMode,
    String? highlightLabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Indicator
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color:
                    isApproved ? AppColors.statusWork : AppColors.statusAbsent,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color:
                    isDarkMode ? AppColors.surfaceDark : AppColors.mutedLight,
              ),
          ],
        ),

        const SizedBox(width: 15),

        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                if (isApproved && approverName != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.statusWork,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${highlightLabel ?? 'Approved by'} $approverName',
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
                  if (date != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? AppColors.textSecondaryDark.withOpacity(0.7)
                            : AppColors.textSecondaryLight.withOpacity(0.7),
                      ),
                    ),
                  ],
                ] else if (!isApproved && approverName == null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.statusAbsent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          title == 'Verified'
                              ? 'Not verified'
                              : 'Not approved',
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
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

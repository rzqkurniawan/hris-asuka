import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class InvestmentBox extends StatelessWidget {
  final String workingPeriod;
  final String investmentAmount;
  final bool isDarkMode;

  const InvestmentBox({
    super.key,
    required this.workingPeriod,
    required this.investmentAmount,
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
          Expanded(
            child: _buildInvestmentItem(
              label: 'Working Period',
              value: workingPeriod,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildInvestmentItem(
              label: 'Investment Box',
              value: investmentAmount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentItem({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(15),
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
            value,
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
    );
  }
}

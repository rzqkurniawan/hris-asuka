import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/position_history_model.dart';
import '../services/position_history_service.dart';

class PositionHistoryScreen extends StatefulWidget {
  const PositionHistoryScreen({super.key});

  @override
  State<PositionHistoryScreen> createState() => _PositionHistoryScreenState();
}

class _PositionHistoryScreenState extends State<PositionHistoryScreen> {
  final PositionHistoryService _positionHistoryService = PositionHistoryService();
  PositionHistoryModel? _positionHistory;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPositionHistory();
  }

  Future<void> _loadPositionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _positionHistoryService.getPositionHistory();
      setState(() {
        _positionHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        title: Text(
          'Position History',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkMode
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load position history',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadPositionHistory,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // History Card
                      _buildHistoryCard(isDarkMode),
                      const SizedBox(height: 16),

                      // Contract History Table
                      _buildContractTableCard(
                          _positionHistory!.contractHistory, isDarkMode),
                      const SizedBox(height: 16),

                      // Remarks Card
                      _buildRemarksCard(_positionHistory!.remarks, isDarkMode),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primaryDark
                  : AppColors.secondaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Work History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHistoryRow(
                  Icons.play_arrow,
                  'Start of Work',
                  _positionHistory!.workHistory.startOfWork,
                  isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildHistoryRow(
                  Icons.star,
                  'Appointed',
                  _positionHistory!.workHistory.appointed,
                  isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildHistoryRow(
                  Icons.event,
                  'End of Work',
                  _positionHistory!.workHistory.endOfWork,
                  isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildHistoryRow(
                  Icons.exit_to_app,
                  'Leaving',
                  _positionHistory!.workHistory.leaving,
                  isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildHistoryRow(
                  Icons.info_outline,
                  'Reasons for Leaving',
                  _positionHistory!.workHistory.reasonForLeaving,
                  isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(
    IconData icon,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.surfaceAltDark.withOpacity(0.5)
                : AppColors.mutedLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDarkMode
                ? AppColors.primaryDark
                : AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContractTableCard(
      List<ContractHistory> contracts, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primaryDark
                  : AppColors.secondaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.table_chart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Contract History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildContractTable(contracts, isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractTable(
      List<ContractHistory> contracts, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode
              ? AppColors.surfaceAltDark
              : AppColors.mutedLight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.surfaceAltDark
                  : AppColors.primaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('No.', 40, isDarkMode),
                _buildTableHeaderCell('Description', 120, isDarkMode),
                _buildTableHeaderCell('Employee Grade', 140, isDarkMode),
                _buildTableHeaderCell('In', 90, isDarkMode),
                _buildTableHeaderCell('Out', 90, isDarkMode),
              ],
            ),
          ),
          // Table Rows
          ...contracts.asMap().entries.map((entry) {
            final index = entry.key;
            final contract = entry.value;
            final isLast = index == contracts.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: index % 2 == 0
                    ? (isDarkMode
                        ? AppColors.surfaceAltDark.withOpacity(0.2)
                        : Colors.transparent)
                    : Colors.transparent,
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(
                          color: isDarkMode
                              ? AppColors.surfaceAltDark
                              : AppColors.mutedLight,
                        ),
                ),
              ),
              child: Row(
                children: [
                  _buildTableCell(
                    contract.no.toString(),
                    40,
                    isDarkMode,
                    isNumber: true,
                  ),
                  _buildTableCell(
                    contract.description,
                    120,
                    isDarkMode,
                  ),
                  _buildTableCell(
                    contract.grade,
                    140,
                    isDarkMode,
                  ),
                  _buildTableCell(
                    contract.inDate,
                    90,
                    isDarkMode,
                  ),
                  _buildTableCell(
                    contract.outDate,
                    90,
                    isDarkMode,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, double width, bool isDarkMode) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text,
    double width,
    bool isDarkMode, {
    bool isNumber = false,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isNumber ? FontWeight.w600 : FontWeight.normal,
          color: isDarkMode
              ? (isNumber
                  ? AppColors.primaryDark
                  : AppColors.textPrimaryDark)
              : (isNumber
                  ? AppColors.primaryLight
                  : AppColors.textPrimaryLight),
        ),
      ),
    );
  }

  Widget _buildRemarksCard(Remarks remarks, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primaryDark
                  : AppColors.secondaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notes,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.surfaceAltDark.withOpacity(0.5)
                            : AppColors.mutedLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.attach_money,
                        size: 18,
                        color: isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salary',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remarks.salary,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.surfaceAltDark.withOpacity(0.3)
                        : AppColors.mutedLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remarks.notes,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/employee_overtime_detail.dart';
import '../models/overtime_order.dart';
import '../services/overtime_service.dart';
import '../widgets/approval_timeline.dart';
import '../widgets/employee_overtime_card.dart';
import '../widgets/shimmer_skeleton.dart';
import 'employee_overtime_detail_screen.dart';

class OvertimeDetailScreen extends StatefulWidget {
  final OvertimeOrder order;

  const OvertimeDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OvertimeDetailScreen> createState() => _OvertimeDetailScreenState();
}

class _OvertimeDetailScreenState extends State<OvertimeDetailScreen> {
  final OvertimeService _overtimeService = OvertimeService();
  late OvertimeOrder _order;
  List<EmployeeOvertimeDetail> _employees = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    if (_order.id == null) {
      setState(() {
        _employees = EmployeeOvertimeDetail.getEmployeesForOrder(
          _order.orderNumber,
        );
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _overtimeService.getOvertimeDetail(
        _order.id!,
      );
      setState(() {
        _order = response.overtime;
        _employees = response.employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load employee details: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadEmployees,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget bodyContent;
    if (_isLoading) {
      bodyContent = _buildLoadingState(context);
    } else if (_errorMessage != null) {
      bodyContent = _buildErrorState(context);
    } else {
      bodyContent = _buildDetailContent(context, isDarkMode);
    }

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        title: Text(
          'Overtime Order Detail',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildDetailContent(BuildContext context, bool isDarkMode) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHero(isDarkMode),
          const SizedBox(height: 20),
          _buildOrderInformationCard(context, isDarkMode, dateFormat),
          const SizedBox(height: 20),
          ApprovalTimeline(order: _order),
          const SizedBox(height: 20),
          _buildEmployeesCard(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatusHero(bool isDarkMode) {
    final statusDisplay = _statusDisplayData();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: statusDisplay.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _order.orderNumber,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusDisplay.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _order.statusText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInformationCard(
    BuildContext context,
    bool isDarkMode,
    DateFormat dateFormat,
  ) {
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
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.secondaryLight,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Order Information',
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
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Job Code',
                  value: _order.jobCode,
                  context: context,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildInfoItem(
                  label: 'Work Location',
                  value: _order.workLocation,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Department',
                  value: _order.department,
                  context: context,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildInfoItem(
                  label: 'Proposed Date',
                  value: dateFormat.format(_order.proposedDate),
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoItem(
            label: 'Requested By',
            value: _order.requestedBy.isEmpty ? '-' : _order.requestedBy,
            context: context,
          ),
          const SizedBox(height: 15),
          _buildInfoItem(
            label: 'Work Description',
            value: _order.workDescription,
            isMultiline: true,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesCard(bool isDarkMode) {
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
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppColors.secondaryLight,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Assigned Employees (${_employees.length})',
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
          if (_employees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No employees found',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _employees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final employee = _employees[index];
                return EmployeeOvertimeCard(
                  employee: employee,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeOvertimeDetailScreen(
                          employee: employee,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isMultiline ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            height: isMultiline ? 1.5 : 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ShimmerSkeleton.rectangular(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          SizedBox(height: 20),
          ShimmerSkeleton.rectangular(
            width: double.infinity,
            height: 300,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          SizedBox(height: 20),
          ShimmerSkeleton.rectangular(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          SizedBox(height: 20),
          ShimmerSkeleton.rectangular(
            width: double.infinity,
            height: 250,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.error_outline,
              size: 80,
              color: isDarkMode
                  ? AppColors.textSecondaryDark.withOpacity(0.5)
                  : AppColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadEmployees,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusDisplayData _statusDisplayData() {
    if (_order.isApproved) {
      return const _StatusDisplayData(
        gradient: AppColors.statusWorkGradient,
        icon: Icons.check_circle,
      );
    }

    if (_order.isRejected) {
      return const _StatusDisplayData(
        gradient: AppColors.statusAbsentGradient,
        icon: Icons.cancel,
      );
    }

    return const _StatusDisplayData(
      gradient: AppColors.statusLateGradient,
      icon: Icons.access_time,
    );
  }
}

class _StatusDisplayData {
  final LinearGradient gradient;
  final IconData icon;

  const _StatusDisplayData({
    required this.gradient,
    required this.icon,
  });
}

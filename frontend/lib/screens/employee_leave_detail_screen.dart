import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/employee_leave_model.dart';
import '../services/employee_leave_service.dart';
import '../constants/app_colors.dart';
import '../utils/toast_utils.dart';
import '../utils/page_transitions.dart';
import 'employee_leave_form_screen.dart';

class EmployeeLeaveDetailScreen extends StatefulWidget {
  final EmployeeLeave leave;

  const EmployeeLeaveDetailScreen({
    super.key,
    required this.leave,
  });

  @override
  State<EmployeeLeaveDetailScreen> createState() =>
      _EmployeeLeaveDetailScreenState();
}

class _EmployeeLeaveDetailScreenState extends State<EmployeeLeaveDetailScreen> {
  final EmployeeLeaveService _leaveService = EmployeeLeaveService();
  late EmployeeLeave _leave;
  bool _isDeleting = false;
  bool _isRefreshing = false;
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _leave = widget.leave;
    // Fetch latest detail (includes substitute info) on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshLeaveDetail();
    });
  }

  Future<void> _refreshLeaveDetail() async {
    setState(() => _isRefreshing = true);

    try {
      final refreshedLeave =
          await _leaveService.getEmployeeLeaveDetail(_leave.employeeLeaveId);
      if (mounted) {
        setState(() {
          _leave = refreshedLeave;
          _hasUpdated = true;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ToastUtils.showError(context, 'Failed to refresh leave detail');
      }
    }
  }

  Future<bool> _handleBack() async {
    Navigator.pop(context, _hasUpdated);
    return false;
  }

  Future<void> _editLeave() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
      context,
      SlideRightRoute(
        page: EmployeeLeaveFormScreen(leave: _leave),
      ),
    );

    // Refresh detail instead of popping; avoids navigator lock and shows updated data
    if (result == true && mounted) {
      _hasUpdated = true;
      await _refreshLeaveDetail();
    }
  }

  Future<void> _deleteLeave() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode
              ? AppColors.surfaceAltDark
              : AppColors.surfaceLight,
          title: Text(
            'Delete Leave Request',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this leave request? This action cannot be undone.',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: isDarkMode
                      ? AppColors.dangerDark
                      : AppColors.dangerLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _leaveService.deleteEmployeeLeave(_leave.employeeLeaveId);
      if (mounted) {
        HapticFeedback.lightImpact();
        ToastUtils.showSuccess(context, 'Leave request deleted successfully');
        _hasUpdated = true;
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        if (mounted) {
          ToastUtils.showError(context, 'Failed to delete leave request');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Check if leave can be edited/deleted (not approved)
    final canModify = !_leave.isApproved;
    final isPending = !_leave.isApproved &&
        !(_leave.status.toLowerCase().contains('reject') ||
            _leave.status.toLowerCase().contains('tolak'));

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              _handleBack();
            },
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          title: Text(
            'Leave Detail',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: canModify
              ? [
                  if (_isRefreshing)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    if (!_isDeleting)
                      IconButton(
                        onPressed: _editLeave,
                        icon: Icon(
                          Icons.edit,
                          color: isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                        tooltip: 'Edit Leave',
                      ),
                    if (_isDeleting)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: _deleteLeave,
                        icon: Icon(
                          Icons.delete,
                          color: isDarkMode
                              ? AppColors.dangerDark
                              : AppColors.dangerLight,
                        ),
                        tooltip: 'Delete Leave',
                      ),
                  ],
                ]
              : null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Status Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: _leave.isApproved
                      ? AppColors.statusWorkGradient
                      : isPending
                          ? AppColors.statusLateGradient
                          : AppColors.statusAbsentGradient,
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
                      _leave.employeeLeaveNumber.isNotEmpty
                          ? _leave.employeeLeaveNumber
                          : 'No Number',
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
                          _leave.isApproved ? Icons.check_circle : Icons.pending,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _leave.statusText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Leave Details Card
              _buildSectionCard(
                isDarkMode: isDarkMode,
                title: 'Leave Information',
                icon: Icons.info_outline,
                children: [
                  _buildDetailRow(
                    context,
                    label: 'Leave Category',
                    value: _leave.leaveCategoryName,
                    icon: Icons.category,
                  ),
                  if (_leave.substituteEmployee != null)
                    _buildDetailRow(
                      context,
                      label: 'Employee Substitute',
                      value: _leave.substituteEmployee!.fullname,
                      icon: Icons.person_outline,
                    ),
                  _buildDetailRow(
                    context,
                    label: 'Symbol',
                    value: _leave.reportSymbol,
                    icon: Icons.label,
                  ),
                  _buildDetailRow(
                    context,
                    label: 'Start Date',
                    value: _leave.dateBeginFormatted,
                    icon: Icons.play_arrow,
                  ),
                  _buildDetailRow(
                    context,
                    label: 'End Date',
                    value: _leave.dateEndFormatted,
                    icon: Icons.stop,
                  ),
                  _buildDetailRow(
                    context,
                    label: 'Duration',
                    value: '${_leave.durationDays} days',
                    icon: Icons.access_time,
                    valueColor: AppColors.secondaryLight,
                  ),
                  _buildDetailRow(
                    context,
                    label: 'Remaining Leave',
                    value: '${_leave.sisaCuti} days',
                    icon: Icons.event_available,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Contact Information
              if (_leave.addressLeave != null || _leave.phoneLeave != null)
                _buildSectionCard(
                  isDarkMode: isDarkMode,
                  title: 'Contact During Leave',
                  icon: Icons.contact_phone,
                  children: [
                    if (_leave.addressLeave != null)
                      _buildDetailRow(
                        context,
                        label: 'Address',
                        value: _leave.addressLeave!,
                        icon: Icons.location_on,
                      ),
                    if (_leave.phoneLeave != null)
                      _buildDetailRow(
                        context,
                        label: 'Phone',
                        value: _leave.phoneLeave!,
                        icon: Icons.phone,
                      ),
                  ],
                ),

              const SizedBox(height: 20),

              // Approval Info Card
              if (_leave.isApproved && _leave.approvedDate != null)
                _buildSectionCard(
                  isDarkMode: isDarkMode,
                  title: 'Approval Information',
                  icon: Icons.verified_user,
                  children: [
                    _buildDetailRow(
                      context,
                      label: 'Approved Date',
                      value: dateFormat.format(_leave.approvedDate!),
                      icon: Icons.calendar_today,
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Notes Card
              if (_leave.notes.isNotEmpty && _leave.notes != '-')
                _buildSectionCard(
                  isDarkMode: isDarkMode,
                  title: 'Notes',
                  icon: Icons.notes,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.backgroundDark.withOpacity(0.5)
                            : AppColors.mutedLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? AppColors.surfaceAltDark
                              : AppColors.mutedLight,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _leave.notes,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Created Date
              if (_leave.createdDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      "Created on ${DateFormat('dd/MM/yyyy HH:mm').format(_leave.createdDate!)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDarkMode,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
                icon,
                color: AppColors.secondaryLight,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                title,
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode
                ? AppColors.secondaryDark.withOpacity(0.7)
                : AppColors.secondaryLight.withOpacity(0.7),
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
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ??
                        (isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
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

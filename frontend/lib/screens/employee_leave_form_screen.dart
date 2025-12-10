import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/employee_leave_model.dart';
import '../services/employee_leave_service.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../utils/toast_utils.dart';

class EmployeeLeaveFormScreen extends StatefulWidget {
  final EmployeeLeave? leave; // Optional: if provided, edit mode

  const EmployeeLeaveFormScreen({super.key, this.leave});

  @override
  State<EmployeeLeaveFormScreen> createState() =>
      _EmployeeLeaveFormScreenState();
}

class _EmployeeLeaveFormScreenState extends State<EmployeeLeaveFormScreen> {
  final EmployeeLeaveService _leaveService = EmployeeLeaveService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  List<LeaveCategory> _categories = [];
  List<Employee> _employees = [];
  LeaveCategory? _selectedCategory;
  Employee? _selectedSubstitute;
  DateTime? _proposedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _workDate;
  String _currentEmployeeName = '';

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load categories and employees in parallel
      final results = await Future.wait([
        _leaveService.getLeaveCategories(),
        _leaveService.getActiveEmployees(),
      ]);

      // Get current user info
      final user = await _authService.getCurrentUser();

      if (mounted) {
        setState(() {
          _categories = results[0] as List<LeaveCategory>;
          _employees = results[1] as List<Employee>;
          _currentEmployeeName = user.fullname;

          // Pre-fill form if edit mode
          if (widget.leave != null) {
            final leave = widget.leave!;

            // Find and set category
            _selectedCategory = _categories.firstWhere(
              (cat) => cat.leaveCategoryId == leave.leaveCategoryId,
              orElse: () => _categories.first,
            );

            // Set dates (edit mode only needs dateBegin and dateEnd)
            _startDate = leave.dateBegin;
            _endDate = leave.dateEnd;
            // Note: proposed_date and work_date are not editable, leave as null

            // Set text fields
            if (leave.addressLeave != null && leave.addressLeave!.isNotEmpty) {
              _addressController.text = leave.addressLeave!;
            }
            if (leave.phoneLeave != null && leave.phoneLeave!.isNotEmpty) {
              _phoneController.text = leave.phoneLeave!;
            }
            if (leave.notes != null && leave.notes!.isNotEmpty) {
              _notesController.text = leave.notes!;
            }

            // Note: Substitute employee will be set after employees list is loaded
            // We'll handle this in a separate check below
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('ERROR in _loadInitialData: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        ToastUtils.showError(
          context,
          'Failed to load form data: ${e.toString()}',
        );
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context, {
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final effectiveFirstDate = firstDate ?? DateTime.now();
    DateTime effectiveLastDate = lastDate ?? DateTime(2030);

    if (effectiveLastDate.isBefore(effectiveFirstDate)) {
      effectiveLastDate = effectiveFirstDate;
    }

    DateTime effectiveInitialDate = initialDate ?? DateTime.now();

    if (effectiveInitialDate.isBefore(effectiveFirstDate)) {
      effectiveInitialDate = effectiveFirstDate;
    } else if (effectiveInitialDate.isAfter(effectiveLastDate)) {
      effectiveInitialDate = effectiveLastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
      builder: (context, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
              onPrimary: Colors.white,
              surface:
                  isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
              onSurface: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    if (_selectedCategory == null) {
      ToastUtils.showError(context, 'Please select leave category');
      HapticFeedback.mediumImpact();
      return;
    }

    // Check required dates (edit mode doesn't need proposed_date and work_date)
    final bool isEditMode = widget.leave != null;
    if (_startDate == null || _endDate == null) {
      ToastUtils.showError(context, 'Please fill all required date fields');
      HapticFeedback.mediumImpact();
      return;
    }
    if (!isEditMode && (_proposedDate == null || _workDate == null)) {
      ToastUtils.showError(context, 'Please fill all required date fields');
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool isEditMode = widget.leave != null;

      if (isEditMode) {
        // Update existing leave
        final request = UpdateLeaveRequest(
          leaveCategoryId: _selectedCategory!.leaveCategoryId,
          dateBegin: _startDate!,
          dateEnd: _endDate!,
          dateWork: _workDate, // Optional: only if user changed it
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          addressLeave: _addressController.text.isNotEmpty
              ? _addressController.text
              : null,
          phoneLeave:
              _phoneController.text.isNotEmpty ? _phoneController.text : null,
        );

        await _leaveService.updateEmployeeLeave(
          widget.leave!.employeeLeaveId,
          request,
        );
      } else {
        // Create new leave
        final request = CreateLeaveRequest(
          leaveCategoryId: _selectedCategory!.leaveCategoryId,
          substituteEmployeeId: _selectedSubstitute?.employeeId,
          dateProposed: _proposedDate!,
          dateBegin: _startDate!,
          dateEnd: _endDate!,
          dateWork: _workDate!,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          addressLeave: _addressController.text.isNotEmpty
              ? _addressController.text
              : null,
          phoneLeave:
              _phoneController.text.isNotEmpty ? _phoneController.text : null,
        );

        await _leaveService.createEmployeeLeave(request);
      }

      // Success handling for both create and update
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context, true); // Return true to reload list

        // Use Future.microtask to avoid Navigator lock when showing success toast
        Future.microtask(() {
          if (mounted) {
            ToastUtils.showSuccess(
              context,
              widget.leave != null
                  ? 'Leave request updated successfully'
                  : 'Leave request created successfully',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Use Future.microtask to avoid Navigator lock when showing error toast
        Future.microtask(() {
          if (mounted) {
            ToastUtils.showError(
              context,
              widget.leave != null
                  ? 'Failed to update leave request'
                  : 'Failed to create leave request',
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingData) {
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
            widget.leave != null
                ? 'Edit Leave Request'
                : 'Create Leave Request',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
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
          widget.leave != null ? 'Edit Leave Request' : 'Create Leave Request',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee (Read-only, auto-filled)
                  _buildTextFormField(
                    controller:
                        TextEditingController(text: _currentEmployeeName),
                    label: 'Employee',
                    icon: Icons.person,
                    isDarkMode: isDarkMode,
                    enabled: false,
                    required: true,
                  ),

                  const SizedBox(height: 20),

                  // Leave Category Dropdown (Required)
                  _buildLeaveCategoryDropdown(
                    label: 'Leave Category',
                    icon: Icons.category,
                    value: _selectedCategory,
                    items: _categories,
                    isDarkMode: isDarkMode,
                    required: true,
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Employee Substitute Dropdown (Optional)
                  _buildEmployeeDropdown(
                    label: 'Employee Substitute',
                    icon: Icons.people,
                    value: _selectedSubstitute,
                    items: _employees,
                    isDarkMode: isDarkMode,
                    required: false,
                    onChanged: (value) {
                      setState(() => _selectedSubstitute = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Proposed Date (Required)
                  _buildDateField(
                    label: 'Proposed Date',
                    icon: Icons.event_note,
                    date: _proposedDate,
                    isDarkMode: isDarkMode,
                    required: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _selectDate(
                        context,
                        initialDate: _proposedDate ?? DateTime.now(),
                        onDateSelected: (date) {
                          setState(() => _proposedDate = date);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Start Leave Date (Required)
                  _buildDateField(
                    label: 'Start Leave',
                    icon: Icons.play_arrow,
                    date: _startDate,
                    isDarkMode: isDarkMode,
                    required: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _selectDate(
                        context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: _proposedDate,
                        onDateSelected: (date) {
                          setState(() => _startDate = date);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // End Leave Date (Required)
                  _buildDateField(
                    label: 'End Leave',
                    icon: Icons.stop,
                    date: _endDate,
                    isDarkMode: isDarkMode,
                    required: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _selectDate(
                        context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: _startDate,
                        onDateSelected: (date) {
                          setState(() => _endDate = date);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Start of Work Date (Required)
                  _buildDateField(
                    label: 'Start of Work',
                    icon: Icons.work,
                    date: _workDate,
                    isDarkMode: isDarkMode,
                    required: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _selectDate(
                        context,
                        initialDate: _workDate ?? _endDate ?? DateTime.now(),
                        firstDate: _endDate,
                        onDateSelected: (date) {
                          setState(() => _workDate = date);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Address when Leave (Optional)
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'Address when Leave',
                    icon: Icons.location_on,
                    isDarkMode: isDarkMode,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),

                  // Phone when Leave (Optional)
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'Phone when Leave',
                    icon: Icons.phone,
                    isDarkMode: isDarkMode,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 20),

                  // Remarks (Optional)
                  _buildTextFormField(
                    controller: _notesController,
                    label: 'Remarks',
                    icon: Icons.note,
                    isDarkMode: isDarkMode,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.leave != null
                                  ? 'Update Leave Request'
                                  : 'Submit Leave Request',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    bool enabled = true,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode ? AppColors.dangerDark : AppColors.dangerLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isDarkMode
                  ? AppColors.secondaryDark
                  : AppColors.secondaryLight,
            ),
            filled: true,
            fillColor:
                isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode
                    ? AppColors.surfaceAltDark.withOpacity(0.5)
                    : AppColors.mutedLight.withOpacity(0.5),
              ),
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required bool isDarkMode,
    required VoidCallback onTap,
    bool required = false,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode ? AppColors.dangerDark : AppColors.dangerLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDarkMode
                      ? AppColors.secondaryDark
                      : AppColors.secondaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date) : 'Select Date',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null
                          ? (isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight)
                          : (isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCategoryDropdown({
    required String label,
    required IconData icon,
    required LeaveCategory? value,
    required List<LeaveCategory> items,
    required bool isDarkMode,
    required Function(LeaveCategory?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode ? AppColors.dangerDark : AppColors.dangerLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<LeaveCategory>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isDarkMode
                  ? AppColors.secondaryDark
                  : AppColors.secondaryLight,
            ),
            filled: true,
            fillColor:
                isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                width: 2,
              ),
            ),
          ),
          dropdownColor:
              isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          items: items.map((LeaveCategory category) {
            return DropdownMenuItem<LeaveCategory>(
              value: category,
              child: Text(category.leaveCategoryName),
            );
          }).toList(),
          onChanged: onChanged,
          validator: required
              ? (value) {
                  if (value == null) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildEmployeeDropdown({
    required String label,
    required IconData icon,
    required Employee? value,
    required List<Employee> items,
    required bool isDarkMode,
    required Function(Employee?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode ? AppColors.dangerDark : AppColors.dangerLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            _showEmployeeSearchDialog(
              context: context,
              isDarkMode: isDarkMode,
              items: items,
              currentValue: value,
              onSelected: onChanged,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDarkMode
                      ? AppColors.secondaryDark
                      : AppColors.secondaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value != null
                        ? '${value.fullname} (${value.employeeNumber})'
                        : 'Select Substitute (Optional)',
                    style: TextStyle(
                      color: value != null
                          ? (isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight)
                          : (isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.search,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEmployeeSearchDialog({
    required BuildContext context,
    required bool isDarkMode,
    required List<Employee> items,
    required Employee? currentValue,
    required Function(Employee?) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _EmployeeSearchDialog(
          isDarkMode: isDarkMode,
          employees: items,
          currentValue: currentValue,
          onSelected: (employee) {
            onSelected(employee);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _EmployeeSearchDialog extends StatefulWidget {
  final bool isDarkMode;
  final List<Employee> employees;
  final Employee? currentValue;
  final Function(Employee?) onSelected;

  const _EmployeeSearchDialog({
    required this.isDarkMode,
    required this.employees,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_EmployeeSearchDialog> createState() => _EmployeeSearchDialogState();
}

class _EmployeeSearchDialogState extends State<_EmployeeSearchDialog> {
  late TextEditingController _searchController;
  late List<Employee> _filteredEmployees;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredEmployees = widget.employees;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = widget.employees;
      } else {
        _filteredEmployees = widget.employees.where((employee) {
          final fullnameLower = employee.fullname.toLowerCase();
          final numberLower = employee.employeeNumber.toLowerCase();
          final queryLower = query.toLowerCase();
          return fullnameLower.contains(queryLower) ||
              numberLower.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          widget.isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Employee',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: widget.isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              onChanged: _filterEmployees,
              decoration: InputDecoration(
                hintText: 'Search by name or employee number...',
                hintStyle: TextStyle(
                  color: widget.isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: widget.isDarkMode
                      ? AppColors.secondaryDark
                      : AppColors.secondaryLight,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: widget.isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterEmployees('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: widget.isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDarkMode
                        ? AppColors.surfaceAltDark
                        : AppColors.mutedLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDarkMode
                        ? AppColors.surfaceAltDark
                        : AppColors.mutedLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isDarkMode
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                color: widget.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),

            // Clear selection option
            ListTile(
              leading: Icon(
                Icons.clear,
                color: widget.isDarkMode
                    ? AppColors.dangerDark
                    : AppColors.dangerLight,
              ),
              title: Text(
                'Clear Selection',
                style: TextStyle(
                  color: widget.isDarkMode
                      ? AppColors.dangerDark
                      : AppColors.dangerLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => widget.onSelected(null),
              tileColor: widget.isDarkMode
                  ? AppColors.surfaceAltDark.withOpacity(0.3)
                  : AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),

            // Employee list
            Expanded(
              child: _filteredEmployees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: widget.isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No employees found',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredEmployees.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final employee = _filteredEmployees[index];
                        final isSelected = widget.currentValue?.employeeId ==
                            employee.employeeId;

                        return ListTile(
                          leading: Icon(
                            Icons.badge_outlined,
                            color: widget.isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          title: Text(
                            employee.fullname,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            employee.employeeNumber,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: widget.isDarkMode
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight,
                                )
                              : null,
                          onTap: () => widget.onSelected(employee),
                          tileColor: isSelected
                              ? (widget.isDarkMode
                                  ? AppColors.primaryDark.withOpacity(0.1)
                                  : AppColors.primaryLight.withOpacity(0.1))
                              : (widget.isDarkMode
                                  ? AppColors.surfaceAltDark
                                  : AppColors.surfaceLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: isSelected
                                ? BorderSide(
                                    color: widget.isDarkMode
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

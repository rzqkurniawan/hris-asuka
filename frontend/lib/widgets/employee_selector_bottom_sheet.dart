import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/employee.dart';

class EmployeeSelectorBottomSheet extends StatefulWidget {
  final Employee? initialEmployee;
  final Function(Employee) onEmployeeSelected;

  const EmployeeSelectorBottomSheet({
    super.key,
    this.initialEmployee,
    required this.onEmployeeSelected,
  });

  @override
  State<EmployeeSelectorBottomSheet> createState() =>
      _EmployeeSelectorBottomSheetState();
}

class _EmployeeSelectorBottomSheetState
    extends State<EmployeeSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  Employee? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _allEmployees = Employee.getSampleEmployees();
    _filteredEmployees = _allEmployees;
    _selectedEmployee = widget.initialEmployee;
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _allEmployees;
      } else {
        _filteredEmployees = _allEmployees.where((employee) {
          return employee.name.toLowerCase().contains(query) ||
              employee.id.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  void _confirmSelection() {
    if (_selectedEmployee != null) {
      widget.onEmployeeSelected(_selectedEmployee!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.2)
                : const Color(0xFFE0F2FE),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF94A3B8).withOpacity(0.3)
                  : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B).withOpacity(0.15)
                      : const Color(0xFFE0F2FE),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Employee',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your employee profile',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),

          // Search Box
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155).withOpacity(0.2)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155).withOpacity(0.2)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0EA5E9),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Employee List
          Flexible(
            child: _filteredEmployees.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: isDark
                                ? const Color(0xFF94A3B8).withOpacity(0.3)
                                : const Color(0xFF64748B).withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No employees found',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = _filteredEmployees[index];
                      final isSelected = _selectedEmployee?.id == employee.id;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEmployee = employee;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0EA5E9).withOpacity(0.15)
                                : null,
                            border: Border(
                              left: isSelected
                                  ? const BorderSide(
                                      color: Color(0xFF0EA5E9),
                                      width: 3,
                                    )
                                  : BorderSide.none,
                              bottom: BorderSide(
                                color: isDark
                                    ? const Color(0xFF1E293B).withOpacity(0.05)
                                    : const Color(0xFFF0F9FF),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Employee Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 15.2,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      employee.id,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 12.8,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              // Check Icon
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF0EA5E9),
                                  size: 24,
                                )
                                    .animate()
                                    .scale(
                                      duration: 200.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .fadeIn(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B).withOpacity(0.15)
                      : const Color(0xFFE0F2FE),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedEmployee == null ? null : _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE0F2FE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Selection',
                  style: TextStyle(
                    fontSize: 15.2,
                    fontWeight: FontWeight.w600,
                    color: _selectedEmployee == null
                        ? (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B))
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the bottom sheet
Future<Employee?> showEmployeeSelector(
  BuildContext context, {
  Employee? initialEmployee,
}) async {
  return await showModalBottomSheet<Employee>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EmployeeSelectorBottomSheet(
      initialEmployee: initialEmployee,
      onEmployeeSelected: (employee) {
        Navigator.pop(context, employee);
      },
    ),
  );
}

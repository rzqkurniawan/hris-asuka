import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/employee.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();

  Employee? _selectedEmployee;
  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showEmployeeList = false;
  bool _employeeFieldTouched = false;

  @override
  void initState() {
    super.initState();
    _allEmployees = Employee.getSampleEmployees();
    _filteredEmployees = _allEmployees;
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleRegister() async {
    setState(() => _employeeFieldTouched = true);

    if (_selectedEmployee == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Navigate back to login
      Navigator.pop(context);
    }
  }

  void _selectEmployee(Employee employee) {
    setState(() {
      _selectedEmployee = employee;
      _showEmployeeList = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasEmployeeError = _employeeFieldTouched && _selectedEmployee == null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 50),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                // Logo
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E293B).withOpacity(0.15)
                            : const Color(0xFFE0F2FE),
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color:
                                    const Color(0xFF0C4A6E).withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/logo/HRIS_LOGO.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOut,
                      ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  'Register to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0369A1),
                      ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 40),

                // Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Employee Selector Field
                        Text(
                          'Select Employee',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 8),

                        // Search Field
                        TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search employee name or ID...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _showEmployeeList = false);
                                    },
                                  )
                                : null,
                            errorText: hasEmployeeError
                                ? 'Employee selection is required'
                                : null,
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFBE123C),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() => _showEmployeeList = true);
                          },
                          onChanged: (value) {
                            setState(
                                () => _showEmployeeList = value.isNotEmpty);
                          },
                        ),

                        // Selected Employee Display
                        if (_selectedEmployee != null &&
                            !_showEmployeeList) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF0EA5E9).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF0EA5E9),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedEmployee!.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFFF1F5F9)
                                              : const Color(0xFF164E63),
                                        ),
                                      ),
                                      Text(
                                        _selectedEmployee!.id,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedEmployee = null;
                                      _searchController.clear();
                                    });
                                  },
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Employee List
                        if (_showEmployeeList &&
                            _searchController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155).withOpacity(0.2)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: _filteredEmployees.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Text(
                                        'No employees found',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredEmployees.length,
                                    itemBuilder: (context, index) {
                                      final employee =
                                          _filteredEmployees[index];
                                      return InkWell(
                                        onTap: () => _selectEmployee(employee),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: isDark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFF0F9FF),
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                employee.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? const Color(0xFFF1F5F9)
                                                      : const Color(0xFF164E63),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                employee.id,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Username Field
                        Text(
                          'Username',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Create your username',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username is required';
                            }
                            if (value.length < 4) {
                              return 'Username must be at least 4 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        Text(
                          'Password',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Create your password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Register Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Login Link
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E293B).withOpacity(0.15)
                            : const Color(0xFFE0F2FE),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 600.ms),

                const SizedBox(height: 20),

                // Footer
                Text(
                  '© 2025 HRIS Asuka. All rights reserved.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                  textAlign: TextAlign.center,
                ).animate(delay: 600.ms).fadeIn(duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

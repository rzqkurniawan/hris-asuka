import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../utils/toast_utils.dart';
import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _searchController = TextEditingController();

  Map<String, dynamic>? _selectedEmployee;
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _showEmployeeList = false;
  bool _employeeFieldTouched = false;
  bool _isLoadingEmployees = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nikController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.length >= 3) {
        _searchEmployees(_searchController.text);
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _filteredEmployees = [];
          _showEmployeeList = false;
        });
      }
    });
  }

  Future<void> _searchEmployees(String query) async {
    setState(() {
      _isLoadingEmployees = true;
      _showEmployeeList = true;
    });

    try {
      final authService = AuthService();
      // Add explicit timeout to catch hangs
      final employees = await authService
          .getAvailableEmployees(query: query)
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          _filteredEmployees = employees;
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
        ToastUtils.showError(context, 'Search failed: $e');
      }
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _employeeFieldTouched = true);

    if (_selectedEmployee == null || !_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.register(
        employeeId: _selectedEmployee!['employee_id'] as int,
        nik: _nikController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Navigate back to login with success result
        // Toast will be shown on login page after navigation
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.mediumImpact();
        ToastUtils.showError(
          context,
          e.toString(),
        );
      }
    }
  }

  void _selectEmployee(Map<String, dynamic> employee) {
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
      appBar: AppBar(
        title: const Text('Register'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                ),

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
                ),

                const SizedBox(height: 30),

                // Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Employee Selector
                        Text(
                          'Select Employee',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 8),

                        if (_isLoadingEmployees)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          // Search Field
                          TextFormField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Type at least 3 characters to search...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(
                                            () => _showEmployeeList = false);
                                      },
                                    )
                                  : null,
                              errorText: hasEmployeeError
                                  ? 'Employee selection is required'
                                  : null,
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
                                  color:
                                      const Color(0xFF0EA5E9).withOpacity(0.3),
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
                                          (_selectedEmployee!['fullname'] ?? 'Unknown').toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          (_selectedEmployee!['employee_number'] ?? '').toString(),
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
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Employee List
                          if (_showEmployeeList && _filteredEmployees.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE0F2FE),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredEmployees.length,
                                itemBuilder: (context, index) {
                                  final employee = _filteredEmployees[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      (employee['fullname'] ?? 'Unknown').toString(),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      (employee['employee_number'] ?? '').toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () => _selectEmployee(employee),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 20),

                        // NIK Field
                        Text(
                          'NIK (16 Digit)',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nikController,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          decoration: const InputDecoration(
                            hintText: 'Enter 16-digit NIK',
                            prefixIcon: Icon(Icons.badge_outlined),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'NIK is required';
                            }
                            if (value.length != 16) {
                              return 'NIK must be exactly 16 digits';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'NIK must contain only numbers';
                            }
                            return null;
                          },
                        ),

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
                          maxLength: 12,
                          decoration: const InputDecoration(
                            hintText: 'Enter your username (6-12 characters)',
                            prefixIcon: Icon(Icons.person_outline),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username is required';
                            }
                            if (value.length < 6) {
                              return 'Username minimal 6 karakter';
                            }
                            if (value.length > 12) {
                              return 'Username maksimal 12 karakter';
                            }
                            // Only alphanumeric
                            if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                              return 'Username hanya boleh huruf dan angka';
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
                          maxLength: 12,
                          decoration: InputDecoration(
                            hintText: 'Enter your password (8-12 characters)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
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
                            if (value.length < 8) {
                              return 'Password minimal 8 karakter';
                            }
                            if (value.length > 12) {
                              return 'Password maksimal 12 karakter';
                            }
                            // Must contain both letters and numbers
                            if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+$')
                                .hasMatch(value)) {
                              return 'Password harus ada huruf dan angka';
                            }
                            // Check for common passwords
                            final commonPasswords = [
                              '12345678',
                              '123456789',
                              '1234567890',
                              'password',
                              'password1',
                              'password123',
                              'qwerty123',
                              'abc12345',
                              'admin123',
                              '87654321',
                              'asdf1234',
                              'qwer1234',
                            ];
                            if (commonPasswords
                                .contains(value.toLowerCase())) {
                              return 'Password terlalu umum';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Confirm Password Field
                        Text(
                          'Confirm Password',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          maxLength: 12,
                          decoration: InputDecoration(
                            hintText: 'Confirm your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok';
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
                ),

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

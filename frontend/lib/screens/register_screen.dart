import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
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
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.surfaceAltDark.withOpacity(0.15)
                            : AppColors.mutedLight,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/logo/HRIS_LOGO_NEW.png',
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
                            ? AppColors.textSecondaryDark
                            : AppColors.secondaryLight,
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
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.accent,
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
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
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
                                      ? AppColors.surfaceAltDark
                                      : AppColors.mutedLight,
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

                        // Username Requirements Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Username Requirements:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• 6-12 characters\n• Letters and numbers only (a-z, A-Z, 0-9)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                          maxLength: 128,
                          decoration: InputDecoration(
                            hintText: 'Enter your password (min. 12 characters)',
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
                            if (value.length < 12) {
                              return 'Password minimal 12 karakter';
                            }
                            if (value.length > 128) {
                              return 'Password maksimal 128 karakter';
                            }
                            // Must contain uppercase
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Password harus ada huruf besar (A-Z)';
                            }
                            // Must contain lowercase
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Password harus ada huruf kecil (a-z)';
                            }
                            // Must contain number
                            if (!RegExp(r'\d').hasMatch(value)) {
                              return 'Password harus ada angka (0-9)';
                            }
                            // Must contain special character
                            if (!RegExp(r'[@$!%*?&#^()_+=\[\]{};:' "'" r'",.<>\/\\|`~-]').hasMatch(value)) {
                              return 'Password harus ada karakter khusus (!@#\$%^&*)';
                            }
                            // Check for common passwords
                            final commonPasswords = [
                              '123456789012',
                              'password1234',
                              'password12345',
                              'qwerty123456',
                              'admin1234567',
                            ];
                            if (commonPasswords.contains(value.toLowerCase())) {
                              return 'Password terlalu umum';
                            }
                            return null;
                          },
                        ),

                        // Password Requirements Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.security,
                                color: Colors.orange[700],
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Requirements:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• Minimum 12 characters\n• At least one uppercase letter (A-Z)\n• At least one lowercase letter (a-z)\n• At least one number (0-9)\n• At least one special character (!@#\$%^&*)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                          maxLength: 128,
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
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.overlayLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.overlayLight,
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
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
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

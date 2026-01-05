import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../utils/toast_utils.dart';
import '../utils/debug_logger.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import 'face_verification_register_screen.dart';
import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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
      final employeeId = _selectedEmployee!['employee_id'] as int;
      final employeeName = (_selectedEmployee!['fullname'] ?? 'Unknown').toString();

      DebugLogger.log('Getting employee avatar for face verification', tag: 'Register');

      // Step 1: Get employee avatar for face verification
      final avatarData = await authService.getEmployeeAvatarForRegister(
        employeeId: employeeId,
      );

      if (!mounted) return;

      final avatarUrl = avatarData['avatar_url'] as String?;

      if (avatarUrl == null || avatarUrl.isEmpty) {
        setState(() => _isLoading = false);
        HapticFeedback.mediumImpact();
        final l10n = AppLocalizations.of(context);
        ToastUtils.showError(
          context,
          '${l10n.get('face_required')}. ${l10n.contactHrd}.',
        );
        return;
      }

      setState(() => _isLoading = false);

      DebugLogger.log('Avatar URL: $avatarUrl', tag: 'Register');

      // Step 2: Navigate to face verification screen
      final registrationData = RegistrationData(
        employeeId: employeeId,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        employeeName: employeeName,
        avatarUrl: avatarUrl,
      );

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => FaceVerificationRegisterScreen(
            registrationData: registrationData,
          ),
        ),
      );

      // Step 3: Handle result
      if (result == true && mounted) {
        // Registration successful, navigate back to login
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.mediumImpact();
        ToastUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.mediumImpact();
        DebugLogger.error('Register error', error: e, tag: 'Register');
        final l10n = AppLocalizations.of(context);
        ToastUtils.showError(
          context,
          '${l10n.somethingWentWrong}: ${e.toString()}',
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.register),
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
                  l10n.get('create_account'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  l10n.get('register_to_start'),
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
                          l10n.selectEmployee,
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
                              hintText: l10n.get('type_to_search'),
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
                                  ? l10n.get('employee_required')
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

                        // Username Field
                        Text(
                          l10n.username,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          maxLength: 12,
                          decoration: InputDecoration(
                            hintText: l10n.get('enter_username_hint'),
                            prefixIcon: const Icon(Icons.person_outline),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.fieldRequired;
                            }
                            if (value.length < 6) {
                              return l10n.get('min_length').replaceAll('{0}', '6');
                            }
                            if (value.length > 12) {
                              return l10n.get('max_length').replaceAll('{0}', '12');
                            }
                            // Only alphanumeric
                            if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                              return l10n.usernameAlphanumeric;
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
                                      l10n.get('username_requirements'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.get('username_requirements_detail'),
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
                          l10n.password,
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
                            hintText: l10n.get('enter_password_hint'),
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
                              return l10n.fieldRequired;
                            }
                            if (value.length < 6) {
                              return l10n.get('password_min_6');
                            }
                            if (value.length > 128) {
                              return l10n.get('password_max_128');
                            }
                            // Must contain at least one uppercase letter
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return l10n.get('password_need_uppercase');
                            }
                            // Must contain at least one number
                            if (!RegExp(r'\d').hasMatch(value)) {
                              return l10n.get('password_need_number');
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
                                      l10n.get('password_requirements_title'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.get('password_requirements_simple'),
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
                          l10n.confirmPassword,
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
                            hintText: l10n.get('confirm_your_password'),
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
                              return l10n.fieldRequired;
                            }
                            if (value != _passwordController.text) {
                              return l10n.passwordNotMatch;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Info about face verification
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.face,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.livenessVerificationRequired,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.get('face_verification_info'),
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
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          l10n.continueToFaceVerification,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
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
                      '${l10n.alreadyHaveAccount} ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.login,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/toast_utils.dart';
import '../utils/page_transitions.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setUser(user);
        Navigator.of(context).pushReplacement(
          FadeRoute(page: const MainScreen()),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          final displayName = user.fullname.length > 25
              ? '${user.fullname.substring(0, 25)}...'
              : user.fullname;
          ToastUtils.showSuccess(context, 'Welcome, $displayName!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.mediumImpact();
        ToastUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('LoginScreen: build (isDark: $isDark)');

    // Minimal test screen to diagnose rendering issue
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login Screen Test',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => print('Button pressed'),
              child: const Text('Test Button'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Minimum splash duration for UX
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if onboarding completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingCompleted) {
      // First time user, show onboarding
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
      return;
    }

    // Initialize AuthProvider to check if user is already logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      print('🔍 Starting auth initialization...');
      await authProvider.initialize();
      print('✅ Auth initialization complete. Status: ${authProvider.status}');
      print('🔐 Is authenticated: ${authProvider.isAuthenticated}');
    } catch (e) {
      // If initialization fails (401 error from old token), clear storage
      print('❌ Auth initialization failed: $e');
      await authProvider.logout(); // This will clear all tokens
    }

    if (!mounted) return;

    // Navigate based on auth status
    print('🧭 Navigating... isAuthenticated: ${authProvider.isAuthenticated}');
    if (authProvider.isAuthenticated) {
      // User is already logged in, go to main screen
      print('→ Going to /main');
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // User not logged in, go to login screen
      print('→ Going to /login');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    AppColors.surfaceDark,
                  ]
                : [
                    AppColors.backgroundLight,
                    AppColors.mutedLight,
                  ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? AppColors.surfaceAltDark.withOpacity(0.15)
                      : AppColors.mutedLight,
                  width: 1,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primaryLight.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/logo/HRIS_LOGO_NEW.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),
            
            const SizedBox(height: 24),
            
            // App Title
            Text(
              'HRIS Asuka',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 6),
            
            // Subtitle
            Text(
              'Human Resource Information System',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.secondaryLight,
                  ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 80),
            
            // Loading Bar
            SizedBox(
              width: 160,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        backgroundColor: isDark
                            ? AppColors.textSecondaryDark.withOpacity(0.2)
                            : AppColors.mutedLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 600.ms),
          ],
        ),
      ),
    );
  }
}

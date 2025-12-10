import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_dialog.dart';
import '../utils/page_transitions.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'login_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../constants/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _handleLogout() async {
    HapticFeedback.lightImpact();

    final shouldLogout = await CustomDialog.showConfirmation(
          context: context,
          title: 'Logout',
          message: 'Are you sure you want to logout?',
          confirmText: 'Logout',
          cancelText: 'Cancel',
        ) ??
        false;

    if (!shouldLogout || !mounted) return;

    HapticFeedback.mediumImpact();
    // Clear auth session before navigating to login
    try {
      await context.read<AuthProvider>().logout();
    } catch (e) {
      // Ignore errors on logout; fallback to navigation
      debugPrint('Logout error: $e');
    }
    Navigator.of(context).pushAndRemoveUntil(
      FadeRoute(page: const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo/HRIS_LOGO.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _currentIndex == 0 ? 'HRIS Asuka' : 'My Profile',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              // Theme Toggle Button
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.surfaceAltDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    context.read<ThemeProvider>().toggleTheme();
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      key: ValueKey(isDarkMode),
                      color: isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
              // Logout Button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.surfaceAltDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _handleLogout,
                  icon: Icon(
                    Icons.logout,
                    color: isDarkMode
                        ? AppColors.dangerDark
                        : AppColors.dangerLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // PageView for swipe gesture
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              HomePage(),
              ProfilePage(),
            ],
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              hasNotification: false,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_dialog.dart';
import '../utils/page_transitions.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'login_screen.dart';
import 'mobile_attendance_screen.dart';
import '../widgets/fab_bottom_nav_bar.dart';
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

  void _onAttendanceFabPressed() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      SlideUpRoute(page: const MobileAttendanceScreen()),
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
    try {
      await context.read<AuthProvider>().logout();
    } catch (e) {
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
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: Image.asset(
                  'assets/logo/HRIS_LOGO_NEW.png',
                  width: 28.w,
                  height: 28.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              _currentIndex == 0 ? 'HRIS Asuka' : 'My Profile',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle Button
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.surfaceAltDark
                  : AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
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
                  isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(isDarkMode),
                  color: isDarkMode
                      ? AppColors.timeMorning
                      : AppColors.accent,
                  size: 22.sp,
                ),
              ),
            ),
          ),
          // Logout Button
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.surfaceAltDark
                  : AppColors.dangerLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: _handleLogout,
              icon: Icon(
                Icons.logout_rounded,
                color: AppColors.dangerLight,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // PageView for swipe gesture
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: const [
              HomePage(),
              ProfilePage(),
            ],
          ),

          // Bottom Navigation Bar with FAB
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FabBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              onFabPressed: _onAttendanceFabPressed,
              hasNotification: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide Up Route for attendance screen
class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

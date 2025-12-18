import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingData> _getPages(AppLocalizations l10n) {
    return [
      OnboardingData(
        icon: Icons.access_time_rounded,
        title: l10n.get('onboarding_1_title'),
        description: l10n.get('onboarding_1_desc'),
        color: AppColors.accent,
      ),
      OnboardingData(
        icon: Icons.location_on_rounded,
        title: l10n.get('onboarding_2_title'),
        description: l10n.get('onboarding_2_desc'),
        color: AppColors.statusWork,
      ),
      OnboardingData(
        icon: Icons.face_rounded,
        title: l10n.get('onboarding_3_title'),
        description: l10n.get('onboarding_3_desc'),
        color: AppColors.statusLeave,
      ),
      OnboardingData(
        icon: Icons.history_rounded,
        title: l10n.get('onboarding_4_title'),
        description: l10n.get('onboarding_4_desc'),
        color: AppColors.statusLate,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const int _totalPages = 4;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final pages = _getPages(l10n);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      l10n.skip,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index], isDark, index);
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => _buildIndicator(index, isDark, pages),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _nextPage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == pages.length - 1
                                ? l10n.get('start_now')
                                : l10n.get('continue_button'),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            _currentPage == pages.length - 1
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(key: ValueKey(_currentPage))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, bool isDark, int index) {
    final isActive = _currentPage == index;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animated background
          Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  size: 64.sp,
                  color: data.color,
                ),
              ),
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

          SizedBox(height: 48.h),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .slideY(begin: 0.3, end: 0),

          SizedBox(height: 16.h),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, bool isDark, List<OnboardingData> pages) {
    final isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: isActive ? 32.w : 8.w,
      height: 8.h,
      decoration: BoxDecoration(
        color: isActive
            ? pages[_currentPage].color
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

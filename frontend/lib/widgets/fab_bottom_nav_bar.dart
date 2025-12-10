import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

class FabBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onFabPressed;
  final bool hasNotification;

  const FabBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFabPressed,
    this.hasNotification = false,
  });

  @override
  State<FabBottomNavBar> createState() => _FabBottomNavBarState();
}

class _FabBottomNavBarState extends State<FabBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _indicatorController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeInOutCubic,
    );

    // Initialize based on current index
    if (widget.currentIndex == 1) {
      _indicatorController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FabBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (widget.currentIndex == 1) {
        _indicatorController.forward();
      } else {
        _indicatorController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  void _onFabTapDown(TapDownDetails details) {
    _fabAnimationController.forward();
  }

  void _onFabTapUp(TapUpDetails details) {
    _fabAnimationController.reverse();
    HapticFeedback.mediumImpact();
    widget.onFabPressed?.call();
  }

  void _onFabTapCancel() {
    _fabAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 100.h,
      margin: EdgeInsets.only(bottom: 10.h),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Main Nav Bar Container
          Container(
            height: 75.h,
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(32.r),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.4)
                      : const Color(0xFF0C4A6E).withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final sideWidth = (trackWidth - 80.w) / 2; // Space for FAB

                return Stack(
                  children: [
                    // Sliding Indicator
                    AnimatedBuilder(
                      animation: _indicatorAnimation,
                      builder: (context, child) {
                        final startX = sideWidth / 2 - 30.w;
                        final endX = trackWidth - sideWidth / 2 - 30.w;
                        final currentX = startX + (endX - startX) * _indicatorAnimation.value;

                        return Positioned(
                          left: currentX,
                          top: 8.h,
                          child: Container(
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0EA5E9),
                                  Color(0xFF0284C7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Navigation Items
                    Row(
                      children: [
                        // Left Side - Home
                        SizedBox(
                          width: sideWidth,
                          child: _buildNavItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: 'Home',
                            index: 0,
                            isDarkMode: isDarkMode,
                          ),
                        ),

                        // Center Space for FAB
                        SizedBox(width: 80.w),

                        // Right Side - Profile
                        SizedBox(
                          width: sideWidth,
                          child: _buildNavItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Profile',
                            index: 1,
                            hasNotification: widget.hasNotification,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.5, end: 0),

          // Center FAB
          Positioned(
            top: 0,
            child: GestureDetector(
              onTapDown: _onFabTapDown,
              onTapUp: _onFabTapUp,
              onTapCancel: _onFabTapCancel,
              child: AnimatedBuilder(
                animation: _fabScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabScaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 70.w,
                  height: 70.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse effect ring
                      Container(
                        width: 62.w,
                        height: 62.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 1500.ms,
                          )
                          .fadeOut(duration: 1500.ms),
                      // Main icon
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                          Text(
                            'Absen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDarkMode,
    bool hasNotification = false,
  }) {
    final isActive = widget.currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    size: 26.sp,
                    color: isActive
                        ? Colors.white
                        : isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 4.h),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                  child: Text(label),
                ),
              ],
            ),
            // Notification Badge
            if (hasNotification)
              Positioned(
                top: 0,
                right: -4.w,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

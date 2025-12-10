import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

class EnhancedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onFabPressed;
  final bool hasNotification;

  const EnhancedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFabPressed,
    this.hasNotification = false,
  });

  @override
  State<EnhancedBottomNavBar> createState() => _EnhancedBottomNavBarState();
}

class _EnhancedBottomNavBarState extends State<EnhancedBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
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
      height: 90.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Main Nav Bar Container
          Container(
            height: 72.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.4)
                      : const Color(0xFF0EA5E9).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Side Items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                        index: 0,
                        isDarkMode: isDarkMode,
                      ),
                      _buildNavItem(
                        icon: Icons.history_rounded,
                        activeIcon: Icons.history_rounded,
                        label: 'History',
                        index: 1,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),

                // Space for FAB
                SizedBox(width: 70.w),

                // Right Side Items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications_rounded,
                        label: 'Notif',
                        index: 2,
                        hasNotification: widget.hasNotification,
                        isDarkMode: isDarkMode,
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        index: 3,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.3, end: 0),

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
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0EA5E9),
                        Color(0xFF0284C7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withOpacity(0.4),
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
                        width: 64.w,
                        height: 64.w,
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
                            end: const Offset(1.3, 1.3),
                            duration: 1500.ms,
                          )
                          .fadeOut(duration: 1500.ms),
                      // Main icon
                      Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 32.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDarkMode
                            ? const Color(0xFF0EA5E9).withOpacity(0.2)
                            : const Color(0xFF0EA5E9).withOpacity(0.1))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    size: 24.sp,
                    color: isActive
                        ? const Color(0xFF0EA5E9)
                        : isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 4.h),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF0EA5E9)
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
                top: 4,
                right: 4,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
                      width: 2,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 600.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

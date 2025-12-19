import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';

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
    final isTablet = Responsive.isTablet(context);

    // Use fixed pixels for tablet, ScreenUtil for phone
    final fabSize = isTablet ? 80.0 : 70.w;
    final navBarHeight = isTablet ? 80.0 : 75.h;
    final fabSpaceWidth = isTablet ? 100.0 : 80.w;
    final navBarMargin = isTablet ? 80.0 : 24.w;
    final containerHeight = isTablet ? 110.0 : 100.h;
    final bottomMargin = isTablet ? 10.0 : 10.h;
    final navBarBorderRadius = isTablet ? 32.0 : 32.r;

    return Container(
      height: containerHeight,
      margin: EdgeInsets.only(bottom: bottomMargin),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Main Nav Bar Container
          Center(
            child: Container(
              height: navBarHeight,
              margin: EdgeInsets.symmetric(horizontal: navBarMargin),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(navBarBorderRadius),
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
                  final sideWidth = (trackWidth - fabSpaceWidth) / 2;

                  return Stack(
                    children: [
                      // Sliding Indicator
                      AnimatedBuilder(
                        animation: _indicatorAnimation,
                        builder: (context, child) {
                          final indicatorWidth = isTablet ? 65.0 : 60.w;
                          final indicatorHeight = isTablet ? 65.0 : 60.h;
                          final indicatorTop = isTablet ? 8.0 : 8.h;
                          final indicatorBorderRadius = isTablet ? 20.0 : 20.r;
                          final startX = sideWidth / 2 - indicatorWidth / 2;
                          final endX = trackWidth - sideWidth / 2 - indicatorWidth / 2;
                          final currentX = startX + (endX - startX) * _indicatorAnimation.value;

                          return Positioned(
                            left: currentX,
                            top: indicatorTop,
                            child: Container(
                              width: indicatorWidth,
                              height: indicatorHeight,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0EA5E9),
                                    Color(0xFF0284C7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(indicatorBorderRadius),
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
                              isTablet: isTablet,
                            ),
                          ),

                          // Center Space for FAB
                          SizedBox(width: fabSpaceWidth),

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
                              isTablet: isTablet,
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
          ),

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
                  width: fabSize,
                  height: fabSize,
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
                        width: isTablet ? 72.0 : 62.w,
                        height: isTablet ? 72.0 : 62.w,
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
                            size: isTablet ? 32.0 : 28.sp,
                          ),
                          Text(
                            'Absen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 10.0 : 9.sp,
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
    required bool isTablet,
    bool hasNotification = false,
  }) {
    final isActive = widget.currentIndex == index;

    // Use fixed pixels for tablet
    final paddingVertical = isTablet ? 12.0 : 12.h;
    final iconSize = isTablet ? 28.0 : 26.sp;
    final labelFontSize = isTablet ? 12.0 : 11.sp;
    final spacingHeight = isTablet ? 4.0 : 4.h;
    final badgeSize = isTablet ? 10.0 : 10.w;
    final badgeRight = isTablet ? -4.0 : -4.w;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: paddingVertical),
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
                    size: iconSize,
                    color: isActive
                        ? Colors.white
                        : isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                  ),
                ),
                SizedBox(height: spacingHeight),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: labelFontSize,
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
                right: badgeRight,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
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

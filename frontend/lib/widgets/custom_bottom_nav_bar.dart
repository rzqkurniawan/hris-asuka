import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool hasNotification;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (widget.currentIndex == 1) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final itemWidth = trackWidth / 2;

          return SizedBox(
            height: 72,
            child: Stack(
              children: [
                // Sliding Indicator
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      left: itemWidth * _animation.value,
                      top: 8,
                      child: Container(
                        width: itemWidth,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: isDarkMode
                              ? AppColors.primaryGradientDark
                              : AppColors.secondaryGradientLight,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryLight.withOpacity(0.4),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(
                      icon: Icons.home,
                      label: 'Home',
                      index: 0,
                      isActive: widget.currentIndex == 0,
                      width: itemWidth,
                    ),
                    _buildNavItem(
                      icon: Icons.person,
                      label: 'Profile',
                      index: 1,
                      isActive: widget.currentIndex == 1,
                      hasNotification: widget.hasNotification,
                      width: itemWidth,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required double width,
    bool hasNotification = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                      icon,
                      size: 28,
                      color: isActive
                          ? Colors.white
                          : isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
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
                  top: -2,
                  right: width * 0.25,
                  child: _buildNotificationBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }
}

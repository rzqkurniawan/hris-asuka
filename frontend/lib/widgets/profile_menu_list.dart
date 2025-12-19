import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final Widget? trailing;
  final VoidCallback onTap;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.trailing,
    required this.onTap,
  });
}

class ProfileMenuList extends StatelessWidget {
  final List<ProfileMenuItem> items;
  final bool isDarkMode;

  const ProfileMenuList({
    super.key,
    required this.items,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    // Use fixed pixels for tablet, ScreenUtil for phone
    final gridSpacing = isTablet ? 12.0 : 12.w;
    final listSpacing = isTablet ? 12.0 : 12.h;

    if (isTablet) {
      // Use GridView for tablets (2 columns)
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: gridSpacing,
          mainAxisSpacing: gridSpacing,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildMenuItem(items[index], index, isTablet);
        },
      );
    }

    // Use ListView for phones
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: listSpacing),
      itemBuilder: (context, index) {
        return _buildMenuItem(items[index], index, isTablet);
      },
    );
  }

  Widget _buildMenuItem(ProfileMenuItem item, int index, bool isTablet) {
    final color = item.color ?? AppColors.secondaryLight;

    // Use fixed pixels for tablet, ScreenUtil for phone
    final containerPadding = isTablet ? 16.0 : 16.w;
    final borderRadius = isTablet ? 16.0 : 16.r;
    final iconContainerSize = isTablet ? 48.0 : 48.w;
    final iconBorderRadius = isTablet ? 12.0 : 12.r;
    final iconSize = isTablet ? 24.0 : 24.sp;
    final spacingWidth = isTablet ? 14.0 : 14.w;
    final titleFontSize = isTablet ? 15.0 : 15.sp;
    final subtitleFontSize = isTablet ? 12.0 : 12.sp;
    final spacingHeight = isTablet ? 2.0 : 2.h;
    final trailingSize = isTablet ? 32.0 : 32.w;
    final trailingIconSize = isTablet ? 20.0 : 20.sp;

    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: EdgeInsets.all(containerPadding),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border(
            left: BorderSide(
              color: color,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with colored background
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(iconBorderRadius),
              ),
              child: Icon(
                item.icon,
                color: color,
                size: iconSize,
              ),
            ),
            SizedBox(width: spacingWidth),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacingHeight),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Trailing widget or default arrow (hide on tablet to save space)
            if (!isTablet)
              item.trailing ?? Container(
                width: trailingSize,
                height: trailingSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: trailingIconSize,
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 80))
        .slideX(begin: 0.1, end: 0);
  }
}

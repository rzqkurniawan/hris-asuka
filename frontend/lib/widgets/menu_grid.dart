import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';

class MenuGridItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  MenuGridItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class MenuGrid extends StatelessWidget {
  final List<MenuGridItem> items;

  const MenuGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final columns = Responsive.getMenuGridColumns(context);
    // Use fixed pixels for tablet, ScreenUtil for phone
    final spacing = isTablet
        ? Responsive.getGridSpacing(context)
        : 15.w;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: isTablet ? 1.0 : 1.2,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildMenuItem(items[index], context);
      },
    );
  }

  Widget _buildMenuItem(MenuGridItem item, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTablet = Responsive.isTablet(context);

    // Use fixed pixels for tablet, ScreenUtil for phone
    final iconContainerSize = isTablet
        ? Responsive.getMenuIconSize(context)
        : 50.w;
    final padding = isTablet ? 20.0 : 20.w;
    final borderRadius = isTablet ? 16.0 : 16.r;
    final iconBorderRadius = isTablet ? 12.0 : 12.r;
    final iconSize = isTablet ? 28.0 : 26.sp;
    final fontSize = isTablet ? 14.0 : 13.sp;
    final spacing = isTablet ? 12.0 : 12.h;

    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradientLight,
                borderRadius: BorderRadius.circular(iconBorderRadius),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(height: spacing),
            // Label
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

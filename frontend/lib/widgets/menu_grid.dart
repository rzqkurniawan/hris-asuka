import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildMenuItem(items[index], context);
      },
    );
  }

  Widget _buildMenuItem(MenuGridItem item, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradientLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            // Label
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
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

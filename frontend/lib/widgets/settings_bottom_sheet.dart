import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_utils.dart';
import 'change_password_bottom_sheet.dart';

void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SettingsBottomSheet(),
  );
}

class _SettingsBottomSheet extends StatelessWidget {
  const _SettingsBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, LocaleProvider, AuthProvider>(
      builder: (context, themeProvider, localeProvider, authProvider, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context);
        final isTablet = Responsive.isTablet(context);

        // Use fixed pixels for tablet, ScreenUtil for phone
        final borderRadius = isTablet ? 24.0 : 24.r;
        final handleMarginTop = isTablet ? 12.0 : 12.h;
        final handleWidth = isTablet ? 40.0 : 40.w;
        final handleHeight = isTablet ? 4.0 : 4.h;
        final handleBorderRadius = isTablet ? 2.0 : 2.r;
        final titlePadding = isTablet ? 20.0 : 20.w;
        final iconContainerPadding = isTablet ? 10.0 : 10.w;
        final iconContainerBorderRadius = isTablet ? 12.0 : 12.r;
        final iconSize = isTablet ? 24.0 : 24.sp;
        final titleSpacing = isTablet ? 12.0 : 12.w;
        final titleFontSize = isTablet ? 20.0 : 20.sp;
        final menuHorizontalPadding = isTablet ? 16.0 : 16.w;
        final menuVerticalPadding = isTablet ? 8.0 : 8.h;
        final menuItemSpacing = isTablet ? 8.0 : 8.h;
        final bottomSpacing = isTablet ? 16.0 : 16.h;
        final langPaddingH = isTablet ? 8.0 : 8.w;
        final langPaddingV = isTablet ? 4.0 : 4.h;
        final langBorderRadius = isTablet ? 8.0 : 8.r;
        final langFontSize = isTablet ? 12.0 : 12.sp;
        final langSpacing = isTablet ? 4.0 : 4.w;
        final langIconSize = isTablet ? 16.0 : 16.sp;

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: handleMarginTop),
                  width: handleWidth,
                  height: handleHeight,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.textSecondaryDark.withOpacity(0.3)
                        : AppColors.textSecondaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(handleBorderRadius),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.all(titlePadding),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconContainerPadding),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(iconContainerBorderRadius),
                        ),
                        child: Icon(
                          Icons.settings_rounded,
                          color: AppColors.accent,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: titleSpacing),
                      Text(
                        l10n.settings,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  color: isDarkMode
                      ? AppColors.surfaceAltDark
                      : AppColors.mutedLight,
                ),

                // Menu Items
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: menuHorizontalPadding, vertical: menuVerticalPadding),
                  child: Column(
                    children: [
                      // Language
                      _buildMenuItem(
                        context: context,
                        isDarkMode: isDarkMode,
                        isTablet: isTablet,
                        icon: Icons.language_rounded,
                        title: l10n.language,
                        subtitle: localeProvider.currentLanguageName,
                        color: AppColors.accent,
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: langPaddingH, vertical: langPaddingV),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(langBorderRadius),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localeProvider.isIndonesian ? 'ID' : 'EN',
                                style: TextStyle(
                                  fontSize: langFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                              SizedBox(width: langSpacing),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.accent,
                                size: langIconSize,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showLanguageDialog(context, localeProvider, isDarkMode);
                        },
                      ),

                      SizedBox(height: menuItemSpacing),

                      // Theme Switch
                      _buildMenuItem(
                        context: context,
                        isDarkMode: isDarkMode,
                        isTablet: isTablet,
                        icon: isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        title: l10n.theme,
                        subtitle: isDarkMode ? l10n.darkMode : l10n.lightMode,
                        color: isDarkMode ? Colors.indigo : Colors.amber,
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            themeProvider.toggleTheme();
                          },
                          activeColor: AppColors.accent,
                          activeTrackColor: AppColors.accent.withOpacity(0.3),
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          themeProvider.toggleTheme();
                        },
                      ),

                      SizedBox(height: menuItemSpacing),

                      // Change Password
                      _buildMenuItem(
                        context: context,
                        isDarkMode: isDarkMode,
                        isTablet: isTablet,
                        icon: Icons.lock_outline_rounded,
                        title: l10n.changePassword,
                        subtitle: l10n.get('change_password_subtitle'),
                        color: AppColors.statusWork,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          showChangePasswordBottomSheet(context);
                        },
                      ),

                      SizedBox(height: menuItemSpacing),

                      // Logout
                      _buildMenuItem(
                        context: context,
                        isDarkMode: isDarkMode,
                        isTablet: isTablet,
                        icon: Icons.logout_rounded,
                        title: l10n.logout,
                        subtitle: l10n.get('logout_subtitle'),
                        color: AppColors.error,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showLogoutConfirmation(context, authProvider, l10n, isDarkMode);
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: bottomSpacing),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required bool isDarkMode,
    required bool isTablet,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    // Use fixed pixels for tablet, ScreenUtil for phone
    final borderRadius = isTablet ? 16.0 : 16.r;
    final containerPadding = isTablet ? 16.0 : 16.w;
    final iconContainerPadding = isTablet ? 10.0 : 10.w;
    final iconBorderRadius = isTablet ? 12.0 : 12.r;
    final iconSize = isTablet ? 22.0 : 22.sp;
    final spacingWidth = isTablet ? 14.0 : 14.w;
    final titleFontSize = isTablet ? 15.0 : 15.sp;
    final subtitleFontSize = isTablet ? 12.0 : 12.sp;
    final spacingHeight = isTablet ? 2.0 : 2.h;
    final chevronSize = isTablet ? 24.0 : 24.sp;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.overlayDark
                : AppColors.overlayLight,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDarkMode
                  ? AppColors.surfaceAltDark.withOpacity(0.5)
                  : AppColors.mutedLight.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iconBorderRadius),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(width: spacingWidth),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: spacingHeight),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  size: chevronSize,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider, bool isDarkMode) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.language_rounded,
              color: AppColors.accent,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              l10n.language,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleProvider.supportedLocales.map((locale) {
            final isSelected = localeProvider.locale.languageCode == locale.languageCode;
            final languageName = LocaleProvider.languageNames[locale.languageCode] ?? locale.languageCode;

            return ListTile(
              onTap: () {
                HapticFeedback.lightImpact();
                localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.2)
                      : (isDarkMode ? AppColors.overlayDark : AppColors.overlayLight),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    locale.languageCode.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.accent : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ),
              title: Text(
                languageName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.accent
                      : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: AppColors.accent, size: 20.sp)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              tileColor: isSelected
                  ? AppColors.accent.withOpacity(0.1)
                  : Colors.transparent,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthProvider authProvider,
    AppLocalizations l10n,
    bool isDarkMode,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              l10n.logout,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.get('logout_confirmation'),
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save navigator before popping dialogs
              final navigator = Navigator.of(context, rootNavigator: true);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              await authProvider.logout();
              // Navigate to login screen and clear all routes
              navigator.pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

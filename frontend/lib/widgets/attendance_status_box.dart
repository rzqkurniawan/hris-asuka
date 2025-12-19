import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/mobile_attendance_service.dart';
import '../utils/page_transitions.dart';
import '../utils/responsive_utils.dart';
import '../screens/face_verification_screen.dart';

enum AttendanceStatus { work, late, absent, leave, notYet }

class AttendanceStatusBox extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onAttendanceComplete;

  const AttendanceStatusBox({
    super.key,
    this.isDarkMode = false,
    this.onAttendanceComplete,
  });

  @override
  State<AttendanceStatusBox> createState() => _AttendanceStatusBoxState();
}

class _AttendanceStatusBoxState extends State<AttendanceStatusBox> {
  final MobileAttendanceService _attendanceService = MobileAttendanceService();

  bool _isLoading = true;
  bool _isCheckingLocation = false;
  TodayAttendanceStatus? _todayStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final status = await _attendanceService.getTodayStatus();
      setState(() {
        _todayStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkLocationAndProceed(String checkType) async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isCheckingLocation = true;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('location_permission_denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('location_permission_permanent');
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('location_service_inactive');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final validation = await _attendanceService.validateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _isCheckingLocation = false;
      });

      if (!validation.isValid) {
        if (mounted) {
          _showLocationErrorDialog(validation);
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          SlideRightRoute(
            page: FaceVerificationScreen(
              checkType: checkType,
              latitude: position.latitude,
              longitude: position.longitude,
              locationId: validation.locationId!,
              locationName: validation.locationName!,
              onSuccess: () {
                _loadData();
                widget.onAttendanceComplete?.call();
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCheckingLocation = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final errorKey = e.toString().replaceAll('Exception: ', '');
        final errorMessage = l10n.get(errorKey);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage != errorKey ? errorMessage : e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationErrorDialog(LocationValidationResult validation) {
    final l10n = AppLocalizations.of(context);
    final isTablet = Responsive.isTablet(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 16 : 16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red[400], size: isTablet ? 28 : 28.sp),
            SizedBox(width: isTablet ? 10 : 10.w),
            Text(
              l10n.get('location_invalid'),
              style: TextStyle(
                fontSize: isTablet ? 18 : 18.sp,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              validation.message,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            if (validation.nearestLocation != null) ...[
              SizedBox(height: isTablet ? 12 : 12.h),
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 8 : 8.r),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.near_me, color: Colors.orange[700], size: isTablet ? 20 : 20.sp),
                    SizedBox(width: isTablet ? 8 : 8.w),
                    Expanded(
                      child: Text(
                        l10n.get('nearest_location_info')
                            .replaceAll('{location}', validation.nearestLocation!)
                            .replaceAll('{distance}', validation.distanceToNearest?.toStringAsFixed(0) ?? '0'),
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 13.sp,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  AttendanceStatus _getStatus() {
    if (_todayStatus == null) return AttendanceStatus.notYet;

    final checkIn = _todayStatus!.checkIn;

    if (checkIn == null) return AttendanceStatus.notYet;

    if (checkIn.time != null) {
      try {
        final parts = checkIn.time!.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1].split(' ')[0]);
        if (hour > 8 || (hour == 8 && minute > 30)) {
          return AttendanceStatus.late;
        }
      } catch (_) {}
    }

    return AttendanceStatus.work;
  }

  String _formatDisplayDate(String? dateString) {
    try {
      DateTime date;
      if (dateString != null) {
        date = DateTime.parse(dateString);
      } else {
        date = DateTime.now();
      }
      return DateFormat('EEEE, dd MMMM yyyy').format(date);
    } catch (e) {
      return DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTablet = Responsive.isTablet(context);

    // Use fixed pixels for tablet, ScreenUtil for phone
    final containerPadding = isTablet ? 24.0 : 20.w;
    final borderRadius = isTablet ? 20.0 : 20.r;
    final titleIconSize = isTablet ? 22.0 : 20.sp;
    final titleFontSize = isTablet ? 17.0 : 16.sp;
    final sectionSpacing = isTablet ? 15.0 : 15.h;
    final itemSpacing = isTablet ? 12.0 : 12.w;
    final calendarIconSize = isTablet ? 15.0 : 14.sp;
    final dateFontSize = isTablet ? 14.0 : 13.sp;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingState(isTablet)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row with Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: widget.isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          size: titleIconSize,
                        ),
                        SizedBox(width: isTablet ? 10 : 10.w),
                        Text(
                          l10n.get('attendance_status'),
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    _buildSmallStatusBadge(l10n, isTablet),
                  ],
                ),
                SizedBox(height: sectionSpacing),

                // Time Grid with Check In/Out buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeItemWithButton(
                        label: l10n.checkIn,
                        time: _todayStatus?.checkIn?.time ?? '--:--',
                        location: _todayStatus?.checkIn?.location,
                        canAction: _todayStatus?.canCheckIn ?? true,
                        onTap: () => _checkLocationAndProceed('check_in'),
                        isCheckIn: true,
                        l10n: l10n,
                        isTablet: isTablet,
                      ),
                    ),
                    SizedBox(width: itemSpacing),
                    Expanded(
                      child: _buildTimeItemWithButton(
                        label: l10n.checkOut,
                        time: _todayStatus?.checkOut?.time ?? '--:--',
                        location: _todayStatus?.checkOut?.location,
                        canAction: _todayStatus?.canCheckOut ?? false,
                        onTap: () => _checkLocationAndProceed('check_out'),
                        isCheckIn: false,
                        l10n: l10n,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sectionSpacing),

                // Today Date
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: calendarIconSize,
                        color: widget.isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      SizedBox(width: isTablet ? 5 : 5.w),
                      Text(
                        _formatDisplayDate(_todayStatus?.date),
                        style: TextStyle(
                          fontSize: dateFontSize,
                          color: widget.isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isTablet ? 30 : 30.h),
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildTimeItemWithButton({
    required String label,
    required String time,
    String? location,
    required bool canAction,
    required VoidCallback onTap,
    required bool isCheckIn,
    required AppLocalizations l10n,
    required bool isTablet,
  }) {
    final hasTime = time != '--:--';
    final statusColor = hasTime ? Colors.green : Colors.red;

    // Use fixed pixels for tablet
    final itemPadding = isTablet ? 14.0 : 12.w;
    final itemBorderRadius = isTablet ? 12.0 : 12.r;
    final labelFontSize = isTablet ? 12.0 : 11.sp;
    final statusIconSize = isTablet ? 18.0 : 16.sp;
    final timeFontSize = isTablet ? 20.0 : 18.sp;
    final locationFontSize = isTablet ? 11.0 : 10.sp;
    final buttonPadding = isTablet ? 12.0 : 10.h;
    final buttonIconSize = isTablet ? 18.0 : 16.sp;
    final buttonFontSize = isTablet ? 13.0 : 12.sp;

    return Container(
      padding: EdgeInsets.all(itemPadding),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(itemBorderRadius),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Icon(
                hasTime ? Icons.check_circle : Icons.cancel,
                size: statusIconSize,
                color: statusColor,
              ),
            ],
          ),
          SizedBox(height: isTablet ? 5 : 5.h),
          Text(
            time,
            style: TextStyle(
              fontSize: timeFontSize,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (location != null && hasTime) ...[
            SizedBox(height: isTablet ? 4 : 4.h),
            Text(
              location,
              style: TextStyle(
                fontSize: locationFontSize,
                color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: isTablet ? 8 : 8.h),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAction && !_isCheckingLocation ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: EdgeInsets.symmetric(vertical: buttonPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 8 : 8.r),
                ),
                elevation: 0,
              ),
              child: _isCheckingLocation
                  ? SizedBox(
                      width: isTablet ? 18 : 18.w,
                      height: isTablet ? 18 : 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCheckIn ? Icons.login : Icons.logout,
                          size: buttonIconSize,
                        ),
                        SizedBox(width: isTablet ? 4 : 4.w),
                        Text(
                          isCheckIn ? l10n.get('in_label') : l10n.get('out_label'),
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatusBadge(AppLocalizations l10n, bool isTablet) {
    final status = _getStatus();
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status) {
      case AttendanceStatus.work:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        statusText = l10n.get('status_work');
        icon = Icons.check_circle;
        break;
      case AttendanceStatus.late:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[700]!;
        statusText = l10n.get('status_late');
        icon = Icons.warning;
        break;
      case AttendanceStatus.absent:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        statusText = l10n.get('status_absent');
        icon = Icons.cancel;
        break;
      case AttendanceStatus.leave:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[700]!;
        statusText = l10n.get('status_leave');
        icon = Icons.event_available;
        break;
      case AttendanceStatus.notYet:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[600]!;
        statusText = l10n.get('status_not_yet');
        icon = Icons.schedule;
        break;
    }

    final badgeIconSize = isTablet ? 15.0 : 14.sp;
    final badgeFontSize = isTablet ? 12.0 : 11.sp;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 10.w,
        vertical: isTablet ? 5 : 5.h,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: badgeIconSize, color: textColor),
          SizedBox(width: isTablet ? 4 : 4.w),
          Text(
            statusText,
            style: TextStyle(
              fontSize: badgeFontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../services/mobile_attendance_service.dart';
import '../utils/page_transitions.dart';
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
  Position? _currentPosition;
  LocationValidationResult? _locationValidation;

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
      _locationValidation = null;
    });

    try {
      // Check location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen. Silakan aktifkan di pengaturan.');
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Silakan aktifkan GPS.');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);

      // Validate location against allowed locations
      final validation = await _attendanceService.validateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _locationValidation = validation;
        _isCheckingLocation = false;
      });

      if (!validation.isValid) {
        if (mounted) {
          _showLocationErrorDialog(validation);
        }
        return;
      }

      // Location is valid, proceed to face verification
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
                setState(() {
                  _currentPosition = null;
                  _locationValidation = null;
                });
                widget.onAttendanceComplete?.call();
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCheckingLocation = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationErrorDialog(LocationValidationResult validation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red[400], size: 28),
            const SizedBox(width: 10),
            Text(
              'Lokasi Tidak Valid',
              style: TextStyle(
                fontSize: 18,
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.near_me, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lokasi terdekat: ${validation.nearestLocation}\n(${validation.distanceToNearest?.toStringAsFixed(0)}m dari posisi Anda)',
                        style: TextStyle(
                          fontSize: 13,
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
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  AttendanceStatus _getStatus() {
    if (_todayStatus == null) return AttendanceStatus.notYet;

    final checkIn = _todayStatus!.checkIn;
    final checkOut = _todayStatus!.checkOut;

    if (checkIn == null) return AttendanceStatus.notYet;

    // Simple logic - can be enhanced based on actual business rules
    if (checkIn.time != null) {
      // Parse time and check if late (after 08:30)
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
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
          ? _buildLoadingState()
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
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Attendance Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    // Status Badge (small)
                    _buildSmallStatusBadge(),
                  ],
                ),
                const SizedBox(height: 15),

                // Time Grid with Check In/Out buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeItemWithButton(
                        label: 'Check In',
                        time: _todayStatus?.checkIn?.time ?? '--:--',
                        location: _todayStatus?.checkIn?.location,
                        canAction: _todayStatus?.canCheckIn ?? true,
                        actionColor: Colors.green,
                        onTap: () => _checkLocationAndProceed('check_in'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeItemWithButton(
                        label: 'Check Out',
                        time: _todayStatus?.checkOut?.time ?? '--:--',
                        location: _todayStatus?.checkOut?.location,
                        canAction: _todayStatus?.canCheckOut ?? false,
                        actionColor: Colors.blue,
                        onTap: () => _checkLocationAndProceed('check_out'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Today Date
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: widget.isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _todayStatus?.date ?? DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 13,
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

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildTimeItemWithButton({
    required String label,
    required String time,
    String? location,
    required bool canAction,
    required Color actionColor,
    required VoidCallback onTap,
  }) {
    final hasTime = time != '--:--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: hasTime ? actionColor : Colors.grey[400]!,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              if (hasTime)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: actionColor,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hasTime
                  ? actionColor
                  : (widget.isDarkMode ? Colors.grey[500] : Colors.grey[400]),
            ),
          ),
          if (location != null && hasTime) ...[
            const SizedBox(height: 4),
            Text(
              location,
              style: TextStyle(
                fontSize: 10,
                color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAction && !_isCheckingLocation ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isCheckingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          label == 'Check In' ? Icons.login : Icons.logout,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label == 'Check In' ? 'IN' : 'OUT',
                          style: const TextStyle(
                            fontSize: 12,
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

  Widget _buildSmallStatusBadge() {
    final status = _getStatus();
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status) {
      case AttendanceStatus.work:
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        statusText = 'WORK';
        icon = Icons.check_circle;
        break;
      case AttendanceStatus.late:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[700]!;
        statusText = 'LATE';
        icon = Icons.warning;
        break;
      case AttendanceStatus.absent:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        statusText = 'ABSENT';
        icon = Icons.cancel;
        break;
      case AttendanceStatus.leave:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[700]!;
        statusText = 'LEAVE';
        icon = Icons.event_available;
        break;
      case AttendanceStatus.notYet:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[600]!;
        statusText = 'NOT YET';
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

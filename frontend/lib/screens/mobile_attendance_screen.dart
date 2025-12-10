import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
import '../services/device_security_service.dart';
import '../services/mobile_attendance_service.dart';
import '../utils/page_transitions.dart';
import 'face_verification_screen.dart';

class MobileAttendanceScreen extends StatefulWidget {
  const MobileAttendanceScreen({super.key});

  @override
  State<MobileAttendanceScreen> createState() => _MobileAttendanceScreenState();
}

class _MobileAttendanceScreenState extends State<MobileAttendanceScreen> {
  final MobileAttendanceService _attendanceService = MobileAttendanceService();
  final DeviceSecurityService _securityService = DeviceSecurityService();

  bool _isLoading = true;
  bool _isCheckingLocation = false;
  String? _errorMessage;

  TodayAttendanceStatus? _todayStatus;
  List<AttendanceLocation> _locations = [];
  Position? _currentPosition;
  LocationValidationResult? _locationValidation;
  ExtendedLocationData? _securityData; // Anti-fake GPS data

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load today status and locations in parallel
      final results = await Future.wait([
        _attendanceService.getTodayStatus(),
        _attendanceService.getLocations(),
      ]);

      setState(() {
        _todayStatus = results[0] as TodayAttendanceStatus;
        _locations = results[1] as List<AttendanceLocation>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isCheckingLocation = true;
      _locationValidation = null;
      _securityData = null;
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
        throw Exception(
            'Izin lokasi ditolak secara permanen. Silakan aktifkan di pengaturan.');
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

      setState(() {
        _currentPosition = position;
      });

      // Get extended security data (anti-fake GPS)
      final securityData = await _securityService.getExtendedLocationData(position);

      // Check if mock location is detected
      if (_securityService.shouldBlockAttendance(securityData)) {
        throw Exception('Fake GPS terdeteksi! Absensi tidak dapat dilakukan.');
      }

      setState(() {
        _securityData = securityData;
      });

      // Validate location against allowed locations
      final validation = await _attendanceService.validateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _locationValidation = validation;
        _isCheckingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingLocation = false;
        _securityData = null;
      });

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

  void _proceedToFaceVerification(String checkType) {
    if (_currentPosition == null || _locationValidation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan verifikasi lokasi terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_locationValidation!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_locationValidation!.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      SlideRightRoute(
        page: FaceVerificationScreen(
          checkType: checkType,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          locationId: _locationValidation!.locationId!,
          locationName: _locationValidation!.locationName!,
          securityData: _securityData, // Pass anti-fake GPS data
          onSuccess: () {
            // Refresh data after successful attendance
            _loadData();
            // Reset location validation and security data
            setState(() {
              _currentPosition = null;
              _locationValidation = null;
              _securityData = null;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Absensi'),
        backgroundColor: isDarkMode ? AppColors.cardDark : AppColors.surfaceLight,
        foregroundColor: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(isDarkMode),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today Status Card
            _buildTodayStatusCard(isDarkMode),
            const SizedBox(height: 20),

            // Location Verification Card
            _buildLocationCard(isDarkMode),
            const SizedBox(height: 20),

            // Check In / Check Out Buttons
            _buildActionButtons(isDarkMode),
            const SizedBox(height: 20),

            // Available Locations Info
            _buildLocationsInfo(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(bool isDarkMode) {
    final status = _todayStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Hari Ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status?.date ?? '-',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.login,
                  label: 'Check In',
                  time: status?.checkIn?.time,
                  location: status?.checkIn?.location,
                  isVerified: status?.checkIn != null,
                  verifiedColor: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  isDarkMode: isDarkMode,
                  icon: Icons.logout,
                  label: 'Check Out',
                  time: status?.checkOut?.time,
                  location: status?.checkOut?.location,
                  isVerified: status?.checkOut != null,
                  verifiedColor: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    String? time,
    String? location,
    required bool isVerified,
    required Color verifiedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[800]
            : (isVerified ? verifiedColor.withOpacity(0.1) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? verifiedColor : Colors.grey[300]!,
          width: isVerified ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: isVerified ? verifiedColor : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time ?? '--:--',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isVerified ? verifiedColor : Colors.grey,
            ),
          ),
          if (location != null) ...[
            const SizedBox(height: 4),
            Text(
              location,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Verifikasi Lokasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location Status
          if (_locationValidation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _locationValidation!.isValid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _locationValidation!.isValid
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _locationValidation!.isValid
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: _locationValidation!.isValid
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locationValidation!.isValid
                              ? 'Lokasi Valid'
                              : 'Lokasi Tidak Valid',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _locationValidation!.isValid
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationValidation!.isValid
                              ? '${_locationValidation!.locationName} (${_locationValidation!.distanceMeters?.toStringAsFixed(0)}m)'
                              : _locationValidation!.nearestLocation != null
                                  ? 'Terdekat: ${_locationValidation!.nearestLocation} (${_locationValidation!.distanceToNearest?.toStringAsFixed(0)}m)'
                                  : 'Tidak ada lokasi dalam radius',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Check Location Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCheckingLocation ? null : _getCurrentLocation,
              icon: _isCheckingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.overlayLight,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_isCheckingLocation
                  ? 'Memeriksa Lokasi...'
                  : _locationValidation != null
                      ? 'Perbarui Lokasi'
                      : 'Cek Lokasi Saya'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.overlayLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (_currentPosition != null) ...[
            const SizedBox(height: 8),
            Text(
              'Koordinat: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    final canCheckIn = _todayStatus?.canCheckIn ?? false;
    final canCheckOut = _todayStatus?.canCheckOut ?? false;
    final locationValid = _locationValidation?.isValid ?? false;

    return Row(
      children: [
        // Check In Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canCheckIn && locationValid
                ? () => _proceedToFaceVerification('check_in')
                : null,
            icon: const Icon(Icons.login, size: 28),
            label: const Text(
              'CHECK IN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusWork,
              foregroundColor: AppColors.overlayLight,
              disabledBackgroundColor: AppColors.borderLight,
              disabledForegroundColor: AppColors.textSecondaryLight,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Check Out Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canCheckOut && locationValid
                ? () => _proceedToFaceVerification('check_out')
                : null,
            icon: const Icon(Icons.logout, size: 28),
            label: const Text(
              'CHECK OUT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.overlayLight,
              disabledBackgroundColor: AppColors.borderLight,
              disabledForegroundColor: AppColors.textSecondaryLight,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsInfo(bool isDarkMode) {
    if (_locations.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi Absensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._locations.map((loc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (loc.address != null)
                            Text(
                              loc.address!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${loc.radiusMeters}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../services/mobile_attendance_service.dart';
import '../services/device_security_service.dart';

class FaceVerificationScreen extends StatefulWidget {
  final String checkType;
  final double latitude;
  final double longitude;
  final int locationId;
  final String locationName;
  final VoidCallback onSuccess;
  final ExtendedLocationData? securityData; // Anti-fake GPS data

  const FaceVerificationScreen({
    super.key,
    required this.checkType,
    required this.latitude,
    required this.longitude,
    required this.locationId,
    required this.locationName,
    required this.onSuccess,
    this.securityData,
  });

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  final MobileAttendanceService _attendanceService = MobileAttendanceService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isSubmitting = false;
  bool _faceDetected = false;

  FaceDetector? _faceDetector;
  String? _avatarUrl;
  String? _errorMessage;
  double _faceConfidence = 0.0;

  XFile? _capturedImage;
  String? _capturedImageBase64;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadEmployeeAvatar();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'Tidak ada kamera yang tersedia';
        });
        return;
      }

      // Use front camera for face verification
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menginisialisasi kamera: ${e.toString()}';
      });
    }
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: false,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _loadEmployeeAvatar() async {
    try {
      final avatarResponse = await _attendanceService.getEmployeeAvatar();
      setState(() {
        _avatarUrl = avatarResponse.avatarUrl;
      });
    } catch (e) {
      // Avatar not found is okay, we can still proceed
      print('Avatar not found: $e');
    }
  }

  Future<void> _captureAndVerify() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      // Read image bytes for face detection
      final inputImage = InputImage.fromFilePath(imageFile.path);

      // Detect faces
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _isProcessing = false;
          _faceDetected = false;
          _errorMessage = 'Wajah tidak terdeteksi. Pastikan wajah Anda terlihat jelas.';
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Terdeteksi lebih dari satu wajah. Pastikan hanya ada satu wajah.';
        });
        return;
      }

      final face = faces.first;

      // Calculate face confidence based on detection quality
      double confidence = _calculateFaceConfidence(face);

      // Read image bytes and convert to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _capturedImage = imageFile;
        _capturedImageBase64 = base64Image;
        _faceDetected = true;
        _faceConfidence = confidence;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Gagal memverifikasi wajah: ${e.toString()}';
      });
    }
  }

  double _calculateFaceConfidence(Face face) {
    double confidence = 85.0; // Base confidence

    // Adjust based on head rotation (prefer straight face)
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;

    if (headEulerAngleY.abs() < 10 && headEulerAngleZ.abs() < 10) {
      confidence += 5; // Bonus for straight face
    } else if (headEulerAngleY.abs() > 30 || headEulerAngleZ.abs() > 30) {
      confidence -= 10; // Penalty for tilted face
    }

    // Adjust based on eye open probability
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;

    if (leftEyeOpen > 0.8 && rightEyeOpen > 0.8) {
      confidence += 5; // Both eyes open
    } else if (leftEyeOpen < 0.3 || rightEyeOpen < 0.3) {
      confidence -= 10; // Eyes closed
    }

    // Adjust based on smiling probability (optional, just for quality)
    final smilingProb = face.smilingProbability ?? 0.5;
    if (smilingProb > 0.8 || smilingProb < 0.2) {
      // Extreme expressions might affect recognition
      confidence -= 3;
    }

    // Clamp confidence between 0 and 100
    return confidence.clamp(0.0, 100.0);
  }

  Future<void> _submitAttendance() async {
    if (_capturedImageBase64 == null || !_faceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ambil foto wajah terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_faceConfidence < 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kualitas foto kurang baik. Silakan foto ulang.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get device info
      String? deviceInfo;
      try {
        final deviceInfoPlugin = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfoPlugin.androidInfo;
          deviceInfo = '${androidInfo.brand} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfoPlugin.iosInfo;
          deviceInfo = '${iosInfo.name} ${iosInfo.model}';
        }
      } catch (e) {
        // Device info is optional
      }

      final result = await _attendanceService.submitAttendance(
        checkType: widget.checkType,
        latitude: widget.latitude,
        longitude: widget.longitude,
        faceImageBase64: _capturedImageBase64!,
        faceConfidence: _faceConfidence,
        deviceInfo: deviceInfo,
        securityData: widget.securityData, // Pass anti-fake GPS data
      );

      setState(() {
        _isSubmitting = false;
      });

      if (result.success) {
        if (mounted) {
          HapticFeedback.heavyImpact();
          _showSuccessDialog(result);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan absensi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(AttendanceSubmitResult result) {
    final isCheckIn = widget.checkType == 'check_in';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCheckIn
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCheckIn ? Icons.login : Icons.logout,
                size: 48,
                color: isCheckIn ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCheckIn ? 'Check-In Berhasil!' : 'Check-Out Berhasil!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Waktu: ${result.time ?? '-'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lokasi: ${result.location ?? '-'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to attendance screen
                  widget.onSuccess(); // Trigger refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckIn ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _capturedImageBase64 = null;
      _faceDetected = false;
      _faceConfidence = 0.0;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isCheckIn = widget.checkType == 'check_in';

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isCheckIn ? 'Verifikasi Check-In' : 'Verifikasi Check-Out'),
        backgroundColor: isDarkMode ? AppColors.cardDark : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_errorMessage != null && !_isCameraInitialized) {
      return _buildErrorWidget();
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menginisialisasi kamera...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Location Info
            _buildLocationInfo(isDarkMode),
            const SizedBox(height: 20),

            // Camera Preview or Captured Image
            _buildCameraSection(isDarkMode),
            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(isDarkMode),
          ],
        ),
      ),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lokasi Terverifikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  widget.locationName,
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
    );
  }

  Widget _buildCameraSection(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camera Preview or Captured Image
            AspectRatio(
              aspectRatio: 3 / 4,
              child: _capturedImage != null
                  ? Image.file(
                      File(_capturedImage!.path),
                      fit: BoxFit.cover,
                    )
                  : CameraPreview(_cameraController!),
            ),

            // Face Overlay Guide
            if (_capturedImage == null)
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceOverlayPainter(),
                ),
              ),

            // Face Detection Status
            if (_capturedImage != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _faceDetected
                        ? Colors.green.withOpacity(0.9)
                        : Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _faceDetected ? Icons.face : Icons.face_retouching_off,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _faceDetected
                            ? 'Wajah Terdeteksi (${_faceConfidence.toStringAsFixed(0)}%)'
                            : 'Wajah Tidak Terdeteksi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Processing Indicator
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Memverifikasi wajah...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    final isCheckIn = widget.checkType == 'check_in';

    if (_capturedImage == null) {
      // Capture Button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : _captureAndVerify,
          icon: const Icon(Icons.camera_alt, size: 28),
          label: const Text(
            'AMBIL FOTO',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    // Retake and Submit Buttons
    return Column(
      children: [
        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting || _faceConfidence < 80
                ? null
                : _submitAttendance,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isCheckIn ? Icons.login : Icons.logout, size: 28),
            label: Text(
              _isSubmitting
                  ? 'Menyimpan...'
                  : isCheckIn
                      ? 'KONFIRMASI CHECK-IN'
                      : 'KONFIRMASI CHECK-OUT',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCheckIn ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Retake Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _retakePhoto,
            icon: const Icon(Icons.refresh),
            label: const Text('FOTO ULANG'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              side: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Face Overlay Guide
class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2 - 30);
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.25;

    // Draw oval guide
    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(rect, paint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final bracketLength = 30.0;
    final padding = 20.0;

    // Top-left
    canvas.drawLine(
      Offset(center.dx - radiusX - padding, center.dy - radiusY - padding),
      Offset(center.dx - radiusX - padding + bracketLength, center.dy - radiusY - padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radiusX - padding, center.dy - radiusY - padding),
      Offset(center.dx - radiusX - padding, center.dy - radiusY - padding + bracketLength),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy - radiusY - padding),
      Offset(center.dx + radiusX + padding - bracketLength, center.dy - radiusY - padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy - radiusY - padding),
      Offset(center.dx + radiusX + padding, center.dy - radiusY - padding + bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(center.dx - radiusX - padding, center.dy + radiusY + padding),
      Offset(center.dx - radiusX - padding + bracketLength, center.dy + radiusY + padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radiusX - padding, center.dy + radiusY + padding),
      Offset(center.dx - radiusX - padding, center.dy + radiusY + padding - bracketLength),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy + radiusY + padding),
      Offset(center.dx + radiusX + padding - bracketLength, center.dy + radiusY + padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy + radiusY + padding),
      Offset(center.dx + radiusX + padding, center.dy + radiusY + padding - bracketLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

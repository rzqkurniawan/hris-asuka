import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image/image.dart' as img;
import '../constants/app_colors.dart';
import '../services/mobile_attendance_service.dart';
import '../services/device_security_service.dart';
import '../l10n/app_localizations.dart';

/// Random challenge types for anti-spoofing liveness detection
enum LivenessChallenge {
  blink,      // Kedipkan mata
  turnLeft,   // Putar kepala ke kiri
  turnRight,  // Putar kepala ke kanan
  smile,      // Tersenyum
}

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

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with WidgetsBindingObserver {
  final MobileAttendanceService _attendanceService = MobileAttendanceService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isSubmitting = false;
  bool _faceDetected = false;
  bool _isComparingFace = false; // Server-side face comparison in progress

  FaceDetector? _faceDetector;
  String? _avatarUrl;
  String? _errorMessage;
  double _faceConfidence = 0.0;

  XFile? _capturedImage;
  String? _capturedImageBase64;

  // Server-side face comparison result
  FaceComparisonResult? _serverFaceResult;

  // ===== LIVENESS DETECTION STATE =====
  bool _isLivenessMode = false;
  bool _livenessVerified = false;
  bool _isStreamingFaces = false;

  // Random challenge system for anti-video-replay attack
  List<LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  static const int _totalChallenges = 2; // Number of random challenges to complete

  // Eye blink detection
  bool _eyesWereClosed = false;
  static const double _eyeClosedThreshold = 0.3;
  static const double _eyeOpenThreshold = 0.7;
  int _requiredBlinkCount = 1; // Random 1-3 blinks required
  int _currentBlinkCount = 0; // Current blink count

  // Head turn detection
  double? _baselineHeadAngleY;
  static const double _headTurnThreshold = 30.0; // degrees to turn (increased for more noticeable turn)

  // Smile detection
  static const double _smileThreshold = 0.7;

  // Challenge completion tracking
  bool _currentChallengeCompleted = false;
  String _livenessInstruction = '';
  Timer? _livenessTimer;
  int _livenessTimeRemaining = 20;
  static const int _livenessTimeoutSeconds = 20; // More time for screen flash + challenges

  // Flag to prevent setState after dispose
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadEmployeeAvatar();
    _initializeFaceDetector();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopLivenessDetection();
    } else if (state == AppLifecycleState.resumed) {
      // Camera will be re-initialized when returning
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'no_camera_available'; // Will be localized in UI
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
        // Use YUV420 for Android (needed for image streaming/ML Kit)
        // Use BGRA8888 for iOS
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
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

  Future<InputImage?> _createInputImageFromFile(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Decode image to get dimensions
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        return InputImage.fromFilePath(imageFile.path);
      }

      // For iOS front camera, we need to handle orientation
      if (Platform.isIOS) {
        // Use bytes with metadata for better iOS compatibility
        final inputImageData = InputImageMetadata(
          size: Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: decodedImage.width,
        );

        // Try file path first, then fallback to bytes if detection fails
        return InputImage.fromFilePath(imageFile.path);
      }

      return InputImage.fromFilePath(imageFile.path);
    } catch (e) {
      print('Error creating InputImage: $e');
      return InputImage.fromFilePath(imageFile.path);
    }
  }

  Future<List<Face>> _detectFacesFromFile(XFile imageFile) async {
    try {
      // First try with file path
      var inputImage = InputImage.fromFilePath(imageFile.path);
      var faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty && Platform.isIOS) {
        // On iOS, try with processed bytes if file path fails
        final bytes = await imageFile.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        if (decodedImage != null) {
          // Fix orientation for front camera (mirror horizontal)
          var processedImage = img.flipHorizontal(decodedImage);

          // Encode back to JPEG
          final processedBytes = Uint8List.fromList(img.encodeJpg(processedImage));

          // Save to temp file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/face_detect_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(processedBytes);

          inputImage = InputImage.fromFilePath(tempFile.path);
          faces = await _faceDetector!.processImage(inputImage);

          // Clean up temp file
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      }

      return faces;
    } catch (e) {
      print('Error detecting faces: $e');
      return [];
    }
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
        livenessVerified: _livenessVerified, // Anti-spoofing liveness check
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
      // Reset liveness state
      _livenessVerified = false;
      _challenges.clear();
      _currentChallengeIndex = 0;
      _currentChallengeCompleted = false;
      _eyesWereClosed = false;
      _baselineHeadAngleY = null;
      // Reset server face comparison result
      _serverFaceResult = null;
      _isComparingFace = false;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _livenessTimer?.cancel();
    _stopFaceStreaming();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  // ===== LIVENESS DETECTION METHODS =====

  /// Generate random challenges for liveness detection
  List<LivenessChallenge> _generateRandomChallenges() {
    final random = Random();
    final allChallenges = List<LivenessChallenge>.from(LivenessChallenge.values);
    allChallenges.shuffle(random);
    return allChallenges.take(_totalChallenges).toList();
  }

  /// Get instruction text for a challenge
  String _getChallengeInstruction(LivenessChallenge challenge) {
    switch (challenge) {
      case LivenessChallenge.blink:
        if (_requiredBlinkCount > 1) {
          return 'Kedipkan mata $_currentBlinkCount/$_requiredBlinkCount kali';
        }
        return 'Kedipkan mata Anda';
      case LivenessChallenge.turnLeft:
        return 'Putar kepala ke KIRI';
      case LivenessChallenge.turnRight:
        return 'Putar kepala ke KANAN';
      case LivenessChallenge.smile:
        return 'Tersenyum';
    }
  }

  /// Get icon for a challenge
  IconData _getChallengeIcon(LivenessChallenge challenge) {
    switch (challenge) {
      case LivenessChallenge.blink:
        return Icons.remove_red_eye;
      case LivenessChallenge.turnLeft:
        return Icons.turn_left;
      case LivenessChallenge.turnRight:
        return Icons.turn_right;
      case LivenessChallenge.smile:
        return Icons.sentiment_satisfied_alt;
    }
  }

  /// Get simple instruction text for a challenge
  String _getSimpleInstruction(LivenessChallenge challenge) {
    switch (challenge) {
      case LivenessChallenge.blink:
        return _requiredBlinkCount > 1
            ? 'Kedipkan Mata ${_currentBlinkCount}/${_requiredBlinkCount}'
            : 'Kedipkan Mata';
      case LivenessChallenge.turnLeft:
        return 'Putar ke KIRI';
      case LivenessChallenge.turnRight:
        return 'Putar ke KANAN';
      case LivenessChallenge.smile:
        return 'Tersenyum';
    }
  }

  /// Build animated icon only (without text) for center display
  Widget _buildAnimatedIconOnly(LivenessChallenge challenge) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        // This creates the repeating animation effect
        if (mounted) setState(() {});
      },
      child: _buildChallengeIconContainer(challenge),
    );
  }

  Widget _buildChallengeIconContainer(LivenessChallenge challenge) {
    IconData icon;
    switch (challenge) {
      case LivenessChallenge.blink:
        icon = Icons.visibility;
        break;
      case LivenessChallenge.turnLeft:
        icon = Icons.arrow_back_rounded;
        break;
      case LivenessChallenge.turnRight:
        icon = Icons.arrow_forward_rounded;
        break;
      case LivenessChallenge.smile:
        icon = Icons.sentiment_very_satisfied;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(40),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(50),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: AppColors.accent,
        size: 50,
      ),
    );
  }

  void _startLivenessDetection() {
    if (_isLivenessMode) return;

    // Generate random challenges
    final challenges = _generateRandomChallenges();
    final random = Random();
    // Random blink count between 1-3
    final blinkCount = random.nextInt(3) + 1;

    setState(() {
      _isLivenessMode = true;
      _livenessVerified = false;
      _challenges = challenges;
      _currentChallengeIndex = 0;
      _currentChallengeCompleted = false;
      _eyesWereClosed = false;
      _baselineHeadAngleY = null;
      _livenessTimeRemaining = _livenessTimeoutSeconds;
      _errorMessage = null;
      _requiredBlinkCount = blinkCount;
      _currentBlinkCount = 0;
      _livenessInstruction = _getChallengeInstruction(challenges.first);
    });

    // Start timeout timer
    _livenessTimer?.cancel();
    _livenessTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }

      setState(() {
        _livenessTimeRemaining--;
      });

      if (_livenessTimeRemaining <= 0) {
        timer.cancel();
        _onLivenessTimeout();
      }
    });

    // Start streaming face detection
    _startFaceStreaming();
  }

  void _stopLivenessDetection() {
    _livenessTimer?.cancel();
    _stopFaceStreaming();
    if (mounted && !_isDisposed) {
      setState(() {
        _isLivenessMode = false;
        _livenessVerified = false;
        _isStreamingFaces = false;
        _challenges.clear();
        _currentChallengeIndex = 0;
        _currentChallengeCompleted = false;
        _eyesWereClosed = false;
        _baselineHeadAngleY = null;
        _currentBlinkCount = 0;
        _requiredBlinkCount = 1;
      });
    }
  }

  void _onLivenessTimeout() {
    _stopLivenessDetection();
    if (mounted && !_isDisposed) {
      setState(() {
        _errorMessage =
            'Verifikasi gagal: Waktu habis. Pastikan Anda mengedipkan mata dan menggerakkan kepala sedikit.';
        _isLivenessMode = false;
      });
    }
  }

  Future<void> _startFaceStreaming() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isStreamingFaces) {
      return;
    }

    setState(() {
      _isStreamingFaces = true;
    });

    try {
      await _cameraController!.startImageStream((CameraImage image) {
        if (!_isLivenessMode || !_isStreamingFaces || _livenessVerified) {
          return;
        }
        _processFrameForLiveness(image);
      });
    } catch (e) {
      // Error starting image stream - silently handle
      setState(() {
        _isStreamingFaces = false;
      });
    }
  }

  Future<void> _stopFaceStreaming() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !_isStreamingFaces) {
      return;
    }

    try {
      await _cameraController!.stopImageStream();
    } catch (e) {
      // Error stopping image stream - silently handle
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isStreamingFaces = false;
      });
    }
  }

  bool _isProcessingFrame = false;

  Future<void> _processFrameForLiveness(CameraImage image) async {
    if (_isProcessingFrame || !mounted || _isDisposed) return;
    _isProcessingFrame = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (!mounted || _isDisposed || !_isLivenessMode) {
        _isProcessingFrame = false;
        return;
      }

      if (faces.isEmpty) {
        _isProcessingFrame = false;
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _errorMessage = 'Terdeteksi lebih dari satu wajah';
        });
        _isProcessingFrame = false;
        return;
      }

      final face = faces.first;
      _analyzeFaceForLiveness(face);
    } catch (e) {
      // Error processing frame - silently handle
    }

    _isProcessingFrame = false;
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Determine rotation based on platform and sensor orientation
      InputImageRotation imageRotation;
      if (Platform.isAndroid) {
        // On Android front camera, we need to adjust rotation
        final sensorOrientation = camera.sensorOrientation;
        switch (sensorOrientation) {
          case 0:
            imageRotation = InputImageRotation.rotation0deg;
            break;
          case 90:
            imageRotation = InputImageRotation.rotation90deg;
            break;
          case 180:
            imageRotation = InputImageRotation.rotation180deg;
            break;
          case 270:
            imageRotation = InputImageRotation.rotation270deg;
            break;
          default:
            imageRotation = InputImageRotation.rotation0deg;
        }
      } else {
        final rotation = InputImageRotationValue.fromRawValue(
          camera.sensorOrientation,
        );
        if (rotation == null) return null;
        imageRotation = rotation;
      }

      if (image.planes.isEmpty) return null;

      // Handle different image formats
      if (Platform.isAndroid) {
        // Android uses YUV420 format - convert to NV21 for ML Kit
        final nv21Bytes = _convertYUV420ToNV21(image);
        if (nv21Bytes == null) return null;

        return InputImage.fromBytes(
          bytes: nv21Bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: imageRotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      } else {
        // iOS uses BGRA8888 format
        final format = InputImageFormatValue.fromRawValue(image.format.raw);
        if (format == null) return null;

        final plane = image.planes.first;
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: imageRotation,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      }
    } catch (e) {
      return null;
    }
  }

  /// Convert YUV420 camera image to NV21 format for ML Kit on Android
  Uint8List? _convertYUV420ToNV21(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final int ySize = width * height;
      final int uvSize = width * height ~/ 2;

      final nv21 = Uint8List(ySize + uvSize);

      // Copy Y plane
      final yPlane = image.planes[0];
      int yIndex = 0;
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          nv21[yIndex++] = yPlane.bytes[row * yPlane.bytesPerRow + col];
        }
      }

      // Interleave V and U planes into NV21 format (VUVU...)
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final int uvWidth = width ~/ 2;
      final int uvHeight = height ~/ 2;

      int uvIndex = ySize;
      for (int row = 0; row < uvHeight; row++) {
        for (int col = 0; col < uvWidth; col++) {
          final int uOffset = row * uPlane.bytesPerRow + col * uPlane.bytesPerPixel!;
          final int vOffset = row * vPlane.bytesPerRow + col * vPlane.bytesPerPixel!;

          nv21[uvIndex++] = vPlane.bytes[vOffset]; // V first in NV21
          nv21[uvIndex++] = uPlane.bytes[uOffset]; // U second
        }
      }

      return nv21;
    } catch (e) {
      return null;
    }
  }

  void _analyzeFaceForLiveness(Face face) {
    if (!mounted || _livenessVerified || _challenges.isEmpty) return;

    final currentChallenge = _challenges[_currentChallengeIndex];

    // Get face data
    final leftEyeProb = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeProb = face.rightEyeOpenProbability ?? 0.5;
    final headAngleY = face.headEulerAngleY ?? 0.0;
    final smileProb = face.smilingProbability ?? 0.0;

    // Set baseline head angle on first frame
    if (_baselineHeadAngleY == null) {
      _baselineHeadAngleY = headAngleY;
    }

    bool challengeCompleted = false;

    // Check current challenge
    switch (currentChallenge) {
      case LivenessChallenge.blink:
        // Detect eye blink (closed -> open cycle)
        bool eyesAreClosed =
            leftEyeProb < _eyeClosedThreshold && rightEyeProb < _eyeClosedThreshold;
        bool eyesAreOpen =
            leftEyeProb > _eyeOpenThreshold && rightEyeProb > _eyeOpenThreshold;

        if (eyesAreClosed && !_eyesWereClosed) {
          _eyesWereClosed = true;
        } else if (eyesAreOpen && _eyesWereClosed) {
          // One blink completed
          _eyesWereClosed = false;
          _currentBlinkCount++;

          // Update instruction to show progress
          if (_currentBlinkCount < _requiredBlinkCount) {
            setState(() {
              _livenessInstruction = _getChallengeInstruction(currentChallenge);
            });
            // Light haptic for each blink
            if (mounted) {
              HapticFeedback.lightImpact();
            }
          } else {
            // All required blinks completed
            challengeCompleted = true;
          }
        }
        break;

      case LivenessChallenge.turnLeft:
        // Detect head turn to the left (negative Y angle from user perspective)
        // Note: Front camera mirrors, so we check positive angle
        final angleFromBaseline = headAngleY - (_baselineHeadAngleY ?? 0);
        if (angleFromBaseline > _headTurnThreshold) {
          challengeCompleted = true;
        }
        break;

      case LivenessChallenge.turnRight:
        // Detect head turn to the right (positive Y angle from user perspective)
        // Note: Front camera mirrors, so we check negative angle
        final angleFromBaseline = headAngleY - (_baselineHeadAngleY ?? 0);
        if (angleFromBaseline < -_headTurnThreshold) {
          challengeCompleted = true;
        }
        break;

      case LivenessChallenge.smile:
        // Detect smile
        if (smileProb > _smileThreshold) {
          challengeCompleted = true;
        }
        break;
    }

    // Handle challenge completion
    if (challengeCompleted && !_currentChallengeCompleted) {
      _currentChallengeCompleted = true;

      if (mounted) {
        HapticFeedback.mediumImpact();
      }

      // Move to next challenge or complete verification
      if (_currentChallengeIndex < _challenges.length - 1) {
        // Move to next challenge
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isDisposed && _isLivenessMode) {
            // Generate new random blink count for next challenge if it's a blink
            final nextChallenge = _challenges[_currentChallengeIndex + 1];
            int newBlinkCount = _requiredBlinkCount;
            if (nextChallenge == LivenessChallenge.blink) {
              newBlinkCount = Random().nextInt(3) + 1;
            }

            setState(() {
              _currentChallengeIndex++;
              _currentChallengeCompleted = false;
              _eyesWereClosed = false;
              _baselineHeadAngleY = null; // Reset baseline for next challenge
              _currentBlinkCount = 0; // Reset blink count for next challenge
              _requiredBlinkCount = newBlinkCount;
              _livenessInstruction =
                  _getChallengeInstruction(_challenges[_currentChallengeIndex]);
            });
          }
        });
      } else {
        // All challenges completed - verification successful
        _livenessVerified = true;
        _stopFaceStreaming();
        _livenessTimer?.cancel();

        if (mounted) {
          HapticFeedback.heavyImpact();
          setState(() {
            _livenessInstruction = 'Verifikasi berhasil! Tekan tombol AMBIL FOTO';
          });
        }
      }
    }
  }

  Future<void> _captureAfterLiveness() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _isLivenessMode = false;
    });

    try {
      // Ensure stream is stopped before taking picture
      if (_isStreamingFaces) {
        await _stopFaceStreaming();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final XFile imageFile = await _cameraController!.takePicture();

      // Use helper method for better iOS compatibility
      final List<Face> faces = await _detectFacesFromFile(imageFile);

      if (faces.isEmpty) {
        setState(() {
          _isProcessing = false;
          _faceDetected = false;
          _livenessVerified = false;
          _errorMessage =
              'Wajah tidak terdeteksi saat pengambilan foto. Silakan coba lagi.';
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _isProcessing = false;
          _livenessVerified = false;
          _errorMessage =
              'Terdeteksi lebih dari satu wajah. Pastikan hanya ada satu wajah.';
        });
        return;
      }

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _capturedImage = imageFile;
        _capturedImageBase64 = base64Image;
        _faceDetected = true;
        _isProcessing = false;
        _isComparingFace = true; // Start server comparison
      });

      // Perform server-side face comparison
      await _compareFaceWithServer(base64Image);

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _livenessVerified = false;
        _errorMessage = 'Gagal mengambil foto: ${e.toString()}';
      });
    }
  }

  /// Compare captured face with employee's stored photo on server
  Future<void> _compareFaceWithServer(String base64Image) async {
    try {
      final result = await _attendanceService.compareFace(
        faceImageBase64: base64Image,
      );

      if (!mounted) return;

      setState(() {
        _serverFaceResult = result;
        _faceConfidence = result.confidence;
        _isComparingFace = false;
      });

      // Show feedback based on result
      if (!result.success) {
        setState(() {
          _errorMessage = result.message;
        });
      } else if (!result.match) {
        // Face doesn't match but comparison was successful
        if (mounted) {
          HapticFeedback.heavyImpact();
        }
      } else {
        // Face matches!
        if (mounted) {
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isComparingFace = false;
        _errorMessage = 'Gagal memverifikasi wajah: ${e.toString()}';
      });
    }
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

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              // Location Info
              _buildLocationInfo(isDarkMode),
              const SizedBox(height: 16),

              // Camera Preview or Captured Image
              _buildCameraSection(isDarkMode),
              const SizedBox(height: 12),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
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

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(isDarkMode),
            ],
          ),
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
            if (_capturedImage == null && !_isLivenessMode)
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceOverlayPainter(),
                ),
              ),

            // Liveness Detection - Face Guide Oval (same size as initial guide)
            if (_isLivenessMode && _capturedImage == null)
              Positioned.fill(
                child: CustomPaint(
                  painter: LivenessFaceGuidePainter(
                    isVerified: _livenessVerified,
                    blinkProgress: _challenges.isEmpty
                        ? 0.0
                        : (_currentChallengeIndex + (_currentChallengeCompleted ? 1 : 0)) /
                            _challenges.length,
                  ),
                ),
              ),

            // Liveness Detection - Border
            if (_isLivenessMode && _capturedImage == null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _livenessVerified ? Colors.green : Colors.orange,
                      width: 4,
                    ),
                  ),
                ),
              ),

            // Liveness Detection - Challenge Progress at top
            if (_isLivenessMode && _capturedImage == null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(178),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _challenges.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _buildChallengeProgressItem(i),
                      ],
                    ],
                  ),
                ),
              ),

            // Liveness Detection - Toast Style Instruction with Timer (Bottom)
            if (_isLivenessMode && _capturedImage == null && !_livenessVerified && _challenges.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      )),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey('toast_${_currentChallengeIndex}_$_currentBlinkCount'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getChallengeIcon(_challenges[_currentChallengeIndex]),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getSimpleInstruction(_challenges[_currentChallengeIndex]),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Blink progress dots (inline)
                              if (_challenges[_currentChallengeIndex] == LivenessChallenge.blink && _requiredBlinkCount > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(_requiredBlinkCount, (index) {
                                      final isCompleted = index < _currentBlinkCount;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 5),
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCompleted
                                                ? AppColors.success
                                                : Colors.white.withAlpha(50),
                                            border: Border.all(
                                              color: isCompleted
                                                  ? AppColors.success
                                                  : Colors.white.withAlpha(100),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Timer on the right
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _livenessTimeRemaining <= 5
                                ? Colors.red.withAlpha(50)
                                : Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _livenessTimeRemaining <= 5
                                  ? Colors.red.withAlpha(150)
                                  : Colors.white.withAlpha(50),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: _livenessTimeRemaining <= 5
                                    ? Colors.red[300]
                                    : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_livenessTimeRemaining}s',
                                style: TextStyle(
                                  color: _livenessTimeRemaining <= 5
                                      ? Colors.red[300]
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Liveness Verified - Toast Style Success (Bottom)
            if (_isLivenessMode && _capturedImage == null && _livenessVerified)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withAlpha(100),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Verifikasi Berhasil!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Silakan ambil foto',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Face Detection Status (after capture) - Shows server-side comparison result
            if (_capturedImage != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _isComparingFace
                    // Loading state - comparing with server
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Memverifikasi dengan foto karyawan...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    // Server comparison result
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _serverFaceResult?.match == true
                              ? Colors.green.withOpacity(0.9)
                              : _serverFaceResult != null
                                  ? Colors.red.withOpacity(0.9)
                                  : Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _serverFaceResult?.match == true
                                  ? Icons.verified_user
                                  : _serverFaceResult != null
                                      ? Icons.cancel
                                      : Icons.face,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _serverFaceResult?.match == true
                                    ? 'Wajah Cocok! (${_faceConfidence.toStringAsFixed(1)}%)'
                                    : _serverFaceResult != null
                                        ? 'Wajah Tidak Cocok (${_faceConfidence.toStringAsFixed(1)}%)'
                                        : 'Menunggu verifikasi...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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

  /// Build a progress indicator for each challenge
  Widget _buildChallengeProgressItem(int index) {
    final isCompleted = index < _currentChallengeIndex ||
        (index == _currentChallengeIndex && _currentChallengeCompleted);
    final isCurrent = index == _currentChallengeIndex && !_currentChallengeCompleted;
    final challenge = _challenges[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withAlpha(204)
            : isCurrent
                ? Colors.orange.withAlpha(204)
                : Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: isCurrent
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : _getChallengeIcon(challenge),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    final isCheckIn = widget.checkType == 'check_in';

    // Liveness verified - show capture button
    if (_livenessVerified && _capturedImage == null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAfterLiveness,
              icon: const Icon(Icons.camera_alt, size: 28),
              label: Text(
                _isProcessing ? 'MEMPROSES...' : 'AMBIL FOTO',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _stopLivenessDetection,
              icon: const Icon(Icons.refresh),
              label: const Text('ULANGI VERIFIKASI'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
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

    // During liveness mode (not yet verified) - show cancel button
    if (_isLivenessMode && _capturedImage == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _stopLivenessDetection,
          icon: const Icon(Icons.close),
          label: const Text('BATALKAN'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (_capturedImage == null) {
      // Start Liveness Detection Button
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _startLivenessDetection,
              icon: const Icon(Icons.verified_user, size: 28),
              label: const Text(
                'MULAI VERIFIKASI',
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
          ),
          const SizedBox(height: 12),
          // Info text about liveness
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withAlpha(76)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anda akan diminta melakukan $_totalChallenges aksi acak (kedip, senyum, atau putar kepala) untuk memastikan Anda adalah orang yang sebenarnya.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Retake and Submit Buttons (after capture)
    return Column(
      children: [
        // Server face verification status indicator
        if (_serverFaceResult != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _serverFaceResult!.match
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _serverFaceResult!.match
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _serverFaceResult!.match ? Icons.verified_user : Icons.cancel,
                  color: _serverFaceResult!.match ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _serverFaceResult!.match
                        ? 'Wajah Cocok dengan Data Karyawan (${_serverFaceResult!.confidence.toStringAsFixed(1)}%)'
                        : 'Wajah Tidak Cocok! (${_serverFaceResult!.confidence.toStringAsFixed(1)}%) - Foto ulang dengan wajah Anda',
                    style: TextStyle(
                      color: _serverFaceResult!.match ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Submit Button - Only enabled if server says face matches
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting || _isComparingFace || !_livenessVerified || _serverFaceResult?.match != true
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

// Custom Painter for Liveness Face Guide
class LivenessFaceGuidePainter extends CustomPainter {
  final bool isVerified;
  final double blinkProgress;

  LivenessFaceGuidePainter({
    required this.isVerified,
    required this.blinkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use same proportions as FaceOverlayPainter for consistency
    final center = Offset(size.width / 2, size.height / 2 - 30);
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.25;

    // Draw animated oval guide
    final ovalPaint = Paint()
      ..color = isVerified
          ? Colors.green.withAlpha(204)
          : Colors.orange.withAlpha(153)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(rect, ovalPaint);

    // Draw progress arc for challenge completion
    if (!isVerified && blinkProgress > 0) {
      final progressPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * blinkProgress.clamp(0.0, 1.0);
      canvas.drawArc(
        rect.inflate(8),
        -3.14159 / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Draw checkmark if verified
    if (isVerified) {
      final checkPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      final checkPath = Path()
        ..moveTo(center.dx - 30, center.dy)
        ..lineTo(center.dx - 10, center.dy + 25)
        ..lineTo(center.dx + 35, center.dy - 25);

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LivenessFaceGuidePainter oldDelegate) {
    return oldDelegate.isVerified != isVerified ||
        oldDelegate.blinkProgress != blinkProgress;
  }
}

/// Animated visual guide for liveness challenges
class LivenessChallengeAnimation extends StatefulWidget {
  final LivenessChallenge challenge;
  final int currentBlinkCount;
  final int requiredBlinkCount;

  const LivenessChallengeAnimation({
    super.key,
    required this.challenge,
    this.currentBlinkCount = 0,
    this.requiredBlinkCount = 1,
  });

  @override
  State<LivenessChallengeAnimation> createState() => _LivenessChallengeAnimationState();
}

class _LivenessChallengeAnimationState extends State<LivenessChallengeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _moveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _moveAnimation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _moveController]),
      builder: (context, child) {
        return _buildChallengeWidget();
      },
    );
  }

  Widget _buildChallengeWidget() {
    switch (widget.challenge) {
      case LivenessChallenge.blink:
        return _buildBlinkAnimation();
      case LivenessChallenge.turnLeft:
        return _buildTurnLeftAnimation();
      case LivenessChallenge.turnRight:
        return _buildTurnRightAnimation();
      case LivenessChallenge.smile:
        return _buildSmileAnimation();
    }
  }

  Widget _buildBlinkAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated eye icon
        Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent,
                width: 3,
              ),
            ),
            child: Icon(
              _pulseController.value < 0.5
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: AppColors.accent,
              size: 60,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Progress indicator for multiple blinks
        if (widget.requiredBlinkCount > 1)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.requiredBlinkCount, (index) {
              final isCompleted = index < widget.currentBlinkCount;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.success : Colors.white.withAlpha(100),
                    border: Border.all(
                      color: isCompleted ? AppColors.success : AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
        const SizedBox(height: 12),
        _buildInstructionText('Kedipkan Mata', widget.requiredBlinkCount > 1
            ? '${widget.currentBlinkCount}/${widget.requiredBlinkCount}'
            : null),
      ],
    );
  }

  Widget _buildTurnLeftAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated arrow pointing left
        Transform.translate(
          offset: Offset(_moveAnimation.value, 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.accent,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionText('Putar Kepala ke KIRI', null),
      ],
    );
  }

  Widget _buildTurnRightAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated arrow pointing right
        Transform.translate(
          offset: Offset(-_moveAnimation.value, 0),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accent,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionText('Putar Kepala ke KANAN', null),
      ],
    );
  }

  Widget _buildSmileAnimation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated smile icon
        Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.sentiment_very_satisfied,
              color: AppColors.accent,
              size: 60,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInstructionText('Tersenyum', null),
      ],
    );
  }

  Widget _buildInstructionText(String text, String? subText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.accent.withAlpha(100),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (subText != null) ...[
            const SizedBox(height: 4),
            Text(
              subText,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

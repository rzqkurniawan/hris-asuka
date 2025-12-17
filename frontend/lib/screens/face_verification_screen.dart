import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image/image.dart' as img;
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

class _FaceVerificationScreenState extends State<FaceVerificationScreen>
    with WidgetsBindingObserver {
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

  // ===== LIVENESS DETECTION STATE =====
  bool _isLivenessMode = false;
  bool _livenessVerified = false;
  bool _isStreamingFaces = false;

  // Eye blink detection
  int _blinkCount = 0;
  static const int _requiredBlinks = 2;
  bool _eyesWereClosed = false;
  double _lastLeftEyeProb = 1.0;
  double _lastRightEyeProb = 1.0;
  static const double _eyeClosedThreshold = 0.3;
  static const double _eyeOpenThreshold = 0.7;

  // Head movement detection
  bool _headMovementDetected = false;
  double? _initialHeadAngleY;
  double _maxHeadAngleChange = 0.0;
  static const double _requiredHeadMovement = 12.0;

  // Liveness progress tracking
  String _livenessInstruction = '';
  Timer? _livenessTimer;
  int _livenessTimeRemaining = 10;
  static const int _livenessTimeoutSeconds = 10;

  // Multiple frame analysis for anti-spoofing
  List<double> _faceAreaHistory = [];
  List<double> _headAngleHistory = [];
  static const int _historySize = 15;
  bool _naturalMovementDetected = false;

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
      _blinkCount = 0;
      _eyesWereClosed = false;
      _headMovementDetected = false;
      _naturalMovementDetected = false;
      _initialHeadAngleY = null;
      _maxHeadAngleChange = 0.0;
      _faceAreaHistory.clear();
      _headAngleHistory.clear();
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

  void _startLivenessDetection() {
    if (_isLivenessMode) return;

    setState(() {
      _isLivenessMode = true;
      _livenessVerified = false;
      _blinkCount = 0;
      _eyesWereClosed = false;
      _headMovementDetected = false;
      _initialHeadAngleY = null;
      _maxHeadAngleChange = 0.0;
      _faceAreaHistory.clear();
      _headAngleHistory.clear();
      _naturalMovementDetected = false;
      _livenessTimeRemaining = _livenessTimeoutSeconds;
      _livenessInstruction = 'Kedipkan mata Anda 2x';
      _errorMessage = null;
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
        _isStreamingFaces = false;
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
      print('Error starting image stream: $e');
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
      print('Error stopping image stream: $e');
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
      print('Error processing frame: $e');
    }

    _isProcessingFrame = false;
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      final imageRotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );

      if (imageRotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      // For YUV420 format (most common on Android)
      if (image.planes.isEmpty) return null;

      final plane = image.planes.first;
      final bytes = plane.bytes;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  void _analyzeFaceForLiveness(Face face) {
    if (!mounted || _livenessVerified) return;

    // Get eye probabilities
    final leftEyeProb = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeProb = face.rightEyeOpenProbability ?? 0.5;
    final headAngleY = face.headEulerAngleY ?? 0.0;

    // Track face area for natural movement detection
    final faceArea =
        face.boundingBox.width.toDouble() * face.boundingBox.height.toDouble();
    _faceAreaHistory.add(faceArea);
    if (_faceAreaHistory.length > _historySize) {
      _faceAreaHistory.removeAt(0);
    }

    // Track head angle for movement detection
    _headAngleHistory.add(headAngleY);
    if (_headAngleHistory.length > _historySize) {
      _headAngleHistory.removeAt(0);
    }

    // === EYE BLINK DETECTION ===
    bool eyesAreClosed =
        leftEyeProb < _eyeClosedThreshold && rightEyeProb < _eyeClosedThreshold;
    bool eyesAreOpen =
        leftEyeProb > _eyeOpenThreshold && rightEyeProb > _eyeOpenThreshold;

    if (eyesAreClosed && !_eyesWereClosed) {
      _eyesWereClosed = true;
    } else if (eyesAreOpen && _eyesWereClosed) {
      // Blink completed (eyes closed -> eyes open)
      _eyesWereClosed = false;
      _blinkCount++;

      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          if (_blinkCount >= _requiredBlinks) {
            _livenessInstruction = 'Kedipan terdeteksi ✓';
          } else {
            _livenessInstruction =
                'Kedipkan mata lagi (${_blinkCount}/$_requiredBlinks)';
          }
        });
      }
    }

    _lastLeftEyeProb = leftEyeProb;
    _lastRightEyeProb = rightEyeProb;

    // === HEAD MOVEMENT DETECTION ===
    if (_initialHeadAngleY == null) {
      _initialHeadAngleY = headAngleY;
    } else {
      final angleChange = (headAngleY - _initialHeadAngleY!).abs();
      if (angleChange > _maxHeadAngleChange) {
        _maxHeadAngleChange = angleChange;
      }

      if (_maxHeadAngleChange >= _requiredHeadMovement &&
          !_headMovementDetected) {
        _headMovementDetected = true;
        if (mounted) {
          HapticFeedback.lightImpact();
        }
      }
    }

    // === NATURAL MOVEMENT ANALYSIS ===
    // Check for variance in face area and head angle (photos are static)
    if (_faceAreaHistory.length >= _historySize &&
        _headAngleHistory.length >= _historySize) {
      final areaVariance = _calculateVariance(_faceAreaHistory);
      final angleVariance = _calculateVariance(_headAngleHistory);

      // Photos will have very low variance, real faces have natural micro-movements
      // Thresholds are calibrated for typical smartphone usage
      final normalizedAreaVariance =
          areaVariance / (_faceAreaHistory.reduce((a, b) => a + b) / _historySize);

      if (normalizedAreaVariance > 0.0001 || angleVariance > 0.5) {
        _naturalMovementDetected = true;
      }
    }

    // === CHECK IF LIVENESS VERIFIED ===
    bool blinkVerified = _blinkCount >= _requiredBlinks;
    bool movementVerified = _headMovementDetected || _naturalMovementDetected;

    if (blinkVerified && movementVerified && !_livenessVerified) {
      _livenessVerified = true;
      _stopFaceStreaming();
      _livenessTimer?.cancel();

      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _livenessInstruction = 'Verifikasi berhasil! Mengambil foto...';
        });

        // Auto capture after successful liveness
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _captureAfterLiveness();
          }
        });
      }
    }
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
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

      final face = faces.first;
      double confidence = _calculateFaceConfidence(face);

      // Boost confidence for successful liveness
      confidence = (confidence + 5).clamp(0.0, 100.0);

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
        _livenessVerified = false;
        _errorMessage = 'Gagal mengambil foto: ${e.toString()}';
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

            // Liveness Detection Overlay
            if (_isLivenessMode && _capturedImage == null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _livenessVerified ? Colors.green : Colors.orange,
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timer and Progress at top
                      Container(
                        width: double.infinity,
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Timer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer,
                                  color: _livenessTimeRemaining <= 3
                                      ? Colors.red
                                      : Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_livenessTimeRemaining}s',
                                  style: TextStyle(
                                    color: _livenessTimeRemaining <= 3
                                        ? Colors.red
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Progress indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLivenessCheckItem(
                                  'Kedipan',
                                  _blinkCount >= _requiredBlinks,
                                  '$_blinkCount/$_requiredBlinks',
                                ),
                                const SizedBox(width: 12),
                                _buildLivenessCheckItem(
                                  'Gerakan',
                                  _headMovementDetected || _naturalMovementDetected,
                                  _headMovementDetected || _naturalMovementDetected
                                      ? '✓'
                                      : '...',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Face guide oval
                      Flexible(
                        child: CustomPaint(
                          size: const Size(180, 240),
                          painter: LivenessFaceGuidePainter(
                            isVerified: _livenessVerified,
                            blinkProgress: _blinkCount / _requiredBlinks,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Instruction at bottom
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(178),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _livenessVerified
                                  ? Icons.check_circle
                                  : Icons.remove_red_eye,
                              color: _livenessVerified
                                  ? Colors.green
                                  : Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _livenessInstruction,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_livenessVerified)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Gerakkan kepala sedikit ke kiri/kanan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(204),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Face Detection Status (after capture)
            if (_capturedImage != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _faceDetected && _livenessVerified
                        ? Colors.green.withOpacity(0.9)
                        : _faceDetected
                            ? Colors.orange.withOpacity(0.9)
                            : Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _faceDetected && _livenessVerified
                            ? Icons.verified_user
                            : _faceDetected
                                ? Icons.face
                                : Icons.face_retouching_off,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _faceDetected && _livenessVerified
                              ? 'Wajah Terverifikasi (${_faceConfidence.toStringAsFixed(0)}%)'
                              : _faceDetected
                                  ? 'Wajah Terdeteksi (${_faceConfidence.toStringAsFixed(0)}%)'
                                  : 'Wajah Tidak Terdeteksi',
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

  Widget _buildLivenessCheckItem(String label, bool isCompleted, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.8)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $status',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    final isCheckIn = widget.checkType == 'check_in';

    // During liveness mode - show cancel button
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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anda akan diminta mengedipkan mata dan menggerakkan kepala untuk memastikan keaslian wajah.',
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
        // Liveness status indicator
        if (_livenessVerified)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Liveness Terverifikasi',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting || _faceConfidence < 80 || !_livenessVerified
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
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width * 0.45;
    final radiusY = size.height * 0.45;

    // Draw animated oval guide
    final ovalPaint = Paint()
      ..color = isVerified
          ? Colors.green.withOpacity(0.8)
          : Colors.orange.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(rect, ovalPaint);

    // Draw progress arc for blink detection
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
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final checkPath = Path()
        ..moveTo(center.dx - 20, center.dy)
        ..lineTo(center.dx - 5, center.dy + 15)
        ..lineTo(center.dx + 25, center.dy - 15);

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LivenessFaceGuidePainter oldDelegate) {
    return oldDelegate.isVerified != isVerified ||
        oldDelegate.blinkProgress != blinkProgress;
  }
}

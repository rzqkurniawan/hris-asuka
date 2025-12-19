import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import '../utils/page_transitions.dart';
import 'reset_password_screen.dart';

/// Random challenge types for anti-spoofing liveness detection
enum LivenessChallenge {
  blink,
  turnLeft,
  turnRight,
  smile,
}

class FaceVerificationResetScreen extends StatefulWidget {
  final String resetToken;
  final String employeeName;
  final String avatarUrl;
  final String expiresAt;

  const FaceVerificationResetScreen({
    super.key,
    required this.resetToken,
    required this.employeeName,
    required this.avatarUrl,
    required this.expiresAt,
  });

  @override
  State<FaceVerificationResetScreen> createState() =>
      _FaceVerificationResetScreenState();
}

class _FaceVerificationResetScreenState
    extends State<FaceVerificationResetScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _faceDetected = false;
  bool _isComparingFace = false; // Server-side face comparison in progress

  FaceDetector? _faceDetector;
  String? _errorMessage;
  double _faceConfidence = 0.0;

  XFile? _capturedImage;
  String? _capturedImageBase64;

  // Server-side face comparison result
  FaceComparisonResult? _serverFaceResult;

  // Liveness Detection State
  bool _isLivenessMode = false;
  bool _livenessVerified = false;
  bool _isStreamingFaces = false;

  List<LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  static const int _totalChallenges = 2;

  // Eye blink detection
  bool _eyesWereClosed = false;
  static const double _eyeClosedThreshold = 0.3;
  static const double _eyeOpenThreshold = 0.7;
  int _requiredBlinkCount = 1;
  int _currentBlinkCount = 0;

  // Head turn detection
  double? _baselineHeadAngleY;
  static const double _headTurnThreshold = 30.0;

  // Smile detection
  static const double _smileThreshold = 0.7;

  // Challenge completion tracking
  bool _currentChallengeCompleted = false;
  String _livenessInstruction = '';
  Timer? _livenessTimer;
  int _livenessTimeRemaining = 20;
  static const int _livenessTimeoutSeconds = 20;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeFaceDetector();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopLivenessDetection();
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

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
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

  Future<List<Face>> _detectFacesFromFile(XFile imageFile) async {
    try {
      var inputImage = InputImage.fromFilePath(imageFile.path);
      var faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty && Platform.isIOS) {
        final bytes = await imageFile.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        if (decodedImage != null) {
          var processedImage = img.flipHorizontal(decodedImage);
          final processedBytes =
              Uint8List.fromList(img.encodeJpg(processedImage));

          final tempDir = Directory.systemTemp;
          final tempFile = File(
              '${tempDir.path}/face_detect_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(processedBytes);

          inputImage = InputImage.fromFilePath(tempFile.path);
          faces = await _faceDetector!.processImage(inputImage);

          try {
            await tempFile.delete();
          } catch (_) {}
        }
      }

      return faces;
    } catch (e) {
      return [];
    }
  }

  double _calculateFaceConfidence(Face face) {
    double confidence = 85.0;

    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;

    if (headEulerAngleY.abs() < 10 && headEulerAngleZ.abs() < 10) {
      confidence += 5;
    } else if (headEulerAngleY.abs() > 30 || headEulerAngleZ.abs() > 30) {
      confidence -= 10;
    }

    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;

    if (leftEyeOpen > 0.8 && rightEyeOpen > 0.8) {
      confidence += 5;
    } else if (leftEyeOpen < 0.3 || rightEyeOpen < 0.3) {
      confidence -= 10;
    }

    final smilingProb = face.smilingProbability ?? 0.5;
    if (smilingProb > 0.8 || smilingProb < 0.2) {
      confidence -= 3;
    }

    return confidence.clamp(0.0, 100.0);
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _capturedImageBase64 = null;
      _faceDetected = false;
      _faceConfidence = 0.0;
      _errorMessage = null;
      _livenessVerified = false;
      _challenges.clear();
      _currentChallengeIndex = 0;
      _currentChallengeCompleted = false;
      _eyesWereClosed = false;
      _baselineHeadAngleY = null;
      _serverFaceResult = null; // Reset server face comparison result
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

  // Liveness Detection Methods

  List<LivenessChallenge> _generateRandomChallenges() {
    final random = Random();
    final allChallenges = List<LivenessChallenge>.from(LivenessChallenge.values);
    allChallenges.shuffle(random);
    return allChallenges.take(_totalChallenges).toList();
  }

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

  void _startLivenessDetection() {
    if (_isLivenessMode) return;

    final challenges = _generateRandomChallenges();
    final random = Random();
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
      // Silently handle
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
      // Silently handle
    }

    _isProcessingFrame = false;
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      InputImageRotation imageRotation;
      if (Platform.isAndroid) {
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

      if (Platform.isAndroid) {
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

  Uint8List? _convertYUV420ToNV21(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final int ySize = width * height;
      final int uvSize = width * height ~/ 2;

      final nv21 = Uint8List(ySize + uvSize);

      final yPlane = image.planes[0];
      int yIndex = 0;
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          nv21[yIndex++] = yPlane.bytes[row * yPlane.bytesPerRow + col];
        }
      }

      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final int uvWidth = width ~/ 2;
      final int uvHeight = height ~/ 2;

      int uvIndex = ySize;
      for (int row = 0; row < uvHeight; row++) {
        for (int col = 0; col < uvWidth; col++) {
          final int uOffset =
              row * uPlane.bytesPerRow + col * uPlane.bytesPerPixel!;
          final int vOffset =
              row * vPlane.bytesPerRow + col * vPlane.bytesPerPixel!;

          nv21[uvIndex++] = vPlane.bytes[vOffset];
          nv21[uvIndex++] = uPlane.bytes[uOffset];
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

    final leftEyeProb = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeProb = face.rightEyeOpenProbability ?? 0.5;
    final headAngleY = face.headEulerAngleY ?? 0.0;
    final smileProb = face.smilingProbability ?? 0.0;

    if (_baselineHeadAngleY == null) {
      _baselineHeadAngleY = headAngleY;
    }

    bool challengeCompleted = false;

    switch (currentChallenge) {
      case LivenessChallenge.blink:
        bool eyesAreClosed = leftEyeProb < _eyeClosedThreshold &&
            rightEyeProb < _eyeClosedThreshold;
        bool eyesAreOpen =
            leftEyeProb > _eyeOpenThreshold && rightEyeProb > _eyeOpenThreshold;

        if (eyesAreClosed && !_eyesWereClosed) {
          _eyesWereClosed = true;
        } else if (eyesAreOpen && _eyesWereClosed) {
          _eyesWereClosed = false;
          _currentBlinkCount++;

          if (_currentBlinkCount < _requiredBlinkCount) {
            setState(() {
              _livenessInstruction = _getChallengeInstruction(currentChallenge);
            });
            if (mounted) {
              HapticFeedback.lightImpact();
            }
          } else {
            challengeCompleted = true;
          }
        }
        break;

      case LivenessChallenge.turnLeft:
        final angleFromBaseline = headAngleY - (_baselineHeadAngleY ?? 0);
        if (angleFromBaseline > _headTurnThreshold) {
          challengeCompleted = true;
        }
        break;

      case LivenessChallenge.turnRight:
        final angleFromBaseline = headAngleY - (_baselineHeadAngleY ?? 0);
        if (angleFromBaseline < -_headTurnThreshold) {
          challengeCompleted = true;
        }
        break;

      case LivenessChallenge.smile:
        if (smileProb > _smileThreshold) {
          challengeCompleted = true;
        }
        break;
    }

    if (challengeCompleted && !_currentChallengeCompleted) {
      _currentChallengeCompleted = true;

      if (mounted) {
        HapticFeedback.mediumImpact();
      }

      if (_currentChallengeIndex < _challenges.length - 1) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isDisposed && _isLivenessMode) {
            final nextChallenge = _challenges[_currentChallengeIndex + 1];
            int newBlinkCount = _requiredBlinkCount;
            if (nextChallenge == LivenessChallenge.blink) {
              newBlinkCount = Random().nextInt(3) + 1;
            }

            setState(() {
              _currentChallengeIndex++;
              _currentChallengeCompleted = false;
              _eyesWereClosed = false;
              _baselineHeadAngleY = null;
              _currentBlinkCount = 0;
              _requiredBlinkCount = newBlinkCount;
              _livenessInstruction =
                  _getChallengeInstruction(_challenges[_currentChallengeIndex]);
            });
          }
        });
      } else {
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
      if (_isStreamingFaces) {
        await _stopFaceStreaming();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final XFile imageFile = await _cameraController!.takePicture();
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

      // Automatically compare face with server after capture
      await _compareFaceWithServer(base64Image);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _livenessVerified = false;
        _errorMessage = 'Gagal mengambil foto: ${e.toString()}';
      });
    }
  }

  /// Compare captured face with employee photo on server
  Future<void> _compareFaceWithServer(String base64Image) async {
    if (!mounted || _isDisposed) return;

    setState(() {
      _isComparingFace = true;
      _serverFaceResult = null;
    });

    try {
      final result = await _authService.compareFaceForReset(
        resetToken: widget.resetToken,
        faceImage: base64Image,
      );

      if (!mounted || _isDisposed) return;

      setState(() {
        _serverFaceResult = result;
        _isComparingFace = false;
      });

      // Provide haptic feedback based on result
      if (result.match) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;

      setState(() {
        _serverFaceResult = FaceComparisonResult(
          success: false,
          match: false,
          confidence: 0,
          message: 'Gagal memverifikasi wajah: ${e.toString()}',
        );
        _isComparingFace = false;
      });
    }
  }

  void _proceedToResetPassword() {
    if (_capturedImageBase64 == null || !_faceDetected || !_livenessVerified) {
      ToastUtils.showError(context, 'Silakan verifikasi wajah terlebih dahulu');
      return;
    }

    // Server-side face comparison must pass
    if (_serverFaceResult == null || !_serverFaceResult!.match) {
      ToastUtils.showError(
          context, 'Wajah tidak cocok dengan data karyawan. Silakan foto ulang.');
      return;
    }

    // Navigate to reset password screen
    Navigator.pushReplacement(
      context,
      SlideRightRoute(
        page: ResetPasswordScreen(
          resetToken: widget.resetToken,
          faceImage: _capturedImageBase64!,
          faceConfidence: _faceConfidence,
          livenessVerified: _livenessVerified,
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
        title: const Text('Verifikasi Wajah'),
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
              // Employee Info
              _buildEmployeeInfo(isDarkMode),
              const SizedBox(height: 16),

              // Camera Preview
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

  Widget _buildEmployeeInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employeeName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pastikan wajah sesuai dengan foto karyawan',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
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
                child: CustomPaint(
                  painter: LivenessFaceGuidePainter(
                    isVerified: _livenessVerified,
                    blinkProgress: _challenges.isEmpty
                        ? 0.0
                        : (_currentChallengeIndex +
                                (_currentChallengeCompleted ? 1 : 0)) /
                            _challenges.length,
                  ),
                ),
              ),

            // Liveness Detection Border
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

            // Challenge Progress at top
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

            // Challenge Instruction Toast
            if (_isLivenessMode &&
                _capturedImage == null &&
                !_livenessVerified &&
                _challenges.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getSimpleInstruction(
                                  _challenges[_currentChallengeIndex]),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_challenges[_currentChallengeIndex] ==
                                    LivenessChallenge.blink &&
                                _requiredBlinkCount > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(_requiredBlinkCount,
                                      (index) {
                                    final isCompleted =
                                        index < _currentBlinkCount;
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
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _livenessTimeRemaining <= 5
                              ? Colors.red.withAlpha(50)
                              : Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
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

            // Liveness Verified Success Toast
            if (_isLivenessMode && _capturedImage == null && _livenessVerified)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 28),
                      SizedBox(width: 14),
                      Expanded(
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

            // Server Face Comparison Status (after capture)
            if (_capturedImage != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isComparingFace
                        ? Colors.blue.withOpacity(0.9)
                        : _serverFaceResult?.match == true
                            ? Colors.green.withOpacity(0.9)
                            : _serverFaceResult != null
                                ? Colors.red.withOpacity(0.9)
                                : Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isComparingFace)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
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
                          _isComparingFace
                              ? 'Memverifikasi wajah...'
                              : _serverFaceResult?.match == true
                                  ? 'Wajah Cocok (${_serverFaceResult!.confidence.toStringAsFixed(1)}%)'
                                  : _serverFaceResult != null
                                      ? 'Wajah Tidak Cocok (${_serverFaceResult!.confidence.toStringAsFixed(1)}%)'
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

  Widget _buildChallengeProgressItem(int index) {
    final isCompleted = index < _currentChallengeIndex ||
        (index == _currentChallengeIndex && _currentChallengeCompleted);
    final isCurrent =
        index == _currentChallengeIndex && !_currentChallengeCompleted;
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
        border:
            isCurrent ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : _getChallengeIcon(challenge),
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
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    // Retake and Proceed Buttons (after capture)
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

        // Proceed Button (only enabled when server says face matches)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isComparingFace ||
                    !_livenessVerified ||
                    _serverFaceResult?.match != true
                ? null
                : _proceedToResetPassword,
            icon: const Icon(Icons.arrow_forward, size: 28),
            label: const Text(
              'LANJUT RESET PASSWORD',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
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
            onPressed: _retakePhoto,
            icon: const Icon(Icons.refresh),
            label: const Text('FOTO ULANG'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDarkMode ? Colors.white : AppColors.textPrimary,
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

    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(rect, paint);

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
      Offset(center.dx - radiusX - padding + bracketLength,
          center.dy - radiusY - padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radiusX - padding, center.dy - radiusY - padding),
      Offset(center.dx - radiusX - padding,
          center.dy - radiusY - padding + bracketLength),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy - radiusY - padding),
      Offset(center.dx + radiusX + padding - bracketLength,
          center.dy - radiusY - padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy - radiusY - padding),
      Offset(center.dx + radiusX + padding,
          center.dy - radiusY - padding + bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(center.dx - radiusX - padding, center.dy + radiusY + padding),
      Offset(center.dx - radiusX - padding + bracketLength,
          center.dy + radiusY + padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radiusX - padding, center.dy + radiusY + padding),
      Offset(center.dx - radiusX - padding,
          center.dy + radiusY + padding - bracketLength),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy + radiusY + padding),
      Offset(center.dx + radiusX + padding - bracketLength,
          center.dy + radiusY + padding),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radiusX + padding, center.dy + radiusY + padding),
      Offset(center.dx + radiusX + padding,
          center.dy + radiusY + padding - bracketLength),
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
    final center = Offset(size.width / 2, size.height / 2 - 30);
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.25;

    final ovalPaint = Paint()
      ..color =
          isVerified ? Colors.green.withAlpha(204) : Colors.orange.withAlpha(153)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(rect, ovalPaint);

    if (!isVerified && blinkProgress > 0) {
      final progressPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * blinkProgress.clamp(0.0, 1.0);
      canvas.drawArc(
        rect.inflate(8),
        -3.14159 / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }

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

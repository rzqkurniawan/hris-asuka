import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Service untuk mendeteksi fake GPS dan device integrity
class DeviceSecurityService {
  static final DeviceSecurityService _instance = DeviceSecurityService._internal();
  factory DeviceSecurityService() => _instance;
  DeviceSecurityService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();

  /// Check if mock location is enabled (Android only)
  /// Returns true if mock location detected
  Future<bool> isMockLocationEnabled(Position position) async {
    if (Platform.isAndroid) {
      // On Android, Position.isMocked tells us if the location is from a mock provider
      return position.isMocked;
    }
    // iOS doesn't have built-in mock location detection
    // We rely on other heuristics
    return false;
  }

  /// Check if device is rooted (Android) or jailbroken (iOS)
  Future<bool> isDeviceRooted() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        return await _checkIOSJailbreak();
      }
      return false;
    } catch (e) {
      // If check fails, assume not rooted (fail-open for UX)
      return false;
    }
  }

  /// Get current WiFi information
  Future<WifiInfo> getWifiInfo() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      final wifiBSSID = await _networkInfo.getWifiBSSID();

      return WifiInfo(
        ssid: wifiName?.replaceAll('"', ''), // Remove quotes from SSID
        bssid: wifiBSSID,
      );
    } catch (e) {
      return WifiInfo(ssid: null, bssid: null);
    }
  }

  /// Get extended location data for anti-fake GPS validation
  Future<ExtendedLocationData> getExtendedLocationData(Position position) async {
    final wifiInfo = await getWifiInfo();
    final isMocked = await isMockLocationEnabled(position);
    final isRooted = await isDeviceRooted();

    return ExtendedLocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      heading: position.heading,
      timestamp: position.timestamp,
      isMockLocation: isMocked,
      isRooted: isRooted,
      wifiSsid: wifiInfo.ssid,
      wifiBssid: wifiInfo.bssid,
      locationProvider: _getLocationProvider(position),
      locationAgeMs: DateTime.now().difference(position.timestamp).inMilliseconds,
    );
  }

  /// Determine location provider type
  String _getLocationProvider(Position position) {
    // Geolocator doesn't expose provider directly
    // Use accuracy as heuristic
    if (position.accuracy < 10) {
      return 'gps'; // High accuracy = GPS
    } else if (position.accuracy < 50) {
      return 'fused'; // Medium accuracy = Fused (GPS + Network)
    } else {
      return 'network'; // Low accuracy = Network/Cell Tower
    }
  }

  /// Check for Android root indicators
  Future<bool> _checkAndroidRoot() async {
    // Common root detection paths
    final List<String> rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
      '/system/app/SuperSU.apk',
      '/system/app/Superuser',
      '/magisk',
    ];

    for (final path in rootPaths) {
      try {
        if (await File(path).exists()) {
          return true;
        }
      } catch (e) {
        // Path not accessible
      }
    }

    // Check for dangerous properties
    try {
      final result = await Process.run('getprop', ['ro.build.tags']);
      if (result.stdout.toString().contains('test-keys')) {
        return true;
      }
    } catch (e) {
      // Command failed
    }

    return false;
  }

  /// Check for iOS jailbreak indicators
  Future<bool> _checkIOSJailbreak() async {
    // Common jailbreak paths
    final List<String> jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/usr/bin/ssh',
      '/private/var/lib/cydia',
      '/private/var/tmp/cydia.log',
      '/Applications/RockApp.app',
      '/Applications/blackra1n.app',
      '/Applications/FakeCarrier.app',
      '/Applications/SBSettings.app',
      '/Applications/WinterBoard.app',
    ];

    for (final path in jailbreakPaths) {
      try {
        if (await File(path).exists()) {
          return true;
        }
      } catch (e) {
        // Path not accessible
      }
    }

    // Check if app can write outside sandbox
    try {
      final file = File('/private/jailbreak_test.txt');
      await file.writeAsString('test');
      await file.delete();
      return true; // If we can write here, device is jailbroken
    } catch (e) {
      // Expected behavior on non-jailbroken devices
    }

    return false;
  }

  /// Analyze location data and return list of suspicious flags
  List<String> detectSuspiciousBehavior(ExtendedLocationData data) {
    final List<String> flags = [];

    // Mock location detected
    if (data.isMockLocation) {
      flags.add('mock_location_enabled');
    }

    // Rooted/Jailbroken device
    if (data.isRooted) {
      flags.add('rooted_device');
    }

    // GPS accuracy too low (> 100 meters)
    if (data.accuracy > 100) {
      flags.add('low_gps_accuracy');
    }

    // Location data too old (> 30 seconds)
    if (data.locationAgeMs > 30000) {
      flags.add('stale_location_data');
    }

    // Unrealistic speed (> 50 m/s = 180 km/h)
    if (data.speed > 50) {
      flags.add('unrealistic_speed');
    }

    return flags;
  }

  /// Check if attendance should be blocked due to security concerns
  bool shouldBlockAttendance(ExtendedLocationData data) {
    // Block if mock location is definitely enabled
    return data.isMockLocation;
  }
}

/// WiFi Information
class WifiInfo {
  final String? ssid;
  final String? bssid;

  WifiInfo({this.ssid, this.bssid});
}

/// Extended Location Data with security information
class ExtendedLocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final DateTime timestamp;
  final bool isMockLocation;
  final bool isRooted;
  final String? wifiSsid;
  final String? wifiBssid;
  final String locationProvider;
  final int locationAgeMs;

  ExtendedLocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.speedAccuracy,
    required this.heading,
    required this.timestamp,
    required this.isMockLocation,
    required this.isRooted,
    this.wifiSsid,
    this.wifiBssid,
    required this.locationProvider,
    required this.locationAgeMs,
  });

  /// Convert to Map for API submission
  Map<String, dynamic> toApiMap() {
    return {
      'is_mock_location': isMockLocation ? 1 : 0, // Send as int for PHP compatibility
      'is_rooted': isRooted ? 1 : 0, // Send as int for PHP compatibility
      'wifi_ssid': wifiSsid,
      'wifi_bssid': wifiBssid,
      'gps_accuracy': accuracy.isFinite ? accuracy : null, // Handle NaN/Infinity
      'location_age_ms': locationAgeMs,
      'location_provider': locationProvider,
      'altitude': altitude.isFinite ? altitude : null, // Handle NaN/Infinity
      'speed': speed.isFinite ? speed : null, // Handle NaN/Infinity
    };
  }
}

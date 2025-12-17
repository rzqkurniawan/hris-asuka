<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceLocation;
use App\Models\AttendanceRecord;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class MobileAttendanceController extends Controller
{
    /**
     * Get all active attendance locations
     */
    public function getLocations()
    {
        try {
            $locations = AttendanceLocation::active()
                ->select('id', 'name', 'address', 'latitude', 'longitude', 'radius_meters')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Attendance locations retrieved successfully',
                'data' => $locations,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve locations',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get today's attendance status for logged-in user
     */
    public function getTodayStatus()
    {
        try {
            $user = Auth::user();
            $employeeId = $user->employee_id;

            $checkIn = AttendanceRecord::getTodayCheckIn($employeeId);
            $checkOut = AttendanceRecord::getTodayCheckOut($employeeId);

            return response()->json([
                'success' => true,
                'message' => 'Today status retrieved successfully',
                'data' => [
                    'date' => now()->toDateString(),
                    'can_check_in' => !$checkIn,
                    'can_check_out' => $checkIn && !$checkOut,
                    'check_in' => $checkIn ? [
                        'time' => $checkIn->created_at->toIso8601String(),
                        'location' => $checkIn->location->name ?? '-',
                        'location_verified' => $checkIn->location_verified,
                        'face_verified' => $checkIn->face_verified,
                    ] : null,
                    'check_out' => $checkOut ? [
                        'time' => $checkOut->created_at->toIso8601String(),
                        'location' => $checkOut->location->name ?? '-',
                        'location_verified' => $checkOut->location_verified,
                        'face_verified' => $checkOut->face_verified,
                    ] : null,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve today status',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Validate location before attendance
     */
    public function validateLocation(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $latitude = $request->latitude;
            $longitude = $request->longitude;

            // Find location within radius
            $location = AttendanceLocation::findByCoordinates($latitude, $longitude);

            if ($location) {
                $distance = $location->distanceFrom($latitude, $longitude);

                return response()->json([
                    'success' => true,
                    'message' => 'Location is valid',
                    'data' => [
                        'is_valid' => true,
                        'location_id' => $location->id,
                        'location_name' => $location->name,
                        'distance_meters' => round($distance, 2),
                        'radius_meters' => $location->radius_meters,
                    ],
                ], 200);
            }

            // Find nearest location for error message
            $nearest = AttendanceLocation::findNearest($latitude, $longitude);
            $nearestDistance = $nearest ? $nearest->distanceFrom($latitude, $longitude) : null;

            return response()->json([
                'success' => false,
                'message' => 'Location is outside allowed radius',
                'data' => [
                    'is_valid' => false,
                    'nearest_location' => $nearest ? $nearest->name : null,
                    'distance_to_nearest' => $nearestDistance ? round($nearestDistance, 2) : null,
                    'required_radius' => $nearest ? $nearest->radius_meters : null,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to validate location',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get employee avatar for face comparison
     */
    public function getEmployeeAvatar()
    {
        try {
            $user = Auth::user();

            // Get avatar from c3ais database
            $employee = DB::connection('c3ais')
                ->table('ki_employee')
                ->where('employee_id', $user->employee_id)
                ->select('identity_file_name')
                ->first();

            if (!$employee || !$employee->identity_file_name) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee avatar not found',
                ], 404);
            }

            $avatarPath = $employee->identity_file_name;

            return response()->json([
                'success' => true,
                'message' => 'Employee avatar retrieved successfully',
                'data' => [
                    'avatar_url' => url("/api/employees/photo/{$avatarPath}"),
                    'avatar_path' => $avatarPath,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve avatar',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Submit attendance (check-in or check-out)
     */
    public function submitAttendance(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'check_type' => 'required|in:check_in,check_out',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'face_image' => 'required|string', // Base64 encoded image
            'face_confidence' => 'required|numeric|between:0,100',
            'device_info' => 'nullable|string|max:255',
            // Liveness detection field
            'liveness_verified' => 'required|boolean',
            // Anti-fake GPS fields
            'is_mock_location' => 'nullable|boolean',
            'is_rooted' => 'nullable|boolean',
            'wifi_ssid' => 'nullable|string|max:100',
            'wifi_bssid' => 'nullable|string|max:50',
            'gps_accuracy' => 'nullable|numeric|min:0',
            'location_age_ms' => 'nullable|integer|min:0',
            'location_provider' => 'nullable|string|max:50',
            'altitude' => 'nullable|numeric',
            'speed' => 'nullable|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = Auth::user();
            $employeeId = $user->employee_id;
            $checkType = $request->check_type;

            // Check if already checked in/out today
            if ($checkType === AttendanceRecord::CHECK_TYPE_IN) {
                if (AttendanceRecord::hasCheckedInToday($employeeId)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Anda sudah melakukan check-in hari ini',
                    ], 400);
                }
            } else {
                if (!AttendanceRecord::hasCheckedInToday($employeeId)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Anda harus check-in terlebih dahulu',
                    ], 400);
                }

                if (AttendanceRecord::hasCheckedOutToday($employeeId)) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Anda sudah melakukan check-out hari ini',
                    ], 400);
                }
            }

            // Validate location
            $latitude = $request->latitude;
            $longitude = $request->longitude;
            $location = AttendanceLocation::findByCoordinates($latitude, $longitude);

            if (!$location) {
                return response()->json([
                    'success' => false,
                    'message' => 'Lokasi Anda di luar radius yang diizinkan. Absensi ditolak.',
                ], 400);
            }

            // Validate face confidence (minimum 80%)
            $faceConfidence = $request->face_confidence;
            $minConfidence = 80.0;

            if ($faceConfidence < $minConfidence) {
                return response()->json([
                    'success' => false,
                    'message' => 'Verifikasi wajah gagal. Tingkat kecocokan terlalu rendah. Absensi ditolak.',
                    'data' => [
                        'face_confidence' => $faceConfidence,
                        'min_required' => $minConfidence,
                    ],
                ], 400);
            }

            // Validate liveness detection - REQUIRED for anti-spoofing
            $livenessVerified = $request->boolean('liveness_verified', false);
            if (!$livenessVerified) {
                return response()->json([
                    'success' => false,
                    'message' => 'Verifikasi liveness gagal. Pastikan Anda mengedipkan mata dan menggerakkan kepala saat verifikasi. Absensi ditolak.',
                ], 400);
            }

            // Save face image
            $faceImagePath = $this->saveFaceImage($request->face_image, $user->id, $checkType);

            // Prepare location data for suspicious detection
            $locationData = [
                'is_mock_location' => $request->boolean('is_mock_location', false),
                'is_rooted' => $request->boolean('is_rooted', false),
                'gps_accuracy' => $request->gps_accuracy,
                'location_age_ms' => $request->location_age_ms,
                'speed' => $request->speed,
            ];

            // Detect suspicious behavior
            $suspiciousFlags = AttendanceRecord::detectSuspiciousBehavior($locationData);
            $isSuspicious = AttendanceRecord::shouldFlagAsSuspicious($locationData);

            // Create attendance record with anti-fake GPS data
            $attendance = AttendanceRecord::create([
                'employee_id' => $employeeId,
                'user_id' => $user->id,
                'check_type' => $checkType,
                'latitude' => $latitude,
                'longitude' => $longitude,
                'location_id' => $location->id,
                'location_verified' => true,
                'face_verified' => true,
                'face_confidence' => $faceConfidence,
                'face_image_path' => $faceImagePath,
                'liveness_verified' => $livenessVerified, // Anti-spoofing liveness check
                'device_info' => $request->device_info,
                'attendance_date' => now()->toDateString(),
                // Anti-fake GPS data
                'is_mock_location' => $request->boolean('is_mock_location', false),
                'is_rooted' => $request->boolean('is_rooted'),
                'wifi_ssid' => $request->wifi_ssid,
                'wifi_bssid' => $request->wifi_bssid,
                'gps_accuracy' => $request->gps_accuracy,
                'location_age_ms' => $request->location_age_ms,
                'location_provider' => $request->location_provider,
                'altitude' => $request->altitude,
                'speed' => $request->speed,
                'suspicious_flags' => !empty($suspiciousFlags) ? $suspiciousFlags : null,
                'is_suspicious' => $isSuspicious,
            ]);

            $checkTypeDisplay = $checkType === AttendanceRecord::CHECK_TYPE_IN ? 'Check-In' : 'Check-Out';

            // Add warning message if suspicious
            $message = "{$checkTypeDisplay} berhasil dicatat";
            if ($isSuspicious) {
                $message .= " (Flagged for review)";
            }

            return response()->json([
                'success' => true,
                'message' => $message,
                'data' => [
                    'id' => $attendance->id,
                    'check_type' => $attendance->check_type,
                    'time' => $attendance->created_at->toIso8601String(),
                    'location' => $location->name,
                    'location_verified' => $attendance->location_verified,
                    'face_verified' => $attendance->face_verified,
                    'face_confidence' => $attendance->face_confidence,
                    'is_suspicious' => $isSuspicious,
                    'suspicious_flags' => $suspiciousFlags,
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan absensi',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get attendance history for logged-in user
     */
    public function getHistory(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'month' => 'nullable|integer|between:1,12',
            'year' => 'nullable|integer|min:2020',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = Auth::user();
            $employeeId = $user->employee_id;

            // Determine date range
            if ($request->has('start_date') && $request->has('end_date')) {
                $startDate = $request->start_date;
                $endDate = $request->end_date;
            } elseif ($request->has('month') && $request->has('year')) {
                $startDate = "{$request->year}-{$request->month}-01";
                $endDate = date('Y-m-t', strtotime($startDate));
            } else {
                // Default to current month
                $startDate = now()->startOfMonth()->toDateString();
                $endDate = now()->endOfMonth()->toDateString();
            }

            $records = AttendanceRecord::getByDateRange($employeeId, $startDate, $endDate);

            // Group by date
            $groupedRecords = [];
            foreach ($records as $record) {
                $date = $record->attendance_date->toDateString();
                if (!isset($groupedRecords[$date])) {
                    $groupedRecords[$date] = [
                        'date' => $date,
                        'check_in' => null,
                        'check_out' => null,
                    ];
                }

                $recordData = [
                    'time' => $record->created_at->toIso8601String(),
                    'location' => $record->location->name ?? '-',
                    'location_verified' => $record->location_verified,
                    'face_verified' => $record->face_verified,
                ];

                if ($record->check_type === AttendanceRecord::CHECK_TYPE_IN) {
                    $groupedRecords[$date]['check_in'] = $recordData;
                } else {
                    $groupedRecords[$date]['check_out'] = $recordData;
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Attendance history retrieved successfully',
                'data' => [
                    'start_date' => $startDate,
                    'end_date' => $endDate,
                    'total_days' => count($groupedRecords),
                    'records' => array_values($groupedRecords),
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve attendance history',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Save base64 face image to storage
     */
    private function saveFaceImage(string $base64Image, int $userId, string $checkType): string
    {
        // Remove data URL prefix if exists
        if (strpos($base64Image, 'base64,') !== false) {
            $base64Image = explode('base64,', $base64Image)[1];
        }

        $imageData = base64_decode($base64Image);
        $date = now()->format('Y-m-d');
        $timestamp = now()->format('His');
        $filename = "attendance/{$date}/{$userId}_{$checkType}_{$timestamp}.jpg";

        Storage::disk('public')->put($filename, $imageData);

        return $filename;
    }
}

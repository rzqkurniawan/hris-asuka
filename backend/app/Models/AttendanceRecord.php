<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AttendanceRecord extends Model
{
    use HasFactory;

    protected $table = 'attendance_records';

    protected $fillable = [
        'employee_id',
        'user_id',
        'check_type',
        'latitude',
        'longitude',
        'location_id',
        'location_verified',
        'face_verified',
        'face_confidence',
        'liveness_verified', // Anti-spoofing liveness check
        'face_image_path',
        'device_info',
        'attendance_date',
        // Anti-fake GPS fields
        'is_mock_location',
        'is_rooted',
        'wifi_ssid',
        'wifi_bssid',
        'gps_accuracy',
        'location_age_ms',
        'location_provider',
        'altitude',
        'speed',
        'suspicious_flags',
        'is_suspicious',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'location_verified' => 'boolean',
        'face_verified' => 'boolean',
        'face_confidence' => 'decimal:2',
        'liveness_verified' => 'boolean', // Anti-spoofing liveness check
        'attendance_date' => 'date',
        // Anti-fake GPS casts
        'is_mock_location' => 'boolean',
        'is_rooted' => 'boolean',
        'gps_accuracy' => 'decimal:2',
        'location_age_ms' => 'integer',
        'altitude' => 'decimal:2',
        'speed' => 'decimal:2',
        'suspicious_flags' => 'array',
        'is_suspicious' => 'boolean',
    ];

    const CHECK_TYPE_IN = 'check_in';
    const CHECK_TYPE_OUT = 'check_out';

    /**
     * Get the user who made this attendance record
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the employee from c3ais database
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }

    /**
     * Get the attendance location
     */
    public function location()
    {
        return $this->belongsTo(AttendanceLocation::class, 'location_id');
    }

    /**
     * Scope for check-in records
     */
    public function scopeCheckIn($query)
    {
        return $query->where('check_type', self::CHECK_TYPE_IN);
    }

    /**
     * Scope for check-out records
     */
    public function scopeCheckOut($query)
    {
        return $query->where('check_type', self::CHECK_TYPE_OUT);
    }

    /**
     * Scope for today's records
     */
    public function scopeToday($query)
    {
        return $query->where('attendance_date', now()->toDateString());
    }

    /**
     * Scope for specific date
     */
    public function scopeOnDate($query, $date)
    {
        return $query->where('attendance_date', $date);
    }

    /**
     * Scope for specific employee
     */
    public function scopeForEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    /**
     * Check if employee has already checked in today
     */
    public static function hasCheckedInToday(int $employeeId): bool
    {
        return self::forEmployee($employeeId)
            ->today()
            ->checkIn()
            ->exists();
    }

    /**
     * Check if employee has already checked out today
     */
    public static function hasCheckedOutToday(int $employeeId): bool
    {
        return self::forEmployee($employeeId)
            ->today()
            ->checkOut()
            ->exists();
    }

    /**
     * Get today's check-in record for employee
     */
    public static function getTodayCheckIn(int $employeeId): ?self
    {
        return self::forEmployee($employeeId)
            ->today()
            ->checkIn()
            ->first();
    }

    /**
     * Get today's check-out record for employee
     */
    public static function getTodayCheckOut(int $employeeId): ?self
    {
        return self::forEmployee($employeeId)
            ->today()
            ->checkOut()
            ->first();
    }

    /**
     * Get today's attendance status for employee
     * Returns: ['check_in' => record|null, 'check_out' => record|null]
     */
    public static function getTodayStatus(int $employeeId): array
    {
        return [
            'check_in' => self::getTodayCheckIn($employeeId),
            'check_out' => self::getTodayCheckOut($employeeId),
        ];
    }

    /**
     * Get attendance records for employee within date range
     */
    public static function getByDateRange(int $employeeId, string $startDate, string $endDate)
    {
        return self::forEmployee($employeeId)
            ->whereBetween('attendance_date', [$startDate, $endDate])
            ->orderBy('attendance_date', 'desc')
            ->orderBy('created_at', 'asc')
            ->get();
    }

    /**
     * Check if this is a verified attendance (both location and face)
     */
    public function isFullyVerified(): bool
    {
        return $this->location_verified && $this->face_verified;
    }

    /**
     * Get the full URL for face image
     */
    public function getFaceImageUrlAttribute(): ?string
    {
        if (!$this->face_image_path) {
            return null;
        }

        return asset('storage/' . $this->face_image_path);
    }

    /**
     * Scope for suspicious records
     */
    public function scopeSuspicious($query)
    {
        return $query->where('is_suspicious', true);
    }

    /**
     * Scope for mock location records
     */
    public function scopeMockLocation($query)
    {
        return $query->where('is_mock_location', true);
    }

    /**
     * Scope for records from rooted devices
     */
    public function scopeRootedDevice($query)
    {
        return $query->where('is_rooted', true);
    }

    /**
     * Determine suspicious behaviors based on location data
     * Returns array of suspicious flags
     */
    public static function detectSuspiciousBehavior(array $locationData): array
    {
        $suspiciousFlags = [];

        // Flag 1: Mock location enabled
        if (!empty($locationData['is_mock_location'])) {
            $suspiciousFlags[] = 'mock_location_enabled';
        }

        // Flag 2: Rooted/Jailbroken device
        if (!empty($locationData['is_rooted'])) {
            $suspiciousFlags[] = 'rooted_device';
        }

        // Flag 3: GPS accuracy too low (> 100 meters is suspicious)
        if (isset($locationData['gps_accuracy']) && $locationData['gps_accuracy'] > 100) {
            $suspiciousFlags[] = 'low_gps_accuracy';
        }

        // Flag 4: Location data too old (> 30 seconds)
        if (isset($locationData['location_age_ms']) && $locationData['location_age_ms'] > 30000) {
            $suspiciousFlags[] = 'stale_location_data';
        }

        // Flag 5: Unrealistic speed (> 50 m/s = 180 km/h while checking in)
        if (isset($locationData['speed']) && $locationData['speed'] > 50) {
            $suspiciousFlags[] = 'unrealistic_speed';
        }

        // Flag 6: No WiFi connected when in office (optional, depends on implementation)
        // This would need to compare with known office WiFi SSIDs

        return $suspiciousFlags;
    }

    /**
     * Check if attendance should be flagged as suspicious
     */
    public static function shouldFlagAsSuspicious(array $locationData): bool
    {
        // Immediate red flags - always suspicious
        if (!empty($locationData['is_mock_location'])) {
            return true;
        }

        // Multiple minor flags make it suspicious
        $suspiciousFlags = self::detectSuspiciousBehavior($locationData);
        return count($suspiciousFlags) >= 2;
    }
}

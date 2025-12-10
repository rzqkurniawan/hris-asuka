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
        'face_image_path',
        'device_info',
        'attendance_date',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'location_verified' => 'boolean',
        'face_verified' => 'boolean',
        'face_confidence' => 'decimal:2',
        'attendance_date' => 'date',
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
}

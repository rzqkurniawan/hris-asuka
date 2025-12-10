<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AttendanceLocation extends Model
{
    use HasFactory;

    protected $table = 'attendance_locations';

    protected $fillable = [
        'name',
        'address',
        'latitude',
        'longitude',
        'radius_meters',
        'is_active',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'radius_meters' => 'integer',
        'is_active' => 'boolean',
    ];

    /**
     * Get attendance records for this location
     */
    public function attendanceRecords()
    {
        return $this->hasMany(AttendanceRecord::class, 'location_id');
    }

    /**
     * Scope for active locations only
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Calculate distance from given coordinates using Haversine formula
     * Returns distance in meters
     */
    public function distanceFrom(float $latitude, float $longitude): float
    {
        $earthRadius = 6371000; // Earth's radius in meters

        $latFrom = deg2rad($this->latitude);
        $lonFrom = deg2rad($this->longitude);
        $latTo = deg2rad($latitude);
        $lonTo = deg2rad($longitude);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $a = sin($latDelta / 2) * sin($latDelta / 2) +
             cos($latFrom) * cos($latTo) *
             sin($lonDelta / 2) * sin($lonDelta / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * Check if given coordinates are within the location radius
     */
    public function isWithinRadius(float $latitude, float $longitude): bool
    {
        return $this->distanceFrom($latitude, $longitude) <= $this->radius_meters;
    }

    /**
     * Find the nearest active location from given coordinates
     * Returns null if no active locations exist
     */
    public static function findNearest(float $latitude, float $longitude): ?self
    {
        $locations = self::active()->get();

        if ($locations->isEmpty()) {
            return null;
        }

        $nearest = null;
        $minDistance = PHP_FLOAT_MAX;

        foreach ($locations as $location) {
            $distance = $location->distanceFrom($latitude, $longitude);
            if ($distance < $minDistance) {
                $minDistance = $distance;
                $nearest = $location;
            }
        }

        return $nearest;
    }

    /**
     * Find location that contains the given coordinates (within radius)
     * Returns null if not within any location
     */
    public static function findByCoordinates(float $latitude, float $longitude): ?self
    {
        $locations = self::active()->get();

        foreach ($locations as $location) {
            if ($location->isWithinRadius($latitude, $longitude)) {
                return $location;
            }
        }

        return null;
    }
}

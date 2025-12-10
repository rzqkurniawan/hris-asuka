<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Anti-Fake GPS columns:
     * - is_mock_location: True if mock location provider detected (Android)
     * - is_rooted: True if device is rooted/jailbroken
     * - wifi_ssid: Connected WiFi network name for additional verification
     * - wifi_bssid: Connected WiFi MAC address for additional verification
     * - gps_accuracy: GPS accuracy in meters
     * - location_age_ms: How old the location data is in milliseconds
     * - location_provider: GPS provider type (gps, network, fused, etc)
     * - altitude: Altitude in meters if available
     * - speed: Speed in m/s if available
     * - suspicious_flags: JSON array of detected suspicious behaviors
     * - is_suspicious: Boolean flag if attendance is flagged as suspicious
     */
    public function up(): void
    {
        Schema::table('attendance_records', function (Blueprint $table) {
            // Mock location detection
            $table->boolean('is_mock_location')->default(false)->after('device_info');

            // Device integrity
            $table->boolean('is_rooted')->nullable()->after('is_mock_location');

            // WiFi verification (can be compared with known office WiFi)
            $table->string('wifi_ssid')->nullable()->after('is_rooted');
            $table->string('wifi_bssid')->nullable()->after('wifi_ssid');

            // GPS quality metrics
            $table->decimal('gps_accuracy', 8, 2)->nullable()->after('wifi_bssid');
            $table->unsignedBigInteger('location_age_ms')->nullable()->after('gps_accuracy');
            $table->string('location_provider', 50)->nullable()->after('location_age_ms');

            // Additional location data
            $table->decimal('altitude', 10, 2)->nullable()->after('location_provider');
            $table->decimal('speed', 8, 2)->nullable()->after('altitude');

            // Suspicious detection
            $table->json('suspicious_flags')->nullable()->after('speed');
            $table->boolean('is_suspicious')->default(false)->after('suspicious_flags');

            // Index for filtering suspicious records
            $table->index('is_suspicious');
            $table->index('is_mock_location');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendance_records', function (Blueprint $table) {
            $table->dropIndex(['is_suspicious']);
            $table->dropIndex(['is_mock_location']);

            $table->dropColumn([
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
            ]);
        });
    }
};

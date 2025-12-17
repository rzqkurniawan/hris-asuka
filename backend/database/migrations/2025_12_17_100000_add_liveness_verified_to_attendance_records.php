<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * This migration adds liveness_verified field for anti-spoofing protection.
     * Liveness detection prevents photo/video attacks by requiring:
     * - Eye blink detection
     * - Head movement detection
     * - Natural micro-movement analysis
     */
    public function up(): void
    {
        Schema::table('attendance_records', function (Blueprint $table) {
            $table->boolean('liveness_verified')->default(false)->after('face_confidence')
                ->comment('Whether liveness detection passed (anti-spoofing)');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendance_records', function (Blueprint $table) {
            $table->dropColumn('liveness_verified');
        });
    }
};

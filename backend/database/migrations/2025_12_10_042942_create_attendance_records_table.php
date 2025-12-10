<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('attendance_records', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('employee_id');
            $table->unsignedBigInteger('user_id');
            $table->enum('check_type', ['check_in', 'check_out']);
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->foreignId('location_id')->constrained('attendance_locations');
            $table->boolean('location_verified')->default(false);
            $table->boolean('face_verified')->default(false);
            $table->decimal('face_confidence', 5, 2)->nullable();
            $table->string('face_image_path')->nullable();
            $table->string('device_info')->nullable();
            $table->date('attendance_date');
            $table->timestamps();

            // Unique constraint: 1 check_in dan 1 check_out per employee per hari
            $table->unique(['employee_id', 'check_type', 'attendance_date'], 'unique_daily_attendance');

            // Index untuk query cepat
            $table->index(['employee_id', 'attendance_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendance_records');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * 
     * Local users table hanya untuk credential.
     * Data employee (fullname, email, dll) ada di c3ais.ki_employee
     */
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('employee_number', 50)->unique()->comment('Reference to c3ais.ki_employee.employee_number');
            $table->string('username', 100)->unique()->comment('Login username');
            $table->string('password')->comment('Hashed password');
            $table->boolean('is_active')->default(true)->comment('User active status');
            $table->timestamp('last_login_at')->nullable()->comment('Last login timestamp');
            $table->timestamps();

            // Indexes
            $table->index('employee_number');
            $table->index('username');
            $table->index('is_active');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};

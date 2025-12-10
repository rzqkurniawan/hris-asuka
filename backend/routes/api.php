<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\EmployeePhotoController;
use App\Http\Controllers\Api\OvertimeController;
use App\Http\Controllers\Api\PaySlipController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\EmployeeLeaveController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Health check
Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'HRIS Asuka API is running',
        'timestamp' => now()->toISOString(),
        'version' => '1.0.0',
    ]);
});

// Public routes (no authentication required)
Route::prefix('auth')->group(function () {
    Route::get('/employees', [AuthController::class, 'getEmployees']); // Get available employees for registration
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

// Protected routes (require authentication)
Route::middleware('auth:api')->group(function () {

    // Employee photo endpoint (protected)
    Route::get('/employees/photo/{filename}', [EmployeePhotoController::class, 'getPhoto']);

    // Auth routes
    Route::prefix('auth')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });

    // Employee routes
    Route::prefix('employee')->group(function () {
        Route::get('/data', [EmployeeController::class, 'getEmployeeData']);
        Route::get('/family', [EmployeeController::class, 'getFamilyData']);
        Route::get('/position-history', [EmployeeController::class, 'getPositionHistory']);
        Route::get('/training-history', [EmployeeController::class, 'getTrainingHistory']);
        Route::get('/work-experience', [EmployeeController::class, 'getWorkExperience']);
        Route::get('/education-history', [EmployeeController::class, 'getEducationHistory']);
    });

    // User profile routes (will be implemented later)
    Route::prefix('profile')->group(function () {
        // Route::get('/', [ProfileController::class, 'index']);
        // Route::put('/', [ProfileController::class, 'update']);
    });

    // Overtime routes
    Route::prefix('overtime')->group(function () {
        Route::get('/', [OvertimeController::class, 'getOvertimeList']);
        Route::get('/{id}', [OvertimeController::class, 'getOvertimeDetail']);
    });

    // Employee Leave routes (CRUD with c3ais database)
    Route::prefix('leave')->group(function () {
        Route::get('/categories', [EmployeeLeaveController::class, 'getLeaveCategories']);
        Route::get('/employees', [EmployeeLeaveController::class, 'getActiveEmployees']);
        Route::get('/', [EmployeeLeaveController::class, 'getEmployeeLeaves']);
        Route::get('/{id}', [EmployeeLeaveController::class, 'getEmployeeLeaveDetail']);
        Route::post('/', [EmployeeLeaveController::class, 'createEmployeeLeave']);
        Route::put('/{id}', [EmployeeLeaveController::class, 'updateEmployeeLeave']);
        Route::delete('/{id}', [EmployeeLeaveController::class, 'deleteEmployeeLeave']);
    });

    // Attendance routes
    Route::prefix('attendance')->group(function () {
        Route::get('/periods', [AttendanceController::class, 'getAvailablePeriods']);
        Route::get('/summary', [AttendanceController::class, 'getAttendanceSummary']);
        Route::get('/detail', [AttendanceController::class, 'getAttendanceDetail']);
    });

    // Payslip routes
    Route::prefix('payslip')->group(function () {
        Route::get('/periods', [PaySlipController::class, 'getAvailablePeriods']);
        Route::get('/detail', [PaySlipController::class, 'getPaySlipDetail']);
    });
});

<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\EmployeePhotoController;
use App\Http\Controllers\Api\OvertimeController;
use App\Http\Controllers\Api\PaySlipController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\MobileAttendanceController;
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

// Public employee photo endpoint (needed for registration face verification)
Route::get('/employees/photo/{filename}', [EmployeePhotoController::class, 'getPhoto']);

// Public routes (no authentication required) - with rate limiting for security
Route::prefix('auth')->group(function () {
    // Rate limit: 10 requests per minute for employee list
    Route::middleware('throttle:10,1')->group(function () {
        Route::get('/employees', [AuthController::class, 'getEmployees']);
    });

    // Rate limit: 5 requests per minute for registration (prevent spam)
    Route::middleware('throttle:5,1')->group(function () {
        Route::post('/register/get-avatar', [AuthController::class, 'getEmployeeAvatarForRegister']);
        Route::post('/register', [AuthController::class, 'register']);
    });

    // Rate limit: 5 requests per minute for login (prevent brute force)
    Route::middleware('throttle:5,1')->group(function () {
        Route::post('/login', [AuthController::class, 'login']);
    });

    // Forgot Password routes (rate limited for security)
    Route::prefix('forgot-password')->group(function () {
        // Rate limit: 5 requests per minute for identity verification
        Route::middleware('throttle:5,1')->group(function () {
            Route::post('/verify-identity', [AuthController::class, 'verifyIdentity']);
        });

        // Rate limit: 3 requests per minute for password reset
        Route::middleware('throttle:3,1')->group(function () {
            Route::post('/reset', [AuthController::class, 'resetPasswordWithFace']);
        });
    });
});

// Protected routes (require authentication)
Route::middleware('auth:api')->group(function () {

    // Auth routes
    Route::prefix('auth')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
        Route::post('/logout', [AuthController::class, 'logout']);

        // Rate limit: 3 requests per minute for password change (security)
        Route::middleware('throttle:3,1')->group(function () {
            Route::post('/change-password', [AuthController::class, 'changePassword']);
        });
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

    // Attendance routes (history from c3ais)
    Route::prefix('attendance')->group(function () {
        Route::get('/periods', [AttendanceController::class, 'getAvailablePeriods']);
        Route::get('/summary', [AttendanceController::class, 'getAttendanceSummary']);
        Route::get('/detail', [AttendanceController::class, 'getAttendanceDetail']);
    });

    // Mobile Attendance routes (check-in/check-out with GPS & Face Recognition)
    Route::prefix('mobile-attendance')->group(function () {
        Route::get('/locations', [MobileAttendanceController::class, 'getLocations']);
        Route::get('/today-status', [MobileAttendanceController::class, 'getTodayStatus']);
        Route::post('/validate-location', [MobileAttendanceController::class, 'validateLocation']);
        Route::get('/employee-avatar', [MobileAttendanceController::class, 'getEmployeeAvatar']);
        Route::post('/compare-face', [MobileAttendanceController::class, 'compareFace']);
        Route::post('/submit', [MobileAttendanceController::class, 'submitAttendance']);
        Route::get('/history', [MobileAttendanceController::class, 'getHistory']);
    });

    // Payslip routes
    Route::prefix('payslip')->group(function () {
        Route::get('/periods', [PaySlipController::class, 'getAvailablePeriods']);
        Route::get('/detail', [PaySlipController::class, 'getPaySlipDetail']);
    });
});

<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminController;
use App\Http\Controllers\Admin\AttendanceLocationController;
use App\Http\Controllers\Admin\AttendanceRecordController;

Route::get('/', function () {
    return view('welcome');
});

// Admin routes
Route::prefix('admin')->name('admin.')->group(function () {
    // Login routes (no middleware)
    Route::get('login', [AdminController::class, 'showLogin'])->name('login');
    Route::post('login', [AdminController::class, 'login'])->name('login.post');

    // Protected admin routes
    Route::middleware('admin')->group(function () {
        Route::get('dashboard', [AdminController::class, 'dashboard'])->name('dashboard');
        Route::post('logout', [AdminController::class, 'logout'])->name('logout');

        // User management
        Route::get('users', [AdminController::class, 'users'])->name('users');
        Route::get('users/create', [AdminController::class, 'createUser'])->name('users.create');
        Route::post('users', [AdminController::class, 'storeUser'])->name('users.store');
        Route::get('users/{id}/edit', [AdminController::class, 'editUser'])->name('users.edit');
        Route::put('users/{id}', [AdminController::class, 'updateUser'])->name('users.update');
        Route::delete('users/{id}', [AdminController::class, 'deleteUser'])->name('users.delete');
        Route::get('users/export', [AdminController::class, 'exportUsers'])->name('users.export');

        // Attendance Locations management
        Route::get('attendance-locations', [AttendanceLocationController::class, 'index'])->name('attendance-locations.index');
        Route::get('attendance-locations/create', [AttendanceLocationController::class, 'create'])->name('attendance-locations.create');
        Route::post('attendance-locations', [AttendanceLocationController::class, 'store'])->name('attendance-locations.store');
        Route::get('attendance-locations/{id}/edit', [AttendanceLocationController::class, 'edit'])->name('attendance-locations.edit');
        Route::put('attendance-locations/{id}', [AttendanceLocationController::class, 'update'])->name('attendance-locations.update');
        Route::delete('attendance-locations/{id}', [AttendanceLocationController::class, 'destroy'])->name('attendance-locations.destroy');

        // Attendance Records management (Check Clock History)
        Route::get('attendance-records', [AttendanceRecordController::class, 'index'])->name('attendance-records.index');
        Route::get('attendance-records/create', [AttendanceRecordController::class, 'create'])->name('attendance-records.create');
        Route::post('attendance-records', [AttendanceRecordController::class, 'store'])->name('attendance-records.store');
        Route::get('attendance-records/export', [AttendanceRecordController::class, 'export'])->name('attendance-records.export');
        Route::get('attendance-records/{id}', [AttendanceRecordController::class, 'show'])->name('attendance-records.show');
        Route::get('attendance-records/{id}/edit', [AttendanceRecordController::class, 'edit'])->name('attendance-records.edit');
        Route::put('attendance-records/{id}', [AttendanceRecordController::class, 'update'])->name('attendance-records.update');
        Route::delete('attendance-records/{id}', [AttendanceRecordController::class, 'destroy'])->name('attendance-records.destroy');
    });
});

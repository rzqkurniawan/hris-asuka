<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Employee;
use App\Models\MobileToken;
use App\Models\UserPreference;
use App\Models\AuditLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthController extends Controller
{
    /**
     * Get list of employees for registration dropdown
     * Only returns employees who don't have user accounts yet
     */
    public function getEmployees(Request $request)
    {
        try {
            // Security: Require minimum 3 characters search to prevent data enumeration
            if (!$request->has('search') || strlen(trim($request->search)) < 3) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'employees' => [],
                        'total' => 0,
                        'message' => 'Please enter at least 3 characters to search',
                    ],
                ]);
            }

            // Get users who already have accounts
            $usersWithAccounts = User::pluck('employee_id')
                ->filter()
                ->toArray();

            $search = trim($request->search);

            // Security: Only return minimal data needed (employee_id and fullname)
            // employee_number removed from public endpoint to prevent data leakage
            $employees = \DB::connection('c3ais')
                ->table('ki_employee')
                ->select('employee_id', 'fullname')
                ->where('working_status', 'Active')
                ->whereNotIn('employee_id', $usersWithAccounts)
                ->where(function ($q) use ($search) {
                    $q->where('fullname', 'like', "%{$search}%");
                })
                ->orderBy('fullname', 'asc')
                ->limit(20) // Hard limit for security
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'employees' => $employees,
                    'total' => $employees->count(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch employees',
            ], 500);
        }
    }

    /**
     * Register a new user
     * Request: employee_id (from c3ais), nik, username, password
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'employee_id' => 'required|integer|unique:users',
            'nik' => 'required|numeric|digits:16',
            'username' => [
                'required',
                'string',
                'min:6',
                'max:12',
                'unique:users',
                'regex:/^[a-zA-Z0-9]+$/', // Only alphanumeric
            ],
            'password' => [
                'required',
                'string',
                'min:12',
                'max:128',
                'confirmed',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#^()_+=\[\]{};:\'",.<>\/\\|`~-]).+$/', // Uppercase, lowercase, number, special char
            ],
        ], [
            'username.regex' => 'Username hanya boleh mengandung huruf dan angka',
            'username.min' => 'Username minimal 6 karakter',
            'username.max' => 'Username maksimal 12 karakter',
            'password.regex' => 'Password harus mengandung huruf besar, huruf kecil, angka, dan karakter khusus (!@#$%^&*)',
            'password.min' => 'Password minimal 12 karakter',
            'password.max' => 'Password maksimal 128 karakter',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Check for common weak passwords (updated for 12+ char policy)
            $commonPasswords = [
                '123456789012',
                '1234567890123',
                '12345678901234',
                'password1234',
                'password12345',
                'password123456',
                'qwerty123456',
                'qwertyuiop12',
                'admin1234567',
                'administrator1',
                'letmein12345',
                'welcome12345',
                'iloveyou1234',
                'sunshine1234',
                'princess1234',
                'football1234',
                'abc123456789',
                'monkey123456',
                'shadow123456',
                'master123456',
            ];

            $lowercasePassword = strtolower($request->password);
            foreach ($commonPasswords as $commonPass) {
                if (strtolower($commonPass) === $lowercasePassword) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Password terlalu umum. Gunakan kombinasi yang lebih unik',
                        'errors' => [
                            'password' => ['Password terlalu umum. Gunakan kombinasi yang lebih unik']
                        ],
                    ], 422);
                }
            }

            // Validate employee exists in c3ais database
            $employee = Employee::find($request->employee_id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee not found in database',
                ], 404);
            }

            // Validate NIK matches sin_num in database
            if ($employee->sin_num !== $request->nik) {
                return response()->json([
                    'success' => false,
                    'message' => 'NIK tidak cocok dengan data karyawan',
                ], 422);
            }

            // Create user account (only credential)
            $user = User::create([
                'employee_id' => $request->employee_id,
                'employee_number' => $employee->employee_number,
                'username' => $request->username,
                'password' => Hash::make($request->password),
                'is_active' => true,
            ]);

            // Create default preferences
            UserPreference::create([
                'user_id' => $user->id,
                'theme_mode' => 'system',
                'language' => 'en',
                'notification_enabled' => true,
                'biometric_enabled' => false,
            ]);

            // Log registration
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'register',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'response_status' => 201,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'User registered successfully',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'username' => $user->username,
                        'employee_id' => $user->employee_id,
                        'employee_number' => $employee->employee_number, // Badge ID (K01122, P00965, etc)
                        'fullname' => $employee->fullname, // From c3ais
                        'position' => $employee->jobGrade ? $employee->jobGrade->job_grade_name : null, // From c3ais
                        'working_period' => $employee->working_period, // Calculated from employment_date
                        'investment_amount' => $employee->investment_amount, // From latest employee_report
                    ],
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Registration failed',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Login user and create token
     * Request: username, password (no email login)
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string',
            'password' => 'required|string',
            'device_id' => 'nullable|string',
            'device_name' => 'nullable|string',
            'device_type' => 'required|in:android,ios',
            'fcm_token' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Find user by username only
            $user = User::where('username', $request->username)->first();

            if (!$user || !Hash::check($request->password, $user->password)) {
                AuditLog::create([
                    'action' => 'login_failed',
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'request_data' => ['username' => $request->username],
                    'response_status' => 401,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Invalid credentials',
                ], 401);
            }

            // Check if user is active
            if (!$user->isActive()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Account is inactive',
                ], 403);
            }

            // Get employee data from c3ais
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Generate JWT token
            $token = JWTAuth::fromUser($user);
            $ttl = config('jwt.ttl'); // minutes
            $expiresAt = now()->addMinutes($ttl);

            // Save mobile token
            MobileToken::create([
                'user_id' => $user->id,
                'token' => $token,
                'device_id' => $request->device_id,
                'device_name' => $request->device_name,
                'device_type' => $request->device_type,
                'fcm_token' => $request->fcm_token,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'expires_at' => $expiresAt,
                'last_used_at' => now(),
            ]);

            // Update last login
            $user->updateLastLogin();

            // Log successful login
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'login',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'response_status' => 200,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'username' => $user->username,
                        'employee_id' => $user->employee_id,
                        'employee_number' => $employee->employee_number, // Badge ID (K01122, P00965, etc)
                        'fullname' => $employee->fullname, // From c3ais
                        'position' => $employee->jobGrade ? $employee->jobGrade->job_grade_name : null, // From c3ais
                        'working_period' => $employee->working_period, // Calculated from employment_date
                        'investment_amount' => $employee->investment_amount, // From latest employee_report
                        'employee_file_name' => $employee->employee_file_name,
                        'identity_file_name' => $employee->identity_file_name,
                    ],
                    'token' => [
                        'access_token' => $token,
                        'token_type' => 'bearer',
                        'expires_in' => $ttl * 60, // seconds
                        'expires_at' => $expiresAt->toISOString(),
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Login failed',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get authenticated user info
     */
    public function me(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            return response()->json([
                'success' => true,
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'username' => $user->username,
                        'employee_id' => $user->employee_id,
                        'fullname' => $employee ? $employee->fullname : null,
                        'employee_number' => $employee ? $employee->employee_number : null,
                        'position' => ($employee && $employee->jobGrade) ? $employee->jobGrade->job_grade_name : null, // From c3ais
                        'working_period' => $employee ? $employee->working_period : '0Y 0M', // Calculated from employment_date
                        'investment_amount' => $employee ? $employee->investment_amount : 'Rp 0', // From latest employee_report
                        'employee_file_name' => $employee ? $employee->employee_file_name : null,
                        'identity_file_name' => $employee ? $employee->identity_file_name : null,
                        'is_active' => $user->is_active,
                        'last_login_at' => $user->last_login_at,
                        'created_at' => $user->created_at,
                    ],
                    'preferences' => $user->preferences,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch user data',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Refresh JWT token
     */
    public function refresh(Request $request)
    {
        try {
            $token = JWTAuth::parseToken()->refresh();
            $ttl = config('jwt.ttl');
            $expiresAt = now()->addMinutes($ttl);

            // Update mobile token
            $user = $request->user();
            $oldToken = JWTAuth::getToken()->get();

            $mobileToken = MobileToken::where('token', $oldToken)->first();
            if ($mobileToken) {
                $mobileToken->update([
                    'token' => $token,
                    'expires_at' => $expiresAt,
                    'last_used_at' => now(),
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Token refreshed successfully',
                'data' => [
                    'token' => [
                        'access_token' => $token,
                        'token_type' => 'bearer',
                        'expires_in' => $ttl * 60,
                        'expires_at' => $expiresAt->toISOString(),
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to refresh token',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Logout user
     */
    public function logout(Request $request)
    {
        try {
            $user = $request->user();
            $token = JWTAuth::getToken()->get();

            // Delete mobile token
            MobileToken::where('token', $token)->delete();

            // Invalidate JWT token
            JWTAuth::parseToken()->invalidate();

            // Log logout
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'logout',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'response_status' => 200,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Logout successful',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Logout failed',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

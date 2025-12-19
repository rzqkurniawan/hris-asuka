<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Employee;
use App\Models\MobileToken;
use App\Models\UserPreference;
use App\Models\AuditLog;
use App\Services\FaceComparisonService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
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
     * Get employee avatar for registration face verification
     * Request: employee_id
     * Note: NIK verification removed - face recognition prevents impersonation
     */
    public function getEmployeeAvatarForRegister(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'employee_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Check if employee_id already has user account
            $existingUser = User::where('employee_id', $request->employee_id)->first();
            if ($existingUser) {
                return response()->json([
                    'success' => false,
                    'message' => 'Karyawan ini sudah memiliki akun',
                ], 422);
            }

            // Get employee data
            $employee = Employee::find($request->employee_id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data karyawan tidak ditemukan',
                ], 404);
            }

            // Check if employee has photo for face verification
            if (!$employee->employee_file_name) {
                return response()->json([
                    'success' => false,
                    'message' => 'Foto karyawan tidak tersedia. Hubungi HRD untuk update foto.',
                ], 422);
            }

            return response()->json([
                'success' => true,
                'message' => 'Employee avatar retrieved',
                'data' => [
                    'employee_name' => $employee->fullname,
                    'avatar_url' => url("/api/employees/photo/{$employee->employee_file_name}"),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data karyawan',
            ], 500);
        }
    }

    /**
     * Register a new user
     * Request: employee_id (from c3ais), username, password
     * Note: NIK verification removed - face recognition prevents impersonation
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'employee_id' => 'required|integer|unique:users',
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
            // Face verification fields (required for registration)
            'face_image' => 'required|string',
            'face_confidence' => 'required|numeric|min:80|max:100',
            'liveness_verified' => 'required|boolean',
        ], [
            'username.regex' => 'Username hanya boleh mengandung huruf dan angka',
            'username.min' => 'Username minimal 6 karakter',
            'username.max' => 'Username maksimal 12 karakter',
            'password.regex' => 'Password harus mengandung huruf besar, huruf kecil, angka, dan karakter khusus (!@#$%^&*)',
            'password.min' => 'Password minimal 12 karakter',
            'password.max' => 'Password maksimal 128 karakter',
            'face_image.required' => 'Verifikasi wajah diperlukan untuk registrasi',
            'face_confidence.min' => 'Tingkat kecocokan wajah minimal 80%',
            'liveness_verified.required' => 'Verifikasi liveness diperlukan',
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

            // Validate employee has photo for face verification
            if (!$employee->employee_file_name) {
                return response()->json([
                    'success' => false,
                    'message' => 'Foto karyawan tidak tersedia. Hubungi HRD untuk update foto.',
                ], 422);
            }

            // Validate liveness verification passed
            if (!$request->boolean('liveness_verified')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Verifikasi liveness gagal. Pastikan Anda mengedipkan mata dan menggerakkan kepala.',
                ], 400);
            }

            // Perform actual face comparison with employee's stored photo
            $faceComparisonService = new FaceComparisonService();

            // Get the path to the employee's stored photo (from photo-cache synced from GCP)
            $employeePhotoPath = storage_path("app/photo-cache/{$employee->employee_file_name}");

            // Check if photo exists
            if (!file_exists($employeePhotoPath)) {
                Log::warning('Employee photo not found for face comparison', [
                    'employee_id' => $employee->employee_id,
                    'employee_file_name' => $employee->employee_file_name,
                    'tried_path' => $employeePhotoPath,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Foto karyawan tidak ditemukan untuk verifikasi wajah. Hubungi HRD.',
                ], 422);
            }

            // Compare faces
            $faceComparisonResult = $faceComparisonService->compareFaces(
                $employeePhotoPath,
                $request->face_image
            );

            Log::info('Face comparison result for registration', [
                'employee_id' => $employee->employee_id,
                'result' => $faceComparisonResult,
            ]);

            // Check if face comparison was successful
            if (!$faceComparisonResult['success']) {
                return response()->json([
                    'success' => false,
                    'message' => $faceComparisonResult['message'],
                    'data' => [
                        'face_comparison_error' => true,
                    ],
                ], 400);
            }

            // Check if faces match (minimum 75% similarity required)
            if (!$faceComparisonResult['match']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Wajah tidak cocok dengan foto karyawan terdaftar. Pastikan Anda adalah karyawan yang benar.',
                    'data' => [
                        'face_confidence' => $faceComparisonResult['confidence'],
                        'min_required' => $faceComparisonService->getMinConfidence(),
                    ],
                ], 400);
            }

            // Save face image for audit
            $faceImagePath = $this->saveFaceImage(
                $request->face_image,
                $request->employee_id,
                'register'
            );

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

            // Log registration with face verification data
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'register',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'request_data' => [
                    'face_confidence' => $faceComparisonResult['confidence'], // Server-side comparison
                    'face_distance' => $faceComparisonResult['distance'] ?? null,
                    'liveness_verified' => $request->boolean('liveness_verified'),
                    'face_image_path' => $faceImagePath,
                ],
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

    /**
     * Change user password
     * Request: current_password, new_password, password_confirmation
     */
    public function changePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'new_password' => [
                'required',
                'string',
                'min:12',
                'max:128',
                'confirmed',
                'different:current_password',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#^()_+=\[\]{};:\'",.<>\/\\|`~-]).+$/',
            ],
        ], [
            'new_password.regex' => 'Password harus mengandung huruf besar, huruf kecil, angka, dan karakter khusus (!@#$%^&*)',
            'new_password.min' => 'Password minimal 12 karakter',
            'new_password.max' => 'Password maksimal 128 karakter',
            'new_password.different' => 'Password baru harus berbeda dengan password lama',
            'new_password.confirmed' => 'Konfirmasi password tidak cocok',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $user = $request->user();

            // Verify current password
            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Password lama tidak sesuai',
                    'errors' => [
                        'current_password' => ['Password lama tidak sesuai']
                    ],
                ], 422);
            }

            // Check for common weak passwords
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

            $lowercasePassword = strtolower($request->new_password);
            foreach ($commonPasswords as $commonPass) {
                if (strtolower($commonPass) === $lowercasePassword) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Password terlalu umum. Gunakan kombinasi yang lebih unik',
                        'errors' => [
                            'new_password' => ['Password terlalu umum. Gunakan kombinasi yang lebih unik']
                        ],
                    ], 422);
                }
            }

            // Update password
            $user->password = Hash::make($request->new_password);
            $user->save();

            // Log password change
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'change_password',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'response_status' => 200,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Password berhasil diubah',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengubah password',
            ], 500);
        }
    }

    /**
     * Verify user identity for forgot password (Step 1)
     * Request: username, nik
     * Returns: reset_token, employee_avatar_url
     */
    public function verifyIdentity(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string',
            'nik' => 'required|numeric|digits:16',
        ], [
            'nik.digits' => 'NIK harus 16 digit',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Find user by username
            $user = User::where('username', $request->username)->first();

            if (!$user) {
                // Log failed attempt
                AuditLog::create([
                    'action' => 'forgot_password_failed',
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'request_data' => ['username' => $request->username, 'reason' => 'user_not_found'],
                    'response_status' => 404,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Username tidak ditemukan',
                ], 404);
            }

            // Check if user is active
            if (!$user->is_active) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akun tidak aktif. Hubungi administrator.',
                ], 403);
            }

            // Get employee data from c3ais
            $employee = Employee::find($user->employee_id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Data karyawan tidak ditemukan',
                ], 404);
            }

            // Verify NIK matches sin_num
            if ($employee->sin_num !== $request->nik) {
                // Log failed attempt
                AuditLog::create([
                    'user_id' => $user->id,
                    'action' => 'forgot_password_failed',
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'request_data' => ['reason' => 'nik_mismatch'],
                    'response_status' => 422,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'NIK tidak cocok dengan data karyawan',
                ], 422);
            }

            // Check if employee has avatar for face verification
            if (!$employee->identity_file_name) {
                return response()->json([
                    'success' => false,
                    'message' => 'Foto karyawan tidak tersedia. Hubungi HRD untuk update foto.',
                ], 422);
            }

            // Generate reset token (valid for 10 minutes)
            $resetToken = bin2hex(random_bytes(32));
            $expiresAt = now()->addMinutes(10);

            // Store reset token in cache
            \Cache::put(
                "password_reset:{$resetToken}",
                [
                    'user_id' => $user->id,
                    'employee_id' => $employee->employee_id,
                    'expires_at' => $expiresAt->toISOString(),
                ],
                $expiresAt
            );

            // Log successful identity verification
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'forgot_password_identity_verified',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'response_status' => 200,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Identitas terverifikasi. Silakan lakukan verifikasi wajah.',
                'data' => [
                    'reset_token' => $resetToken,
                    'expires_at' => $expiresAt->toISOString(),
                    'employee_name' => $employee->fullname,
                    'avatar_url' => url("/api/employees/photo/{$employee->identity_file_name}"),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal memverifikasi identitas',
            ], 500);
        }
    }

    /**
     * Reset password with face verification (Step 2)
     * Request: reset_token, face_image, face_confidence, liveness_verified, new_password, password_confirmation
     */
    public function resetPasswordWithFace(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reset_token' => 'required|string',
            'face_image' => 'required|string', // Base64 encoded
            'face_confidence' => 'required|numeric|between:0,100',
            'liveness_verified' => 'required|boolean',
            'new_password' => [
                'required',
                'string',
                'min:12',
                'max:128',
                'confirmed',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#^()_+=\[\]{};:\'",.<>\/\\|`~-]).+$/',
            ],
        ], [
            'new_password.regex' => 'Password harus mengandung huruf besar, huruf kecil, angka, dan karakter khusus (!@#$%^&*)',
            'new_password.min' => 'Password minimal 12 karakter',
            'new_password.max' => 'Password maksimal 128 karakter',
            'new_password.confirmed' => 'Konfirmasi password tidak cocok',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            // Validate reset token
            $tokenData = \Cache::get("password_reset:{$request->reset_token}");

            if (!$tokenData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token tidak valid atau sudah kadaluarsa. Silakan ulangi dari awal.',
                ], 422);
            }

            // Validate liveness detection
            if (!$request->boolean('liveness_verified')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Verifikasi liveness gagal. Pastikan Anda mengedipkan mata dan menggerakkan kepala.',
                ], 400);
            }

            // Get employee data for face comparison
            $employee = Employee::find($tokenData['employee_id']);
            if (!$employee || !$employee->identity_file_name) {
                return response()->json([
                    'success' => false,
                    'message' => 'Foto karyawan tidak tersedia untuk verifikasi wajah.',
                ], 422);
            }

            // Perform actual face comparison with employee's stored photo
            $faceComparisonService = new FaceComparisonService();
            $employeePhotoPath = storage_path("app/photo-cache/{$employee->identity_file_name}");

            // Check if photo exists
            if (!file_exists($employeePhotoPath)) {
                Log::warning('Employee photo not found for password reset face comparison', [
                    'employee_id' => $employee->employee_id,
                    'identity_file_name' => $employee->identity_file_name,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Foto karyawan tidak ditemukan untuk verifikasi wajah. Hubungi HRD.',
                ], 422);
            }

            // Compare faces
            $faceComparisonResult = $faceComparisonService->compareFaces(
                $employeePhotoPath,
                $request->face_image
            );

            Log::info('Face comparison result for password reset', [
                'user_id' => $tokenData['user_id'],
                'employee_id' => $employee->employee_id,
                'result' => $faceComparisonResult,
            ]);

            // Check if face comparison was successful
            if (!$faceComparisonResult['success']) {
                return response()->json([
                    'success' => false,
                    'message' => $faceComparisonResult['message'],
                    'data' => [
                        'face_comparison_error' => true,
                    ],
                ], 400);
            }

            // Check if faces match (minimum 75% similarity required)
            if (!$faceComparisonResult['match']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Wajah tidak cocok dengan foto karyawan terdaftar.',
                    'data' => [
                        'face_confidence' => $faceComparisonResult['confidence'],
                        'min_required' => $faceComparisonService->getMinConfidence(),
                    ],
                ], 400);
            }

            // Check for common weak passwords
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

            $lowercasePassword = strtolower($request->new_password);
            foreach ($commonPasswords as $commonPass) {
                if (strtolower($commonPass) === $lowercasePassword) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Password terlalu umum. Gunakan kombinasi yang lebih unik',
                        'errors' => [
                            'new_password' => ['Password terlalu umum. Gunakan kombinasi yang lebih unik']
                        ],
                    ], 422);
                }
            }

            // Get user
            $user = User::find($tokenData['user_id']);

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User tidak ditemukan',
                ], 404);
            }

            // Save face image for audit
            $faceImagePath = $this->saveFaceImage(
                $request->face_image,
                $user->id,
                'password_reset'
            );

            // Update password
            $user->password = Hash::make($request->new_password);
            $user->save();

            // Invalidate reset token
            \Cache::forget("password_reset:{$request->reset_token}");

            // Revoke all existing tokens (logout from all devices)
            MobileToken::where('user_id', $user->id)->delete();

            // Log password reset
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'forgot_password_reset',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'request_data' => [
                    'face_confidence' => $faceComparisonResult['confidence'], // Server-side comparison
                    'face_distance' => $faceComparisonResult['distance'] ?? null,
                    'liveness_verified' => $request->boolean('liveness_verified'),
                    'face_image_path' => $faceImagePath,
                ],
                'response_status' => 200,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Password berhasil direset. Silakan login dengan password baru.',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mereset password',
            ], 500);
        }
    }

    /**
     * Save base64 face image to storage
     */
    private function saveFaceImage(string $base64Image, int $userId, string $action): string
    {
        // Remove data URL prefix if exists
        if (strpos($base64Image, 'base64,') !== false) {
            $base64Image = explode('base64,', $base64Image)[1];
        }

        $imageData = base64_decode($base64Image);
        $date = now()->format('Y-m-d');
        $timestamp = now()->format('His');
        $filename = "face_verification/{$date}/{$userId}_{$action}_{$timestamp}.jpg";

        \Storage::disk('public')->put($filename, $imageData);

        return $filename;
    }
}

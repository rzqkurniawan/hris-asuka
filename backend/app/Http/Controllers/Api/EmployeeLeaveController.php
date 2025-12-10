<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmployeeLeave;
use App\Models\LeaveCategory;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class EmployeeLeaveController extends Controller
{
    /**
     * Generate employee leave number with format ASK-EL-YY.NNNN
     *
     * @return string
     */
    private function generateEmployeeLeaveNumber()
    {
        $year = date('y'); // 25 for 2025
        $prefix = "ASK-EL-{$year}.";

        // Get last number for this year
        $lastLeave = DB::connection('c3ais_write')
            ->table('ki_employee_leave')
            ->where('employee_leave_number', 'LIKE', $prefix . '%')
            ->orderBy('employee_leave_number', 'desc')
            ->first();

        if ($lastLeave && $lastLeave->employee_leave_number) {
            // Extract number after the last dot
            $parts = explode('.', $lastLeave->employee_leave_number);
            $lastNumber = (int) end($parts);
            $newNumber = $lastNumber + 1;
        } else {
            // First number for this year
            $newNumber = 1;
        }

        // Format: ASK-EL-25.0001
        return $prefix . str_pad($newNumber, 4, '0', STR_PAD_LEFT);
    }

    /**
     * Get all active employees for leave form (substitute selection)
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getActiveEmployees()
    {
        try {
            $employees = DB::connection('c3ais')
                ->table('ki_employee')
                ->where('working_status', 'Active')
                ->select('employee_id', 'employee_number', 'fullname')
                ->orderBy('fullname', 'asc')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Employees retrieved successfully',
                'data' => $employees,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve employees',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get all leave categories
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getLeaveCategories()
    {
        try {
            $categories = LeaveCategory::where('is_active', 1)
                ->select('leave_category_id', 'leave_category_name', 'unit', 'report_symbol')
                ->orderBy('leave_category_name', 'asc')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Leave categories retrieved successfully',
                'data' => $categories,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve leave categories',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get employee leaves list for authenticated user
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getEmployeeLeaves(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user->employee_id) {
                // Fallback: try to get employee_id from ki_employee using employee_number
                $employeeData = DB::connection('c3ais')
                    ->table('ki_employee')
                    ->where('employee_number', $user->employee_number)
                    ->select('employee_id')
                    ->first();

                if ($employeeData) {
                    $user->employee_id = $employeeData->employee_id;
                } else {
                    return response()->json([
                        'success' => false,
                        'message' => 'Employee data not found',
                    ], 404);
                }
            }

            // Get employee leaves with category info
            // Only show leaves with employee_leave_number (exclude empty/null numbers)
            // Show all statuses except 'Hangus' (expired) and 'Tidak Aktif' (deleted)
            $leaves = DB::connection('c3ais_write')
                ->table('ki_employee_leave as el')
                ->leftJoin('ki_leave_category as lc', 'el.leave_category_id', '=', 'lc.leave_category_id')
                ->where('el.employee_id', $user->employee_id)
                ->whereNotIn('el.status', ['Hangus', 'Tidak Aktif'])
                ->whereNotNull('el.employee_leave_number')
                ->where('el.employee_leave_number', '!=', '')
                ->select(
                    'el.employee_leave_id',
                    'el.employee_leave_number',
                    'el.leave_category_id',
                    'lc.leave_category_name',
                    'lc.report_symbol',
                    DB::raw("CASE WHEN el.start_leave = '0000-00-00' OR el.start_leave IS NULL THEN NULL ELSE el.start_leave END as date_begin"),
                    DB::raw("CASE WHEN el.date_leave = '0000-00-00' OR el.date_leave IS NULL THEN NULL ELSE el.date_leave END as date_end"),
                    'el.notes',
                    'el.is_approved',
                    'el.approved_date',
                    'el.status',
                    'el.sisa_cuti',
                    'el.created_date',
                    'el.address_leave',
                    'el.phone_leave'
                )
                ->orderBy('el.created_date', 'desc')
                ->get();

            // Format dates and calculate duration
            $formattedLeaves = $leaves->map(function ($leave) {
                // Parse dates - SQL CASE already converted '0000-00-00' to NULL
                $dateBegin = $leave->date_begin ? Carbon::parse($leave->date_begin) : null;
                $dateEnd = $leave->date_end ? Carbon::parse($leave->date_end) : null;

                // Calculate duration only if both dates are valid
                $duration = ($dateBegin && $dateEnd) ? $dateBegin->diffInDays($dateEnd) + 1 : 0;

                return [
                    'employee_leave_id' => (int) $leave->employee_leave_id,
                    'employee_leave_number' => $leave->employee_leave_number,
                    'leave_category_id' => (int) $leave->leave_category_id,
                    'leave_category_name' => $leave->leave_category_name ?? '-',
                    'report_symbol' => $leave->report_symbol ?? '-',
                    'date_begin' => $dateBegin ? $dateBegin->format('Y-m-d') : null,
                    'date_end' => $dateEnd ? $dateEnd->format('Y-m-d') : null,
                    'date_begin_formatted' => $dateBegin ? $dateBegin->format('d/m/Y') : '-',
                    'date_end_formatted' => $dateEnd ? $dateEnd->format('d/m/Y') : '-',
                    'duration_days' => (int) $duration,
                    'notes' => $leave->notes ?? '-',
                    'address_leave' => $leave->address_leave,
                    'phone_leave' => $leave->phone_leave,
                    'is_approved' => (bool) $leave->is_approved,
                    'approved_date' => $leave->approved_date ? Carbon::parse($leave->approved_date)->format('Y-m-d') : null,
                    'status' => $leave->status,
                    'sisa_cuti' => (int) $leave->sisa_cuti,
                    'created_date' => $leave->created_date ? Carbon::parse($leave->created_date)->format('Y-m-d H:i:s') : null,
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Employee leaves retrieved successfully',
                'data' => [
                    'total_records' => $formattedLeaves->count(),
                    'leaves' => $formattedLeaves,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve employee leaves',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get employee leave detail by ID
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function getEmployeeLeaveDetail($id)
    {
        try {
            $user = Auth::user();

            if (!$user->employee_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get leave detail with substitute employee info
            $leave = DB::connection('c3ais_write')
                ->table('ki_employee_leave as el')
                ->leftJoin('ki_leave_category as lc', 'el.leave_category_id', '=', 'lc.leave_category_id')
                ->leftJoin('ki_employee as emp_sub', 'el.subtitute_on_leave', '=', 'emp_sub.employee_id')
                ->where('el.employee_leave_id', $id)
                ->where('el.employee_id', $user->employee_id)
                ->select(
                    'el.*',
                    'lc.leave_category_name',
                    'lc.report_symbol',
                    'emp_sub.employee_id as substitute_employee_id',
                    'emp_sub.employee_number as substitute_employee_number',
                    'emp_sub.fullname as substitute_employee_name'
                )
                ->first();

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Leave not found',
                ], 404);
            }

            // Check if dates are valid (not 0000-00-00 or null)
            $isValidDateBegin = $leave->start_leave && $leave->start_leave !== '0000-00-00';
            $isValidDateEnd = $leave->date_leave && $leave->date_leave !== '0000-00-00';

            // Parse dates only if valid
            $dateBegin = $isValidDateBegin ? Carbon::parse($leave->start_leave) : null;
            $dateEnd = $isValidDateEnd ? Carbon::parse($leave->date_leave) : null;

            // Calculate duration only if both dates are valid
            $duration = ($dateBegin && $dateEnd) ? $dateBegin->diffInDays($dateEnd) + 1 : 0;

            // Prepare substitute employee info
            $substituteEmployee = null;
            if ($leave->substitute_employee_id) {
                $substituteEmployee = [
                    'employee_id' => (int) $leave->substitute_employee_id,
                    'employee_number' => $leave->substitute_employee_number ?? '-',
                    'fullname' => $leave->substitute_employee_name ?? '-',
                ];
            }

            $formattedLeave = [
                'employee_leave_id' => (int) $leave->employee_leave_id,
                'employee_leave_number' => $leave->employee_leave_number ?? '-',
                'leave_category_id' => (int) $leave->leave_category_id,
                'leave_category_name' => $leave->leave_category_name ?? '-',
                'report_symbol' => $leave->report_symbol ?? '-',
                'date_begin' => $dateBegin ? $dateBegin->format('Y-m-d') : null,
                'date_end' => $dateEnd ? $dateEnd->format('Y-m-d') : null,
                'date_begin_formatted' => $dateBegin ? $dateBegin->format('d/m/Y') : '-',
                'date_end_formatted' => $dateEnd ? $dateEnd->format('d/m/Y') : '-',
                'duration_days' => (int) $duration,
                'notes' => $leave->notes ?? '-',
                'address_leave' => $leave->address_leave ?? '-',
                'phone_leave' => $leave->phone_leave ?? '-',
                'substitute_employee' => $substituteEmployee,
                'is_approved' => (bool) $leave->is_approved,
                'approved_date' => $leave->approved_date ? Carbon::parse($leave->approved_date)->format('Y-m-d') : null,
                'status' => $leave->status,
                'sisa_cuti' => (int) $leave->sisa_cuti,
                'created_date' => $leave->created_date ? Carbon::parse($leave->created_date)->format('Y-m-d H:i:s') : null,
            ];

            return response()->json([
                'success' => true,
                'message' => 'Leave detail retrieved successfully',
                'data' => $formattedLeave,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve leave detail',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Create new employee leave
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function createEmployeeLeave(Request $request)
    {
        try {
            // Validate request
            $request->validate([
                'leave_category_id' => 'required|integer|exists:c3ais.ki_leave_category,leave_category_id',
                'substitute_employee_id' => 'nullable|integer|exists:c3ais.ki_employee,employee_id',
                'date_proposed' => 'required|date',
                'date_begin' => 'required|date|after_or_equal:date_proposed',
                'date_end' => 'required|date|after_or_equal:date_begin',
                'date_work' => 'required|date|after_or_equal:date_end',
                'notes' => 'nullable|string',
                'address_leave' => 'nullable|string',
                'phone_leave' => 'nullable|string',
            ]);

            $user = Auth::user();

            if (!$user->employee_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get employee for fullname
            $employee = $user->employee;

            // Get user_id from ki_user table (optional)
            $userData = DB::connection('c3ais')
                ->table('ki_user')
                ->where('employee_id', $user->employee_id)
                ->select('user_id')
                ->first();

            // Prepare created_by value
            $createdBy = $userData ? $userData->user_id : null;

            // Prepare notes with audit trail if no user_id
            $notes = $request->notes ?? '';
            if (!$userData && $employee) {
                $auditNote = "[Created via HRIS Mobile by {$employee->fullname} - No ERP user_id]";
                $notes = $notes ? $auditNote . "\n" . $notes : $auditNote;
            }

            // Generate leave number
            $leaveNumber = $this->generateEmployeeLeaveNumber();

            // Create leave record
            $leaveId = DB::connection('c3ais_write')
                ->table('ki_employee_leave')
                ->insertGetId([
                    'employee_leave_number' => $leaveNumber,
                    'employee_id' => $user->employee_id,
                    'leave_category_id' => $request->leave_category_id,
                    'subtitute_on_leave' => $request->substitute_employee_id ?? null,
                    'proposed_date' => $request->date_proposed,
                    'start_leave' => $request->date_begin,
                    'date_leave' => $request->date_end,
                    'date_begin' => $request->date_begin, // Also fill old column (NOT NULL)
                    'date_end' => $request->date_end, // Also fill old column (NOT NULL)
                    'date_extended' => $request->date_end, // Same as date_end initially
                    'work_date' => $request->date_work,
                    'notes' => $notes,
                    'address_leave' => $request->address_leave ?? null,
                    'phone_leave' => $request->phone_leave ?? null,
                    'status' => 'Aktif',
                    'sisa_cuti' => 0, // Will be calculated by system
                    'is_approved' => 0, // Pending approval
                    'created_by' => $createdBy,
                    'created_date' => now(),
                ]);

            return response()->json([
                'success' => true,
                'message' => 'Leave request created successfully',
                'data' => [
                    'employee_leave_id' => (int) $leaveId,
                    'employee_leave_number' => $leaveNumber,
                ],
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create leave request',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update employee leave
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateEmployeeLeave(Request $request, $id)
    {
        try {
            // Validate request
            $request->validate([
                'leave_category_id' => 'sometimes|required|integer|exists:c3ais.ki_leave_category,leave_category_id',
                'date_begin' => 'sometimes|required|date',
                'date_end' => 'sometimes|required|date|after_or_equal:date_begin',
                'date_work' => 'sometimes|required|date|after_or_equal:date_end',
                'notes' => 'nullable|string',
                'address_leave' => 'nullable|string',
                'phone_leave' => 'nullable|string',
            ]);

            $user = Auth::user();

            if (!$user->employee_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get employee for fullname
            $employee = $user->employee;

            // Get user_id from ki_user table (optional)
            $userData = DB::connection('c3ais')
                ->table('ki_user')
                ->where('employee_id', $user->employee_id)
                ->select('user_id')
                ->first();

            // Check if leave exists and belongs to user
            $leave = DB::connection('c3ais_write')
                ->table('ki_employee_leave')
                ->where('employee_leave_id', $id)
                ->where('employee_id', $user->employee_id)
                ->first();

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Leave not found or unauthorized',
                ], 404);
            }

            // Don't allow update if already approved
            if ($leave->is_approved) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot update approved leave request',
                ], 403);
            }

            // Prepare modified_by value
            $modifiedBy = $userData ? $userData->user_id : null;

            // Prepare update data
            $updateData = [
                'modified_by' => $modifiedBy,
                'modified_date' => now(),
            ];

            if ($request->has('leave_category_id')) {
                $updateData['leave_category_id'] = $request->leave_category_id;
            }

            if ($request->has('date_begin')) {
                $updateData['start_leave'] = $request->date_begin;
                $updateData['date_begin'] = $request->date_begin; // Also update old column
            }

            if ($request->has('date_end')) {
                $updateData['date_leave'] = $request->date_end;
                $updateData['date_end'] = $request->date_end; // Also update old column
                $updateData['date_extended'] = $request->date_end;
            }

            if ($request->has('date_work')) {
                $updateData['work_date'] = $request->date_work;
            }

            if ($request->has('notes')) {
                $notes = $request->notes ?? '';
                // Add audit trail if no user_id
                if (!$userData && $employee) {
                    $auditNote = "[Modified via HRIS Mobile by {$employee->fullname} - No ERP user_id]";
                    $notes = $notes ? $auditNote . "\n" . $notes : $auditNote;
                }
                $updateData['notes'] = $notes;
            }

            if ($request->has('address_leave')) {
                $updateData['address_leave'] = $request->address_leave;
            }

            if ($request->has('phone_leave')) {
                $updateData['phone_leave'] = $request->phone_leave;
            }

            // Update leave
            DB::connection('c3ais_write')
                ->table('ki_employee_leave')
                ->where('employee_leave_id', $id)
                ->update($updateData);

            return response()->json([
                'success' => true,
                'message' => 'Leave request updated successfully',
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update leave request',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete employee leave (soft delete by setting status to 'Tidak Aktif')
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function deleteEmployeeLeave($id)
    {
        try {
            $user = Auth::user();

            if (!$user->employee_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get user_id from ki_user table (optional)
            try {
                $userData = DB::connection('c3ais')
                    ->table('ki_user')
                    ->where('employee_id', $user->employee_id)
                    ->select('user_id')
                    ->first();
            } catch (\Exception $e) {
                // If ki_user table not accessible, continue without user_id
                \Log::warning('Could not access ki_user table: ' . $e->getMessage());
                $userData = null;
            }

            // Prepare modified_by value
            $modifiedBy = $userData ? $userData->user_id : null;

            // Check if leave exists and belongs to user
            $leave = DB::connection('c3ais_write')
                ->table('ki_employee_leave')
                ->where('employee_leave_id', $id)
                ->where('employee_id', $user->employee_id)
                ->first();

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Leave not found or unauthorized',
                ], 404);
            }

            // Don't allow delete if already approved
            if ($leave->is_approved) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete approved leave request',
                ], 403);
            }

            // Hard delete the leave record to remove it from ERP listing
            DB::connection('c3ais_write')
                ->table('ki_employee_leave')
                ->where('employee_leave_id', $id)
                ->where('employee_id', $user->employee_id)
                ->delete();

            return response()->json([
                'success' => true,
                'message' => 'Leave request deleted successfully',
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Delete leave error: ' . $e->getMessage(), [
                'leave_id' => $id,
                'user_id' => Auth::id(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete leave request',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

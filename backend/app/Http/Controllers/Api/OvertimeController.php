<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OvertimeWorkorder;
use Illuminate\Http\Request;

class OvertimeController extends Controller
{
    /**
     * Get overtime list for authenticated user
     * Only show overtimes where user is involved (in detail table)
     */
    public function getOvertimeList(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get overtimes where employee is involved
            $overtimes = OvertimeWorkorder::whereHas('details', function ($query) use ($employee) {
                $query->where('employee_id', $employee->employee_id);
            })
            ->with([
                'jobOrder',
                'department',
                'companyWorkbase',
                'requestedBy',
                'approval1By.employee',
                'approval2By.employee',
                'verifiedBy.employee',
                'details'
            ])
            ->orderBy('proposed_date', 'desc')
            ->get();

            // Format overtime data
            $overtimeData = $overtimes->map(function ($overtime) {
                $employeeIds = $overtime->details->pluck('employee_id')->unique()->values()->all();
                
                return [
                    'id' => $overtime->overtime_workorder_id,
                    'order_number' => $overtime->overtime_workorder_number ?? '-',
                    'job_code' => $overtime->jobOrder ? $overtime->jobOrder->job_order_number : '-',
                    'work_location' => $overtime->companyWorkbase ? $overtime->companyWorkbase->company_workbase_name : '-',
                    'department' => $overtime->department ? $overtime->department->department_name : '-',
                    'work_description' => $overtime->work_description ?? '-',
                    'proposed_date' => $overtime->proposed_date_formatted,
                    'requested_by' => $overtime->requestedBy ? $overtime->requestedBy->fullname : '-',
                    'is_approved' => !is_null($overtime->approval2_date),
                    'approval1_name' => $this->resolveApproverName($overtime->approval1By),
                    'approval1_date' => $overtime->approval1_date_formatted,
                    'approval2_name' => $this->resolveApproverName($overtime->approval2By),
                    'approval2_date' => $overtime->approval2_date_formatted,
                    'approval2_approved' => !is_null($overtime->approval2_date),
                    'verified_by' => $this->resolveApproverName($overtime->verifiedBy),
                    'verified_date' => $overtime->verified_date_formatted,
                    'employee_ids' => $employeeIds,
                    'employee_count' => count($employeeIds),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'overtime_count' => $overtimes->count(),
                    'overtimes' => $overtimeData,
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch overtime list',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get overtime detail by ID
     * Show employees involved in this overtime
     */
    public function getOvertimeDetail(Request $request, $id)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get overtime with all relationships
            $overtime = OvertimeWorkorder::with([
                'jobOrder',
                'department',
                'companyWorkbase',
                'requestedBy',
                'approval1By.employee',
                'approval2By.employee',
                'verifiedBy.employee',
                'details.employee.jobGrade'
            ])
            ->find($id);

            if (!$overtime) {
                return response()->json([
                    'success' => false,
                    'message' => 'Overtime not found',
                ], 404);
            }

            // Check if user is involved in this overtime
            $isInvolved = $overtime->details->where('employee_id', $employee->employee_id)->count() > 0;
            
            if (!$isInvolved) {
                return response()->json([
                    'success' => false,
                    'message' => 'You are not involved in this overtime',
                ], 403);
            }

            // Format overtime header data
            $overtimeHeader = [
                'id' => $overtime->overtime_workorder_id,
                'order_number' => $overtime->overtime_workorder_number ?? '-',
                'job_code' => $overtime->jobOrder ? $overtime->jobOrder->job_order_number : '-',
                'work_location' => $overtime->companyWorkbase ? $overtime->companyWorkbase->company_workbase_name : '-',
                'department' => $overtime->department ? $overtime->department->department_name : '-',
                'work_description' => $overtime->work_description ?? '-',
                'proposed_date' => $overtime->proposed_date_formatted,
                'requested_by' => $overtime->requestedBy ? $overtime->requestedBy->fullname : '-',
                'is_approved' => !is_null($overtime->approval2_date),
                'approval1_name' => $this->resolveApproverName($overtime->approval1By),
                'approval1_date' => $overtime->approval1_date_formatted,
                'approval2_name' => $this->resolveApproverName($overtime->approval2By),
                'approval2_date' => $overtime->approval2_date_formatted,
                'approval2_approved' => !is_null($overtime->approval2_date),
                'verified_by' => $this->resolveApproverName($overtime->verifiedBy),
                'verified_date' => $overtime->verified_date_formatted,
            ];

            // Format employee details
            $employees = $overtime->details->map(function ($detail) {
                return [
                    'employee_id' => $detail->employee ? $detail->employee->employee_number : '-',
                    'employee_name' => $detail->employee ? $detail->employee->fullname : '-',
                    'position' => $detail->employee && $detail->employee->jobGrade 
                        ? $detail->employee->jobGrade->job_grade_name 
                        : '-',
                    'initials' => $detail->employee ? $this->getInitials($detail->employee->fullname) : '-',
                    'overtime_date' => $detail->overtime_date_formatted,
                    'start_time' => $detail->start_time_formatted,
                    'finish_time' => $detail->finish_time_formatted,
                    'remarks' => $detail->description ?? '-',
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'overtime' => $overtimeHeader,
                    'employees' => $employees,
                    'employee_count' => $employees->count(),
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch overtime detail',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Helper function to get initials from full name
     */
    private function getInitials($fullname)
    {
        $words = explode(' ', $fullname);
        $initials = '';
        
        foreach ($words as $word) {
            if (!empty($word)) {
                $initials .= strtoupper(substr($word, 0, 1));
            }
        }

        return $initials;
    }

    /**
     * Helper untuk mendapatkan nama approver dari relasi user
     */
    private function resolveApproverName($userRelation)
    {
        if (!$userRelation) {
            return null;
        }

        if ($userRelation->employee) {
            return $userRelation->employee->fullname;
        }

        return $userRelation->user_displayname ?? null;
    }
}

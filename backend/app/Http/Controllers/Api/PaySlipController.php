<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class PaySlipController extends Controller
{
    /**
     * Get available pay slip periods for the authenticated employee
     */
    public function getAvailablePeriods(Request $request)
    {
        try {
            $employee = Auth::user();

            // Get employee_id from ki_employee table
            $employeeData = DB::connection('c3ais')
                ->table('ki_employee')
                ->where('employee_number', $employee->employee_number)
                ->select('employee_id')
                ->first();

            if (!$employeeData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get all available periods from ki_employee_report
            $periods = DB::connection('c3ais')
                ->table('ki_employee_report')
                ->where('employee_id', $employeeData->employee_id)
                ->select('month_year', 'created_date')
                ->orderBy('created_date', 'desc')
                ->get();

            // Format periods for dropdown
            $formattedPeriods = [];
            $availableYears = [];
            $availableMonths = [];

            foreach ($periods as $period) {
                $monthYear = $period->month_year;

                // Parse different formats:
                // "01 - 15 October 2025", "16 - 31 October 2025", "October 2025"

                $periodType = '1 - 31'; // default
                $monthName = '';
                $year = '';

                if (preg_match('/^(\d{2})\s*-\s*(\d{2})\s+(\w+)\s+(\d{4})$/', $monthYear, $matches)) {
                    // Format: "01 - 15 October 2025" or "16 - 31 October 2025"
                    $periodStart = $matches[1];
                    $periodEnd = $matches[2];
                    $periodType = $periodStart . ' - ' . $periodEnd;
                    $monthName = $matches[3];
                    $year = $matches[4];
                } elseif (preg_match('/^(\w+)\s+(\d{4})$/', $monthYear, $matches)) {
                    // Format: "October 2025"
                    $periodType = '1 - 31';
                    $monthName = $matches[1];
                    $year = $matches[2];
                }

                if ($monthName && $year) {
                    if (!in_array($year, $availableYears)) {
                        $availableYears[] = $year;
                    }

                    if (!in_array($monthName, $availableMonths)) {
                        $availableMonths[] = $monthName;
                    }

                    $formattedPeriods[] = [
                        'month_year' => $monthYear,
                        'month' => $monthName,
                        'year' => $year,
                        'period' => $periodType,
                    ];
                }
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'periods' => $formattedPeriods,
                    'available_years' => $availableYears,
                    'available_months' => $availableMonths,
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load available periods',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get pay slip detail for specific period
     * UPDATED: Uses Employee model relationships for position and department
     */
    public function getPaySlipDetail(Request $request)
    {
        try {
            $month = $request->input('month'); // e.g., "September"
            $year = $request->input('year');   // e.g., "2025"
            $period = $request->input('period', '1 - 31'); // e.g., "1 - 31", "1 - 15", "16 - 31"

            $employee = Auth::user();

            // Get employee_id from ki_employee table
            $employeeData = DB::connection('c3ais')
                ->table('ki_employee')
                ->where('employee_number', $employee->employee_number)
                ->select('employee_id')
                ->first();

            if (!$employeeData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Construct month_year based on period
            $monthYear = '';

            if ($period === '1 - 15') {
                // Format: "01 - 15 September 2025"
                $monthYear = '01 - 15 ' . $month . ' ' . $year;
            } elseif ($period === '16 - 31') {
                // Format: "16 - 31 September 2025"
                $monthYear = '16 - 31 ' . $month . ' ' . $year;
            } else {
                // Format: "September 2025" (full month period 1-31 or default)
                $monthYear = $month . ' ' . $year;
            }

            // Get pay slip report from ki_employee_report
            $paySlip = DB::connection('c3ais')
                ->table('ki_employee_report')
                ->where('employee_id', $employeeData->employee_id)
                ->where('month_year', $monthYear)
                ->first();

            if (!$paySlip) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pay slip not found for the selected period',
                    'data' => null,
                ], 404);
            }

            // Get employee info with relationships using Employee model
            // This fixes the issue where position and department were showing "-"
            $employeeModel = Employee::where('employee_number', $employee->employee_number)->first();

            if (!$employeeModel) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee not found',
                ], 404);
            }

            // Calculate earnings
            $earnings = [
                'basic_salary' => $paySlip->basic_salary ?? 0,
                'meal_allowance' => $paySlip->meal_allowance ?? 0,
                'transport_allowance' => $paySlip->transport_allowance ?? 0,
                'welfare_allowance' => $paySlip->welfare_allowance ?? 0,
                'overtime' => $paySlip->overtime ?? 0,
                'overtime_meal' => $paySlip->overtime_meal ?? 0,
                'location_project_allowance' => $paySlip->location_project_allowance ?? 0,
                'official_travel_allowance' => $paySlip->official_travel_allowance ?? 0,
                'profesional_allowance' => $paySlip->profesional_allowance ?? 0,
                'emergency_call' => $paySlip->emergency_call ?? 0,
                'jamsostek_allowance' => $paySlip->jamsostek_allowance ?? 0,
                'bpjs_allowance' => $paySlip->bpjs_allowance ?? 0,
                'additional_allowance' => $paySlip->additional_allowance ?? 0,
            ];

            $totalEarnings = array_sum($earnings);

            // Calculate deductions
            $deductions = [
                'jamsostek_paid' => $paySlip->jamsostek_paid ?? 0,
                'bpjs_paid' => $paySlip->bpjs_paid ?? 0,
                'jht' => $paySlip->jht ?? 0,
                'bpjs' => $paySlip->bpjs ?? 0,
                'jaminan_pensiun' => $paySlip->jaminan_pensiun ?? 0,
                'pph1' => $paySlip->pph1 ?? 0,
                'pph2' => $paySlip->pph2 ?? 0,
                'late_deduction' => $paySlip->late_deduction ?? 0,
                'absent' => $paySlip->absent ?? 0,
                'moneybox' => $paySlip->moneybox ?? 0,
                'cooperative' => $paySlip->cooperative ?? 0,
                'loan_cooperative' => $paySlip->loan_cooperative ?? 0,
                'deduction_k3_amount' => $paySlip->deduction_k3_amount ?? 0,
                'other_deduction' => $paySlip->other_deduction ?? 0,
                'jpk' => $paySlip->jpk ?? 0,
                'jpk_paid' => $paySlip->jpk_paid ?? 0,
                'less_payment' => $paySlip->less_payment ?? 0,
            ];

            $totalDeductions = array_sum($deductions);

            // Calculate net pay
            $netPay = $totalEarnings - $totalDeductions;

            // Take home pay (assuming moneybox is savings that reduces take home)
            $takeHomePay = $netPay;

            // Format response with FIXED employee info using Employee model relationships
            return response()->json([
                'success' => true,
                'data' => [
                    'period' => $period,
                    'month' => $month,
                    'year' => $year,
                    'month_year' => $monthYear,

                    // Employee Information - FIXED to use Employee model relationships
                    'employee_info' => [
                        'name' => $employeeModel->fullname ?? '-',
                        'employee_number' => $employeeModel->employee_number ?? '-',
                        'grade' => $employeeModel->employeeGrade->employee_grade_name ?? '-',
                        'position' => $employeeModel->jobGrade->job_grade_name ?? '-',  // FIXED: was $employee->position
                        'department' => $employeeModel->department->department_name ?? '-',  // FIXED: was $paySlip->department_name
                        'work_location' => $employeeModel->companyWorkbase->company_workbase_name ?? '-',
                        'employee_status' => $employeeModel->employeeStatus->employee_status_name ?? '-',
                        'npwp' => $employeeModel->npwp ?? '-',
                        'account_number' => $paySlip->no_rek ? number_format($paySlip->no_rek, 0, '', '') : '-',
                    ],

                    // Earnings breakdown
                    'earnings' => $earnings,
                    'total_earnings' => $totalEarnings,

                    // Deductions breakdown
                    'deductions' => $deductions,
                    'total_deductions' => $totalDeductions,

                    // Net pay
                    'net_pay' => $netPay,
                    'take_home_pay' => $takeHomePay,

                    // Additional info
                    'total_savings' => $paySlip->moneybox ?? 0,
                    'created_date' => $paySlip->created_date ?? null,
                ],
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load pay slip detail',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}

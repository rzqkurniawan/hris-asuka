<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    /**
     * Get available periods (years and months) for attendance filtering
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAvailablePeriods()
    {
        try {
            $employee = Auth::user();

            // Get employee_check_id from ki_employee table
            $employeeData = DB::connection('c3ais')
                ->table('ki_employee')
                ->where('employee_number', $employee->employee_number)
                ->select('employee_check_id')
                ->first();

            if (!$employeeData || !$employeeData->employee_check_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee check data not found',
                ], 404);
            }

            // Get distinct years and months from ki_employee_check_clock
            $periods = DB::connection('c3ais')
                ->table('ki_employee_check_clock')
                ->where('employee_check_id', $employeeData->employee_check_id)
                ->select(
                    DB::raw('YEAR(date_check_clock) as year'),
                    DB::raw('MONTH(date_check_clock) as month')
                )
                ->distinct()
                ->orderBy('year', 'desc')
                ->orderBy('month', 'desc')
                ->get();

            if ($periods->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'No attendance periods found',
                ], 404);
            }

            // Get unique years
            $availableYears = $periods->pluck('year')->unique()->values()->toArray();

            // Group months by year
            $periodsByYear = [];
            foreach ($periods as $period) {
                $year = (int) $period->year;
                $month = (int) $period->month;

                if (!isset($periodsByYear[$year])) {
                    $periodsByYear[$year] = [];
                }

                if (!in_array($month, $periodsByYear[$year])) {
                    $periodsByYear[$year][] = $month;
                }
            }

            // Sort months within each year
            foreach ($periodsByYear as $year => $months) {
                sort($periodsByYear[$year]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Available attendance periods retrieved successfully',
                'data' => [
                    'available_years' => $availableYears,
                    'periods_by_year' => $periodsByYear,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve available periods',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get attendance summary for specific month and year
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAttendanceSummary(Request $request)
    {
        try {
            // Validate request
            $request->validate([
                'month' => 'required|integer|min:1|max:12',
                'year' => 'required|integer|min:1900|max:2100',
            ]);

            $month = $request->input('month');
            $year = $request->input('year');

            $employee = Auth::user();

            // Get all check clock records with SPKL data from ki_overtime_workorder_detail
            // JOIN: ki_employee -> ki_employee_check_clock -> ki_overtime_workorder_detail
            $records = DB::connection('c3ais')
                ->table('ki_employee as e')
                ->join('ki_employee_check_clock as ecc', 'e.employee_check_id', '=', 'ecc.employee_check_id')
                ->leftJoin('ki_overtime_workorder_detail as otd', function($join) {
                    $join->on('e.employee_id', '=', 'otd.employee_id')
                         ->on('ecc.date_check_clock', '=', 'otd.overtime_date');
                })
                ->where('e.employee_number', $employee->employee_number)
                ->whereMonth('ecc.date_check_clock', $month)
                ->whereYear('ecc.date_check_clock', $year)
                ->select(
                    'ecc.*',
                    'otd.start_time as spkl_start',
                    'otd.finish_time as spkl_finish'
                )
                ->get();

            // Month names in Indonesian (moved here to use in empty response)
            $monthNames = [
                '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
            ];
            $monthName = $monthNames[$month];

            // If no records found, return empty summary with zeros (200 OK, not 404)
            if ($records->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'message' => 'No attendance records found for the specified period',
                    'data' => [
                        'month' => (int) $month,
                        'year' => (int) $year,
                        'month_name' => $monthName,
                        'total_days' => 0,
                        'masuk' => 0,
                        'terlambat' => 0,
                        'alpha' => 0,
                        'izin' => 0,
                        'sakit' => 0,
                        'cuti' => 0,
                    ],
                ], 200);
            }

            // Calculate summary statistics based on description field
            $totalDays = $records->count();
            $masukDays = 0;     // Masuk
            $lateDays = 0;      // Terlambat (Late)
            $alphaDays = 0;     // Alpha (Absent without permission)
            $izinDays = 0;      // Ijin & IjinNormatif (Permission)
            $sakitDays = 0;     // Sakit (Sick leave)
            $cutiDays = 0;      // Cuti (Annual leave)

            foreach ($records as $record) {
                $description = trim($record->description ?? '');

                // Count based on description field
                if ($description === 'Masuk') {
                    $masukDays++;

                    // Check if late (check_in > on_duty and no permission_late)
                    if (!empty($record->check_in) && !empty($record->on_duty) && !$record->permission_late) {
                        $checkIn = Carbon::parse($record->check_in);
                        $onDuty = Carbon::parse($record->on_duty);

                        // If check_in is after on_duty, count as late
                        if ($checkIn->gt($onDuty)) {
                            $lateDays++;
                        }
                    }
                } elseif ($description === 'Alpha') {
                    $alphaDays++;
                } elseif ($description === 'Ijin' || $description === 'IjinNormatif') {
                    $izinDays++;
                } elseif ($description === 'Sakit') {
                    $sakitDays++;
                } elseif ($description === 'Cuti') {
                    $cutiDays++;
                }
                // Skorsing and Libur are not counted in summary
            }

            return response()->json([
                'success' => true,
                'message' => 'Attendance summary retrieved successfully',
                'data' => [
                    'month' => (int) $month,
                    'year' => (int) $year,
                    'month_name' => $monthName,
                    'total_days' => (int) $totalDays,
                    'masuk' => (int) $masukDays,
                    'terlambat' => (int) $lateDays,
                    'alpha' => (int) $alphaDays,
                    'izin' => (int) $izinDays,
                    'sakit' => (int) $sakitDays,
                    'cuti' => (int) $cutiDays,
                ],
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
                'message' => 'Failed to retrieve attendance summary',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get detailed attendance records for specific month and year
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAttendanceDetail(Request $request)
    {
        try {
            // Validate request
            $request->validate([
                'month' => 'required|integer|min:1|max:12',
                'year' => 'required|integer|min:1900|max:2100',
            ]);

            $month = $request->input('month');
            $year = $request->input('year');

            $employee = Auth::user();

            // Get all check clock records with SPKL data from ki_overtime_workorder_detail
            // JOIN: ki_employee -> ki_employee_check_clock -> ki_overtime_workorder_detail
            $records = DB::connection('c3ais')
                ->table('ki_employee as e')
                ->join('ki_employee_check_clock as ecc', 'e.employee_check_id', '=', 'ecc.employee_check_id')
                ->leftJoin('ki_overtime_workorder_detail as otd', function($join) {
                    $join->on('e.employee_id', '=', 'otd.employee_id')
                         ->on('ecc.date_check_clock', '=', 'otd.overtime_date');
                })
                ->where('e.employee_number', $employee->employee_number)
                ->whereMonth('ecc.date_check_clock', $month)
                ->whereYear('ecc.date_check_clock', $year)
                ->select(
                    'ecc.*',
                    DB::raw('COALESCE(TIME_FORMAT(otd.start_time, "%H:%i"), "-") as spkl_start'),
                    DB::raw('COALESCE(TIME_FORMAT(otd.finish_time, "%H:%i"), "-") as spkl_finish')
                )
                ->orderBy('ecc.date_check_clock', 'asc')
                ->get();

            if ($records->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'No attendance records found for the specified period',
                ], 404);
            }

            // Format records for response
            $formattedRecords = [];
            $no = 1;

            foreach ($records as $record) {
                $formattedRecords[] = [
                    'no' => (int) $no++,
                    'date_check_clock' => $this->formatDate($record->date_check_clock),
                    'on_duty' => $record->on_duty ?? '-',
                    'off_duty' => $record->off_duty ?? '-',
                    'check_in' => $record->check_in ?? '-',
                    'check_out' => $record->check_out ?? '-',
                    'start_call' => $record->spkl_start,  // From LEFT JOIN to ki_overtime_workorder_detail
                    'end_call' => $record->spkl_finish,   // From LEFT JOIN to ki_overtime_workorder_detail
                    'emergency_call' => (bool) ($record->emergency_call ?? false),
                    'no_lunch' => (bool) ($record->no_lunch ?? false),
                    'description' => $record->description ?? '-',
                    'note_for_shift' => $record->note_for_shift ?? '-',
                    'shift_category' => $record->shift_category ?? '-',
                    'type_work_hour' => $record->type_work_hour ?? 'NT',
                    'permission_late' => (bool) ($record->permission_late ?? false),
                    'computed_holiday_notes' => $record->computed_holiday_notes ?? '-',
                ];
            }

            // Month names in Indonesian
            $monthNames = [
                '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
            ];

            $monthName = $monthNames[$month];
            $monthYear = "$monthName $year";

            return response()->json([
                'success' => true,
                'message' => 'Attendance detail retrieved successfully',
                'data' => [
                    'month' => (int) $month,
                    'year' => (int) $year,
                    'month_name' => $monthName,
                    'month_year' => $monthYear,
                    'total_records' => (int) count($formattedRecords),
                    'records' => $formattedRecords,
                ],
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
                'message' => 'Failed to retrieve attendance detail',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Format date to dd/MM/yyyy
     *
     * @param string $date
     * @return string
     */
    private function formatDate($date)
    {
        try {
            $carbonDate = Carbon::parse($date);
            return $carbonDate->format('d/m/Y');
        } catch (\Exception $e) {
            return $date;
        }
    }
}

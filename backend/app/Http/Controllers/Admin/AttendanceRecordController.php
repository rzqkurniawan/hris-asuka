<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\AttendanceLocation;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class AttendanceRecordController extends Controller
{
    /**
     * Display attendance records list
     */
    public function index(Request $request)
    {
        $query = AttendanceRecord::with(['user', 'employee', 'location']);

        // Filter by date range
        if ($request->filled('start_date') && $request->filled('end_date')) {
            $query->whereBetween('attendance_date', [$request->start_date, $request->end_date]);
        } elseif ($request->filled('date')) {
            $query->where('attendance_date', $request->date);
        } else {
            // Default to today
            $query->where('attendance_date', now()->toDateString());
        }

        // Filter by employee
        if ($request->filled('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        // Filter by check type
        if ($request->filled('check_type')) {
            $query->where('check_type', $request->check_type);
        }

        // Search by employee name or number
        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('employee', function($q) use ($search) {
                $q->where('fullname', 'like', "%{$search}%")
                  ->orWhere('employee_number', 'like', "%{$search}%");
            });
        }

        // Filter by suspicious/security status
        if ($request->filled('suspicious')) {
            $suspicious = $request->suspicious;
            if ($suspicious === '1') {
                $query->where('is_suspicious', true);
            } elseif ($suspicious === 'mock') {
                $query->where('is_mock_location', true);
            } elseif ($suspicious === 'rooted') {
                $query->where('is_rooted', true);
            }
        }

        $records = $query->orderBy('attendance_date', 'desc')
                        ->orderBy('created_at', 'desc')
                        ->paginate(20);

        // Get active employees for filter dropdown
        $employees = DB::connection('c3ais')
            ->table('ki_employee')
            ->where('working_status', 'Active')
            ->select('employee_id', 'employee_number', 'fullname')
            ->orderBy('fullname')
            ->get();

        $locations = AttendanceLocation::active()->get();

        return view('admin.attendance-records.index', compact('records', 'employees', 'locations'));
    }

    /**
     * Show create form
     */
    public function create()
    {
        $employees = DB::connection('c3ais')
            ->table('ki_employee')
            ->where('working_status', 'Active')
            ->select('employee_id', 'employee_number', 'fullname')
            ->orderBy('fullname')
            ->get();

        $locations = AttendanceLocation::active()->get();

        return view('admin.attendance-records.create', compact('employees', 'locations'));
    }

    /**
     * Store new attendance record
     */
    public function store(Request $request)
    {
        $request->validate([
            'employee_id' => 'required|integer',
            'check_type' => 'required|in:check_in,check_out',
            'attendance_date' => 'required|date',
            'attendance_time' => 'required',
            'location_id' => 'required|exists:attendance_locations,id',
        ]);

        $employee = DB::connection('c3ais')
            ->table('ki_employee')
            ->where('employee_id', $request->employee_id)
            ->first();

        if (!$employee) {
            return back()->with('error', 'Employee not found');
        }

        // Get user if exists
        $user = User::where('employee_id', $request->employee_id)->first();

        // Get location for coordinates
        $location = AttendanceLocation::find($request->location_id);

        // Combine date and time
        $datetime = $request->attendance_date . ' ' . $request->attendance_time;

        AttendanceRecord::create([
            'employee_id' => $request->employee_id,
            'user_id' => $user ? $user->id : null,
            'check_type' => $request->check_type,
            'latitude' => $location->latitude,
            'longitude' => $location->longitude,
            'location_id' => $request->location_id,
            'location_verified' => true,
            'face_verified' => $request->has('face_verified'),
            'face_confidence' => $request->face_confidence ?? 0,
            'device_info' => 'Admin Manual Entry',
            'attendance_date' => $request->attendance_date,
            'created_at' => $datetime,
            'updated_at' => $datetime,
        ]);

        return redirect()->route('admin.attendance-records.index')
            ->with('success', 'Attendance record created successfully');
    }

    /**
     * Show edit form
     */
    public function edit($id)
    {
        $record = AttendanceRecord::with(['employee', 'location'])->findOrFail($id);

        $employees = DB::connection('c3ais')
            ->table('ki_employee')
            ->where('working_status', 'Active')
            ->select('employee_id', 'employee_number', 'fullname')
            ->orderBy('fullname')
            ->get();

        $locations = AttendanceLocation::active()->get();

        return view('admin.attendance-records.edit', compact('record', 'employees', 'locations'));
    }

    /**
     * Update attendance record
     */
    public function update(Request $request, $id)
    {
        $record = AttendanceRecord::findOrFail($id);

        $request->validate([
            'check_type' => 'required|in:check_in,check_out',
            'attendance_date' => 'required|date',
            'attendance_time' => 'required',
            'location_id' => 'required|exists:attendance_locations,id',
        ]);

        // Get location for coordinates if changed
        $location = AttendanceLocation::find($request->location_id);

        // Combine date and time
        $datetime = $request->attendance_date . ' ' . $request->attendance_time;

        $record->update([
            'check_type' => $request->check_type,
            'latitude' => $location->latitude,
            'longitude' => $location->longitude,
            'location_id' => $request->location_id,
            'location_verified' => $request->has('location_verified'),
            'face_verified' => $request->has('face_verified'),
            'face_confidence' => $request->face_confidence ?? $record->face_confidence,
            'attendance_date' => $request->attendance_date,
            'created_at' => $datetime,
        ]);

        return redirect()->route('admin.attendance-records.index')
            ->with('success', 'Attendance record updated successfully');
    }

    /**
     * Delete attendance record
     */
    public function destroy($id)
    {
        $record = AttendanceRecord::findOrFail($id);

        // Delete face image if exists
        if ($record->face_image_path) {
            Storage::disk('public')->delete($record->face_image_path);
        }

        $record->delete();

        return redirect()->route('admin.attendance-records.index')
            ->with('success', 'Attendance record deleted successfully');
    }

    /**
     * Show attendance record detail with face image
     */
    public function show($id)
    {
        $record = AttendanceRecord::with(['user', 'employee', 'location'])->findOrFail($id);

        return view('admin.attendance-records.show', compact('record'));
    }

    /**
     * Export attendance records to CSV
     */
    public function export(Request $request)
    {
        $query = AttendanceRecord::with(['employee', 'location']);

        // Apply same filters as index
        if ($request->filled('start_date') && $request->filled('end_date')) {
            $query->whereBetween('attendance_date', [$request->start_date, $request->end_date]);
        } elseif ($request->filled('date')) {
            $query->where('attendance_date', $request->date);
        }

        if ($request->filled('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        $records = $query->orderBy('attendance_date', 'desc')
                        ->orderBy('created_at', 'asc')
                        ->get();

        $filename = 'attendance_export_' . date('Y-m-d_His') . '.csv';

        header('Content-Type: text/csv');
        header('Content-Disposition: attachment; filename="' . $filename . '"');

        $output = fopen('php://output', 'w');

        // Header
        fputcsv($output, [
            'Date',
            'Employee Number',
            'Employee Name',
            'Check Type',
            'Time',
            'Location',
            'Location Verified',
            'Face Verified',
            'Face Confidence',
        ]);

        // Data
        foreach ($records as $record) {
            fputcsv($output, [
                $record->attendance_date->format('Y-m-d'),
                $record->employee ? $record->employee->employee_number : '-',
                $record->employee ? $record->employee->fullname : '-',
                $record->check_type === 'check_in' ? 'Check In' : 'Check Out',
                $record->created_at->format('H:i:s'),
                $record->location ? $record->location->name : '-',
                $record->location_verified ? 'Yes' : 'No',
                $record->face_verified ? 'Yes' : 'No',
                $record->face_confidence ? $record->face_confidence . '%' : '-',
            ]);
        }

        fclose($output);
        exit();
    }
}

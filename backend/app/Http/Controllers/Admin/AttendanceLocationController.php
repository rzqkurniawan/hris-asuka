<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AttendanceLocation;
use Illuminate\Http\Request;

class AttendanceLocationController extends Controller
{
    public function index(Request $request)
    {
        $query = AttendanceLocation::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('address', 'like', "%{$search}%");
            });
        }

        $locations = $query->orderBy('created_at', 'desc')->paginate(20);

        return view('admin.attendance-locations.index', compact('locations'));
    }

    public function create()
    {
        return view('admin.attendance-locations.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius_meters' => 'required|integer|min:10|max:5000',
        ]);

        AttendanceLocation::create([
            'name' => $request->name,
            'address' => $request->address,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'radius_meters' => $request->radius_meters,
            'is_active' => $request->has('is_active'),
        ]);

        return redirect()->route('admin.attendance-locations.index')
            ->with('success', 'Lokasi absensi berhasil ditambahkan');
    }

    public function edit($id)
    {
        $location = AttendanceLocation::findOrFail($id);
        return view('admin.attendance-locations.edit', compact('location'));
    }

    public function update(Request $request, $id)
    {
        $location = AttendanceLocation::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius_meters' => 'required|integer|min:10|max:5000',
        ]);

        $location->update([
            'name' => $request->name,
            'address' => $request->address,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'radius_meters' => $request->radius_meters,
            'is_active' => $request->has('is_active'),
        ]);

        return redirect()->route('admin.attendance-locations.index')
            ->with('success', 'Lokasi absensi berhasil diperbarui');
    }

    public function destroy($id)
    {
        $location = AttendanceLocation::findOrFail($id);

        // Check if location has attendance records
        if ($location->attendanceRecords()->exists()) {
            return back()->with('error', 'Tidak dapat menghapus lokasi yang memiliki data absensi');
        }

        $location->delete();

        return redirect()->route('admin.attendance-locations.index')
            ->with('success', 'Lokasi absensi berhasil dihapus');
    }
}

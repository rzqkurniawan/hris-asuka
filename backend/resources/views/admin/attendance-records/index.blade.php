@extends('admin.layouts.app')

@section('title', 'Attendance Records')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="bi bi-clock-history"></i> Attendance Records</h2>
    <div>
        <a href="{{ route('admin.attendance-records.export', request()->all()) }}" class="btn btn-secondary">
            <i class="bi bi-download"></i> Export CSV
        </a>
        <a href="{{ route('admin.attendance-records.create') }}" class="btn btn-primary">
            <i class="bi bi-plus-circle"></i> Add Record
        </a>
    </div>
</div>

<!-- Filter Form -->
<div class="card shadow-sm mb-3">
    <div class="card-body">
        <form method="GET" action="{{ route('admin.attendance-records.index') }}" class="row g-3">
            <div class="col-md-2">
                <label class="form-label small">Date</label>
                <input type="date" name="date" class="form-control" value="{{ request('date', now()->toDateString()) }}">
            </div>
            <div class="col-md-2">
                <label class="form-label small">Start Date</label>
                <input type="date" name="start_date" class="form-control" value="{{ request('start_date') }}">
            </div>
            <div class="col-md-2">
                <label class="form-label small">End Date</label>
                <input type="date" name="end_date" class="form-control" value="{{ request('end_date') }}">
            </div>
            <div class="col-md-2">
                <label class="form-label small">Check Type</label>
                <select name="check_type" class="form-select">
                    <option value="">All</option>
                    <option value="check_in" {{ request('check_type') === 'check_in' ? 'selected' : '' }}>Check In</option>
                    <option value="check_out" {{ request('check_type') === 'check_out' ? 'selected' : '' }}>Check Out</option>
                </select>
            </div>
            <div class="col-md-2">
                <label class="form-label small">Search Employee</label>
                <input type="text" name="search" class="form-control" placeholder="Name or employee number..." value="{{ request('search') }}">
            </div>
            <div class="col-md-2">
                <label class="form-label small">Security Status</label>
                <select name="suspicious" class="form-select">
                    <option value="">All</option>
                    <option value="1" {{ request('suspicious') === '1' ? 'selected' : '' }}>Suspicious Only</option>
                    <option value="mock" {{ request('suspicious') === 'mock' ? 'selected' : '' }}>Mock Location</option>
                    <option value="rooted" {{ request('suspicious') === 'rooted' ? 'selected' : '' }}>Rooted Device</option>
                </select>
            </div>
            <div class="col-md-1 d-flex align-items-end">
                <button type="submit" class="btn btn-primary w-100">
                    <i class="bi bi-search"></i>
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Records Table -->
<div class="card shadow-sm">
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Date</th>
                        <th>Time</th>
                        <th>Employee</th>
                        <th>Type</th>
                        <th>Location</th>
                        <th>Verified</th>
                        <th>Security</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($records as $record)
                    <tr>
                        <td>{{ $record->id }}</td>
                        <td>{{ $record->attendance_date->format('Y-m-d') }}</td>
                        <td><strong>{{ $record->created_at->format('H:i:s') }}</strong></td>
                        <td>
                            @if($record->employee)
                                <span class="text-muted small">{{ $record->employee->employee_number }}</span><br>
                                {{ $record->employee->fullname }}
                            @else
                                <span class="text-muted">-</span>
                            @endif
                        </td>
                        <td>
                            @if($record->check_type === 'check_in')
                                <span class="badge bg-success"><i class="bi bi-box-arrow-in-right"></i> Check In</span>
                            @else
                                <span class="badge bg-warning text-dark"><i class="bi bi-box-arrow-right"></i> Check Out</span>
                            @endif
                        </td>
                        <td>{{ $record->location ? $record->location->name : '-' }}</td>
                        <td>
                            <div class="d-flex gap-1">
                                @if($record->location_verified)
                                    <span class="badge bg-success" title="Location Verified"><i class="bi bi-geo-alt-fill"></i></span>
                                @else
                                    <span class="badge bg-danger" title="Location Not Verified"><i class="bi bi-geo-alt"></i></span>
                                @endif
                                @if($record->face_verified)
                                    <span class="badge bg-success" title="Face Verified ({{ $record->face_confidence }}%)"><i class="bi bi-person-check-fill"></i></span>
                                @else
                                    <span class="badge bg-danger" title="Face Not Verified"><i class="bi bi-person-x"></i></span>
                                @endif
                            </div>
                        </td>
                        <td>
                            @if($record->is_suspicious)
                                <span class="badge bg-danger" title="Suspicious Activity Detected">
                                    <i class="bi bi-exclamation-triangle-fill"></i> Suspicious
                                </span>
                                @if($record->suspicious_flags)
                                    <div class="mt-1">
                                        @foreach($record->suspicious_flags as $flag)
                                            <span class="badge bg-warning text-dark small" title="{{ $flag }}">
                                                @if($flag === 'mock_location_enabled')
                                                    <i class="bi bi-geo"></i> Mock GPS
                                                @elseif($flag === 'rooted_device')
                                                    <i class="bi bi-phone"></i> Rooted
                                                @elseif($flag === 'low_gps_accuracy')
                                                    <i class="bi bi-broadcast"></i> Low Acc
                                                @elseif($flag === 'stale_location_data')
                                                    <i class="bi bi-clock"></i> Stale
                                                @elseif($flag === 'unrealistic_speed')
                                                    <i class="bi bi-speedometer"></i> Speed
                                                @else
                                                    {{ $flag }}
                                                @endif
                                            </span>
                                        @endforeach
                                    </div>
                                @endif
                            @elseif($record->is_mock_location)
                                <span class="badge bg-warning text-dark" title="Mock Location Detected">
                                    <i class="bi bi-geo"></i> Mock GPS
                                </span>
                            @elseif($record->is_rooted)
                                <span class="badge bg-secondary" title="Rooted/Jailbroken Device">
                                    <i class="bi bi-phone"></i> Rooted
                                </span>
                            @else
                                <span class="badge bg-success" title="No Security Issues">
                                    <i class="bi bi-shield-check"></i> OK
                                </span>
                            @endif
                        </td>
                        <td>
                            <div class="btn-group btn-group-sm">
                                <a href="{{ route('admin.attendance-records.show', $record->id) }}" class="btn btn-info" title="View Details">
                                    <i class="bi bi-eye"></i>
                                </a>
                                <a href="{{ route('admin.attendance-records.edit', $record->id) }}" class="btn btn-warning" title="Edit">
                                    <i class="bi bi-pencil"></i>
                                </a>
                                <form action="{{ route('admin.attendance-records.destroy', $record->id) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete this record?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-danger" title="Delete">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="9" class="text-center text-muted py-4">
                            <i class="bi bi-inbox" style="font-size: 3rem;"></i>
                            <p class="mt-2">No attendance records found for the selected criteria</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="mt-3">
            {{ $records->appends(request()->query())->links() }}
        </div>
    </div>
</div>
@endsection

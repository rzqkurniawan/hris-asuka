@extends('admin.layouts.app')

@section('title', 'View Attendance Record')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="bi bi-eye"></i> Attendance Record Detail</h2>
    <div>
        <a href="{{ route('admin.attendance-records.edit', $record->id) }}" class="btn btn-warning">
            <i class="bi bi-pencil"></i> Edit
        </a>
        <a href="{{ route('admin.attendance-records.index') }}" class="btn btn-secondary">
            <i class="bi bi-arrow-left"></i> Back
        </a>
    </div>
</div>

<div class="row">
    <div class="col-md-8">
        <div class="card shadow-sm mb-3">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-info-circle"></i> Record Information</h5>
            </div>
            <div class="card-body">
                <table class="table table-borderless">
                    <tr>
                        <th width="200">ID</th>
                        <td>{{ $record->id }}</td>
                    </tr>
                    <tr>
                        <th>Employee</th>
                        <td>
                            @if($record->employee)
                                <strong>{{ $record->employee->fullname }}</strong><br>
                                <span class="text-muted">{{ $record->employee->employee_number }}</span>
                            @else
                                <span class="text-muted">-</span>
                            @endif
                        </td>
                    </tr>
                    <tr>
                        <th>Check Type</th>
                        <td>
                            @if($record->check_type === 'check_in')
                                <span class="badge bg-success fs-6"><i class="bi bi-box-arrow-in-right"></i> Check In</span>
                            @else
                                <span class="badge bg-warning text-dark fs-6"><i class="bi bi-box-arrow-right"></i> Check Out</span>
                            @endif
                        </td>
                    </tr>
                    <tr>
                        <th>Date</th>
                        <td>{{ $record->attendance_date->format('l, d F Y') }}</td>
                    </tr>
                    <tr>
                        <th>Time</th>
                        <td><strong class="fs-5">{{ $record->created_at->format('H:i:s') }}</strong></td>
                    </tr>
                    <tr>
                        <th>Location</th>
                        <td>
                            @if($record->location)
                                {{ $record->location->name }}<br>
                                <small class="text-muted">{{ $record->location->address }}</small>
                            @else
                                <span class="text-muted">-</span>
                            @endif
                        </td>
                    </tr>
                    <tr>
                        <th>Coordinates</th>
                        <td>
                            <code>{{ $record->latitude }}, {{ $record->longitude }}</code>
                            <a href="https://www.google.com/maps?q={{ $record->latitude }},{{ $record->longitude }}" target="_blank" class="btn btn-sm btn-outline-primary ms-2">
                                <i class="bi bi-map"></i> View on Map
                            </a>
                        </td>
                    </tr>
                    <tr>
                        <th>Device Info</th>
                        <td>{{ $record->device_info ?: '-' }}</td>
                    </tr>
                    <tr>
                        <th>Created At</th>
                        <td>{{ $record->created_at->format('Y-m-d H:i:s') }}</td>
                    </tr>
                    <tr>
                        <th>Updated At</th>
                        <td>{{ $record->updated_at->format('Y-m-d H:i:s') }}</td>
                    </tr>
                </table>
            </div>
        </div>

        <!-- Verification Status -->
        <div class="card shadow-sm">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-shield-check"></i> Verification Status</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <div class="card {{ $record->location_verified ? 'border-success' : 'border-danger' }}">
                            <div class="card-body text-center">
                                <i class="bi {{ $record->location_verified ? 'bi-geo-alt-fill text-success' : 'bi-geo-alt text-danger' }}" style="font-size: 2rem;"></i>
                                <h5 class="mt-2">Location Verification</h5>
                                @if($record->location_verified)
                                    <span class="badge bg-success">Verified</span>
                                @else
                                    <span class="badge bg-danger">Not Verified</span>
                                @endif
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card {{ $record->face_verified ? 'border-success' : 'border-danger' }}">
                            <div class="card-body text-center">
                                <i class="bi {{ $record->face_verified ? 'bi-person-check-fill text-success' : 'bi-person-x text-danger' }}" style="font-size: 2rem;"></i>
                                <h5 class="mt-2">Face Verification</h5>
                                @if($record->face_verified)
                                    <span class="badge bg-success">Verified</span>
                                    <p class="mb-0 mt-1">Confidence: <strong>{{ number_format($record->face_confidence, 2) }}%</strong></p>
                                @else
                                    <span class="badge bg-danger">Not Verified</span>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Security Status (Anti-Fake GPS) -->
        <div class="card shadow-sm mt-3">
            <div class="card-header {{ $record->is_suspicious ? 'bg-danger text-white' : '' }}">
                <h5 class="mb-0">
                    <i class="bi bi-shield-exclamation"></i> Security Status
                    @if($record->is_suspicious)
                        <span class="badge bg-warning text-dark ms-2">SUSPICIOUS</span>
                    @endif
                </h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <div class="card {{ $record->is_mock_location ? 'border-danger bg-danger-subtle' : 'border-success bg-success-subtle' }}">
                            <div class="card-body text-center py-3">
                                <i class="bi {{ $record->is_mock_location ? 'bi-geo text-danger' : 'bi-geo-alt-fill text-success' }}" style="font-size: 1.5rem;"></i>
                                <h6 class="mt-2 mb-0">GPS Status</h6>
                                @if($record->is_mock_location)
                                    <span class="badge bg-danger">Mock GPS Detected</span>
                                @else
                                    <span class="badge bg-success">Genuine GPS</span>
                                @endif
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card {{ $record->is_rooted ? 'border-warning bg-warning-subtle' : 'border-success bg-success-subtle' }}">
                            <div class="card-body text-center py-3">
                                <i class="bi {{ $record->is_rooted ? 'bi-phone-vibrate text-warning' : 'bi-phone text-success' }}" style="font-size: 1.5rem;"></i>
                                <h6 class="mt-2 mb-0">Device Status</h6>
                                @if($record->is_rooted)
                                    <span class="badge bg-warning text-dark">Rooted/Jailbroken</span>
                                @else
                                    <span class="badge bg-success">Normal Device</span>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>

                @if($record->suspicious_flags && count($record->suspicious_flags) > 0)
                    <div class="alert alert-warning mt-3 mb-0">
                        <h6 class="alert-heading"><i class="bi bi-exclamation-triangle"></i> Suspicious Flags:</h6>
                        <ul class="mb-0">
                            @foreach($record->suspicious_flags as $flag)
                                <li>
                                    @if($flag === 'mock_location_enabled')
                                        <strong>Mock Location:</strong> GPS location appears to be spoofed
                                    @elseif($flag === 'rooted_device')
                                        <strong>Rooted Device:</strong> Device has root/jailbreak access
                                    @elseif($flag === 'low_gps_accuracy')
                                        <strong>Low GPS Accuracy:</strong> Location accuracy > 100m
                                    @elseif($flag === 'stale_location_data')
                                        <strong>Stale Location:</strong> Location data older than 30 seconds
                                    @elseif($flag === 'unrealistic_speed')
                                        <strong>Unrealistic Speed:</strong> Movement speed > 180 km/h
                                    @else
                                        {{ $flag }}
                                    @endif
                                </li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                <table class="table table-sm mt-3 mb-0">
                    <tr>
                        <th>GPS Accuracy</th>
                        <td>
                            @if($record->gps_accuracy)
                                {{ number_format($record->gps_accuracy, 2) }}m
                                @if($record->gps_accuracy > 100)
                                    <span class="badge bg-warning text-dark">Low</span>
                                @elseif($record->gps_accuracy > 50)
                                    <span class="badge bg-info">Medium</span>
                                @else
                                    <span class="badge bg-success">High</span>
                                @endif
                            @else
                                <span class="text-muted">-</span>
                            @endif
                        </td>
                    </tr>
                    <tr>
                        <th>Location Provider</th>
                        <td>{{ $record->location_provider ?? '-' }}</td>
                    </tr>
                    <tr>
                        <th>WiFi SSID</th>
                        <td>{{ $record->wifi_ssid ?? '-' }}</td>
                    </tr>
                    <tr>
                        <th>WiFi BSSID</th>
                        <td><code>{{ $record->wifi_bssid ?? '-' }}</code></td>
                    </tr>
                    <tr>
                        <th>Altitude</th>
                        <td>{{ $record->altitude ? number_format($record->altitude, 2) . 'm' : '-' }}</td>
                    </tr>
                    <tr>
                        <th>Speed</th>
                        <td>{{ $record->speed ? number_format($record->speed, 2) . ' m/s' : '-' }}</td>
                    </tr>
                    <tr>
                        <th>Location Age</th>
                        <td>{{ $record->location_age_ms ? number_format($record->location_age_ms / 1000, 2) . 's' : '-' }}</td>
                    </tr>
                </table>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <!-- Face Image -->
        <div class="card shadow-sm">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-person-bounding-box"></i> Face Image</h5>
            </div>
            <div class="card-body text-center">
                @if($record->face_image_path)
                    <img src="{{ asset('storage/' . $record->face_image_path) }}" alt="Face Image" class="img-fluid rounded" style="max-height: 300px;">
                    <p class="mt-2 text-muted small">Captured at attendance time</p>
                @else
                    <div class="text-muted py-5">
                        <i class="bi bi-image" style="font-size: 3rem;"></i>
                        <p class="mt-2">No face image available</p>
                    </div>
                @endif
            </div>
        </div>

        <!-- Actions -->
        <div class="card shadow-sm mt-3">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-gear"></i> Actions</h5>
            </div>
            <div class="card-body">
                <div class="d-grid gap-2">
                    <a href="{{ route('admin.attendance-records.edit', $record->id) }}" class="btn btn-warning">
                        <i class="bi bi-pencil"></i> Edit Record
                    </a>
                    <form action="{{ route('admin.attendance-records.destroy', $record->id) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete this record?')">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="btn btn-danger w-100">
                            <i class="bi bi-trash"></i> Delete Record
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

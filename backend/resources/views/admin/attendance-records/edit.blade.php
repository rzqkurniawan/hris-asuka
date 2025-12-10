@extends('admin.layouts.app')

@section('title', 'Edit Attendance Record')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="bi bi-pencil"></i> Edit Attendance Record</h2>
    <a href="{{ route('admin.attendance-records.index') }}" class="btn btn-secondary">
        <i class="bi bi-arrow-left"></i> Back
    </a>
</div>

<div class="card shadow-sm">
    <div class="card-body">
        <form method="POST" action="{{ route('admin.attendance-records.update', $record->id) }}">
            @csrf
            @method('PUT')

            <div class="row mb-3">
                <div class="col-md-6">
                    <label class="form-label">Employee</label>
                    <input type="text" class="form-control" value="{{ $record->employee ? $record->employee->employee_number . ' - ' . $record->employee->fullname : '-' }}" disabled>
                    <small class="text-muted">Employee cannot be changed. Delete and create new record if needed.</small>
                </div>

                <div class="col-md-6">
                    <label for="check_type" class="form-label">Check Type <span class="text-danger">*</span></label>
                    <select name="check_type" id="check_type" class="form-select @error('check_type') is-invalid @enderror" required>
                        <option value="check_in" {{ old('check_type', $record->check_type) === 'check_in' ? 'selected' : '' }}>Check In</option>
                        <option value="check_out" {{ old('check_type', $record->check_type) === 'check_out' ? 'selected' : '' }}>Check Out</option>
                    </select>
                    @error('check_type')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-md-6">
                    <label for="attendance_date" class="form-label">Date <span class="text-danger">*</span></label>
                    <input type="date" name="attendance_date" id="attendance_date" class="form-control @error('attendance_date') is-invalid @enderror" value="{{ old('attendance_date', $record->attendance_date->format('Y-m-d')) }}" required>
                    @error('attendance_date')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label for="attendance_time" class="form-label">Time <span class="text-danger">*</span></label>
                    <input type="time" name="attendance_time" id="attendance_time" class="form-control @error('attendance_time') is-invalid @enderror" value="{{ old('attendance_time', $record->created_at->format('H:i:s')) }}" required step="1">
                    @error('attendance_time')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-md-6">
                    <label for="location_id" class="form-label">Location <span class="text-danger">*</span></label>
                    <select name="location_id" id="location_id" class="form-select @error('location_id') is-invalid @enderror" required>
                        <option value="">-- Select Location --</option>
                        @foreach($locations as $location)
                            <option value="{{ $location->id }}" {{ old('location_id', $record->location_id) == $location->id ? 'selected' : '' }}>
                                {{ $location->name }}
                            </option>
                        @endforeach
                    </select>
                    @error('location_id')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label for="face_confidence" class="form-label">Face Confidence (%)</label>
                    <input type="number" name="face_confidence" id="face_confidence" class="form-control @error('face_confidence') is-invalid @enderror" value="{{ old('face_confidence', $record->face_confidence) }}" min="0" max="100" step="0.01">
                    @error('face_confidence')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-md-6">
                    <div class="form-check">
                        <input type="checkbox" name="location_verified" id="location_verified" class="form-check-input" value="1" {{ old('location_verified', $record->location_verified) ? 'checked' : '' }}>
                        <label for="location_verified" class="form-check-label">Location Verified</label>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-check">
                        <input type="checkbox" name="face_verified" id="face_verified" class="form-check-input" value="1" {{ old('face_verified', $record->face_verified) ? 'checked' : '' }}>
                        <label for="face_verified" class="form-check-label">Face Verified</label>
                    </div>
                </div>
            </div>

            @if($record->face_image_path)
            <div class="row mb-3">
                <div class="col-md-6">
                    <label class="form-label">Face Image</label>
                    <div>
                        <img src="{{ asset('storage/' . $record->face_image_path) }}" alt="Face Image" class="img-thumbnail" style="max-width: 200px;">
                    </div>
                </div>
            </div>
            @endif

            <hr>

            <div class="d-flex justify-content-end gap-2">
                <a href="{{ route('admin.attendance-records.index') }}" class="btn btn-secondary">Cancel</a>
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-check-circle"></i> Update Record
                </button>
            </div>
        </form>
    </div>
</div>
@endsection

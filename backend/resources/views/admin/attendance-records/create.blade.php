@extends('admin.layouts.app')

@section('title', 'Add Attendance Record')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2><i class="bi bi-plus-circle"></i> Add Attendance Record</h2>
    <a href="{{ route('admin.attendance-records.index') }}" class="btn btn-secondary">
        <i class="bi bi-arrow-left"></i> Back
    </a>
</div>

<div class="card shadow-sm">
    <div class="card-body">
        <form method="POST" action="{{ route('admin.attendance-records.store') }}">
            @csrf

            <div class="row mb-3">
                <div class="col-md-6">
                    <label for="employee_id" class="form-label">Employee <span class="text-danger">*</span></label>
                    <select name="employee_id" id="employee_id" class="form-select @error('employee_id') is-invalid @enderror" required>
                        <option value="">-- Select Employee --</option>
                        @foreach($employees as $employee)
                            <option value="{{ $employee->employee_id }}" {{ old('employee_id') == $employee->employee_id ? 'selected' : '' }}>
                                {{ $employee->employee_number }} - {{ $employee->fullname }}
                            </option>
                        @endforeach
                    </select>
                    @error('employee_id')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label for="check_type" class="form-label">Check Type <span class="text-danger">*</span></label>
                    <select name="check_type" id="check_type" class="form-select @error('check_type') is-invalid @enderror" required>
                        <option value="">-- Select Type --</option>
                        <option value="check_in" {{ old('check_type') === 'check_in' ? 'selected' : '' }}>Check In</option>
                        <option value="check_out" {{ old('check_type') === 'check_out' ? 'selected' : '' }}>Check Out</option>
                    </select>
                    @error('check_type')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-md-6">
                    <label for="attendance_date" class="form-label">Date <span class="text-danger">*</span></label>
                    <input type="date" name="attendance_date" id="attendance_date" class="form-control @error('attendance_date') is-invalid @enderror" value="{{ old('attendance_date', now()->toDateString()) }}" required>
                    @error('attendance_date')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <div class="col-md-6">
                    <label for="attendance_time" class="form-label">Time <span class="text-danger">*</span></label>
                    <input type="time" name="attendance_time" id="attendance_time" class="form-control @error('attendance_time') is-invalid @enderror" value="{{ old('attendance_time', now()->format('H:i')) }}" required step="1">
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
                            <option value="{{ $location->id }}" {{ old('location_id') == $location->id ? 'selected' : '' }}>
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
                    <input type="number" name="face_confidence" id="face_confidence" class="form-control @error('face_confidence') is-invalid @enderror" value="{{ old('face_confidence', 100) }}" min="0" max="100" step="0.01">
                    @error('face_confidence')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-md-6">
                    <div class="form-check">
                        <input type="checkbox" name="face_verified" id="face_verified" class="form-check-input" value="1" {{ old('face_verified', true) ? 'checked' : '' }}>
                        <label for="face_verified" class="form-check-label">Face Verified</label>
                    </div>
                </div>
            </div>

            <hr>

            <div class="d-flex justify-content-end gap-2">
                <a href="{{ route('admin.attendance-records.index') }}" class="btn btn-secondary">Cancel</a>
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-check-circle"></i> Save Record
                </button>
            </div>
        </form>
    </div>
</div>
@endsection

@push('scripts')
<script>
    // Auto-search employee select (basic filter)
    document.getElementById('employee_id').addEventListener('focus', function() {
        this.size = 10;
    });
    document.getElementById('employee_id').addEventListener('blur', function() {
        this.size = 1;
    });
</script>
@endpush

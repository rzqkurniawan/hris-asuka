@extends('admin.layouts.app')

@section('title', 'Create User')

@section('content')
<div class="mb-4">
    <a href="{{ route('admin.users') }}" class="btn btn-secondary">
        <i class="bi bi-arrow-left"></i> Back to Users
    </a>
</div>

<div class="row">
    <div class="col-md-8">
        <div class="card shadow-sm">
            <div class="card-header">
                <h4 class="mb-0">➕ Create New User</h4>
            </div>
            <div class="card-body">
                <form method="POST" action="{{ route('admin.users.store') }}">
                    @csrf

                    <div class="mb-3">
                        <label class="form-label">Employee ID <span class="text-danger">*</span></label>
                        <input type="number" name="employee_id" class="form-control @error('employee_id') is-invalid @enderror" value="{{ old('employee_id') }}" required>
                        @error('employee_id')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        <small class="text-muted">Enter employee ID from database</small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Username <span class="text-danger">*</span></label>
                        <input type="text" name="username" class="form-control @error('username') is-invalid @enderror" value="{{ old('username') }}" required minlength="6" maxlength="12">
                        @error('username')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        <small class="text-muted">6-12 characters, alphanumeric only</small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Password <span class="text-danger">*</span></label>
                        <input type="password" name="password" class="form-control @error('password') is-invalid @enderror" required minlength="8">
                        @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        <small class="text-muted">Minimum 8 characters</small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Confirm Password <span class="text-danger">*</span></label>
                        <input type="password" name="password_confirmation" class="form-control" required>
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" name="is_admin" class="form-check-input" id="is_admin">
                        <label class="form-check-label" for="is_admin">
                            Make this user an admin
                        </label>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-save"></i> Create User
                        </button>
                        <a href="{{ route('admin.users') }}" class="btn btn-secondary">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection

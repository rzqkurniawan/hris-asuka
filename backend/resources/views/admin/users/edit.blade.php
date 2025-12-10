@extends('admin.layouts.app')

@section('title', 'Edit User')

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
                <h4 class="mb-0">✏️ Edit User: {{ $user->username }}</h4>
            </div>
            <div class="card-body">
                <form method="POST" action="{{ route('admin.users.update', $user->id) }}">
                    @csrf
                    @method('PUT')

                    <div class="mb-3">
                        <label class="form-label">Employee Number</label>
                        <input type="text" class="form-control" value="{{ $user->employee_number }}" disabled>
                        <small class="text-muted">Cannot be changed</small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Full Name</label>
                        <input type="text" class="form-control" value="{{ $user->employee ? $user->employee->fullname : '-' }}" disabled>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Username <span class="text-danger">*</span></label>
                        <input type="text" name="username" class="form-control @error('username') is-invalid @enderror" value="{{ old('username', $user->username) }}" required minlength="6" maxlength="12">
                        @error('username')<div class="invalid-feedback">{{ $message }}</div>@enderror
                    </div>

                    <div class="mb-3">
                        <label class="form-label">New Password</label>
                        <input type="password" name="password" class="form-control @error('password') is-invalid @enderror" minlength="8">
                        @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        <small class="text-muted">Leave blank to keep current password</small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Confirm New Password</label>
                        <input type="password" name="password_confirmation" class="form-control">
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" name="is_active" class="form-check-input" id="is_active" {{ $user->is_active ? 'checked' : '' }}>
                        <label class="form-check-label" for="is_active">
                            Active
                        </label>
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" name="is_admin" class="form-check-input" id="is_admin" {{ $user->is_admin ? 'checked' : '' }}>
                        <label class="form-check-label" for="is_admin">
                            Administrator
                        </label>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-save"></i> Update User
                        </button>
                        <a href="{{ route('admin.users') }}" class="btn btn-secondary">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card shadow-sm">
            <div class="card-body">
                <h6 class="card-title">User Information</h6>
                <table class="table table-sm">
                    <tr>
                        <td>User ID:</td>
                        <td><strong>{{ $user->id }}</strong></td>
                    </tr>
                    <tr>
                        <td>Created:</td>
                        <td>{{ $user->created_at->format('Y-m-d H:i') }}</td>
                    </tr>
                    <tr>
                        <td>Last Login:</td>
                        <td>{{ $user->last_login_at ? $user->last_login_at->format('Y-m-d H:i') : 'Never' }}</td>
                    </tr>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection

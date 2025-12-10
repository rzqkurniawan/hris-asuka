@extends('admin.layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2>📊 Dashboard</h2>
    <small class="text-muted">Welcome, {{ auth()->user()->username }}</small>
</div>

<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="card stat-card shadow-sm">
            <div class="card-body">
                <h6 class="text-muted">Total Users</h6>
                <h2>{{ $totalUsers }}</h2>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card shadow-sm" style="border-left-color: #28a745;">
            <div class="card-body">
                <h6 class="text-muted">Active Users</h6>
                <h2>{{ $activeUsers }}</h2>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card shadow-sm" style="border-left-color: #ffc107;">
            <div class="card-body">
                <h6 class="text-muted">Total Employees</h6>
                <h2>{{ $totalEmployees }}</h2>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card shadow-sm" style="border-left-color: #dc3545;">
            <div class="card-body">
                <h6 class="text-muted">Without Account</h6>
                <h2>{{ $employeesWithoutAccount }}</h2>
            </div>
        </div>
    </div>
</div>

<div class="card shadow-sm">
    <div class="card-body">
        <h5 class="card-title">Quick Actions</h5>
        <div class="d-flex gap-2">
            <a href="{{ route('admin.users') }}" class="btn btn-primary">
                <i class="bi bi-people-fill"></i> Manage Users
            </a>
            <a href="{{ route('admin.users.create') }}" class="btn btn-success">
                <i class="bi bi-plus-circle"></i> Create New User
            </a>
            <a href="{{ route('admin.users.export') }}" class="btn btn-secondary">
                <i class="bi bi-download"></i> Export Users CSV
            </a>
        </div>
    </div>
</div>
@endsection

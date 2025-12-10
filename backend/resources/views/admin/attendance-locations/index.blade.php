@extends('admin.layouts.app')

@section('title', 'Lokasi Absensi')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h2>Lokasi Absensi</h2>
    <a href="{{ route('admin.attendance-locations.create') }}" class="btn btn-primary">
        <i class="bi bi-plus-lg"></i> Tambah Lokasi
    </a>
</div>

<div class="card shadow-sm">
    <div class="card-header">
        <form method="GET" class="d-flex gap-2">
            <input type="text" name="search" class="form-control" placeholder="Cari nama atau alamat..." value="{{ request('search') }}">
            <button type="submit" class="btn btn-outline-primary">
                <i class="bi bi-search"></i>
            </button>
        </form>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Nama Lokasi</th>
                        <th>Alamat</th>
                        <th>Koordinat</th>
                        <th>Radius</th>
                        <th>Status</th>
                        <th width="150">Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($locations as $location)
                    <tr>
                        <td>
                            <strong>{{ $location->name }}</strong>
                        </td>
                        <td>{{ $location->address ?? '-' }}</td>
                        <td>
                            <small class="text-muted">
                                {{ $location->latitude }}, {{ $location->longitude }}
                            </small>
                            <a href="https://www.google.com/maps?q={{ $location->latitude }},{{ $location->longitude }}"
                               target="_blank" class="ms-1" title="Lihat di Google Maps">
                                <i class="bi bi-box-arrow-up-right"></i>
                            </a>
                        </td>
                        <td>
                            <span class="badge bg-info">{{ $location->radius_meters }}m</span>
                        </td>
                        <td>
                            @if($location->is_active)
                                <span class="badge bg-success">Aktif</span>
                            @else
                                <span class="badge bg-secondary">Nonaktif</span>
                            @endif
                        </td>
                        <td>
                            <a href="{{ route('admin.attendance-locations.edit', $location->id) }}" class="btn btn-sm btn-outline-warning">
                                <i class="bi bi-pencil"></i>
                            </a>
                            <form action="{{ route('admin.attendance-locations.destroy', $location->id) }}" method="POST" class="d-inline" onsubmit="return confirm('Yakin ingin menghapus lokasi ini?')">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-sm btn-outline-danger">
                                    <i class="bi bi-trash"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" class="text-center py-4 text-muted">
                            <i class="bi bi-geo-alt" style="font-size: 2rem;"></i>
                            <p class="mb-0 mt-2">Belum ada lokasi absensi</p>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
    @if($locations->hasPages())
    <div class="card-footer">
        {{ $locations->links() }}
    </div>
    @endif
</div>
@endsection

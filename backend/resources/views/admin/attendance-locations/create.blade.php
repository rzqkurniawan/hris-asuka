@extends('admin.layouts.app')

@section('title', 'Tambah Lokasi Absensi')

@section('content')
<div class="mb-4">
    <a href="{{ route('admin.attendance-locations.index') }}" class="btn btn-secondary">
        <i class="bi bi-arrow-left"></i> Kembali
    </a>
</div>

<div class="row">
    <div class="col-md-8">
        <div class="card shadow-sm">
            <div class="card-header">
                <h4 class="mb-0"><i class="bi bi-geo-alt-fill"></i> Tambah Lokasi Absensi</h4>
            </div>
            <div class="card-body">
                <form method="POST" action="{{ route('admin.attendance-locations.store') }}">
                    @csrf

                    <div class="mb-3">
                        <label class="form-label">Nama Lokasi <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control @error('name') is-invalid @enderror"
                               value="{{ old('name') }}" required placeholder="Contoh: Kantor Pusat Jakarta">
                        @error('name')<div class="invalid-feedback">{{ $message }}</div>@enderror
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Alamat</label>
                        <textarea name="address" class="form-control @error('address') is-invalid @enderror"
                                  rows="2" placeholder="Alamat lengkap lokasi">{{ old('address') }}</textarea>
                        @error('address')<div class="invalid-feedback">{{ $message }}</div>@enderror
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Latitude <span class="text-danger">*</span></label>
                                <input type="number" step="any" name="latitude" id="latitude"
                                       class="form-control @error('latitude') is-invalid @enderror"
                                       value="{{ old('latitude') }}" required placeholder="-6.123456">
                                @error('latitude')<div class="invalid-feedback">{{ $message }}</div>@enderror
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label">Longitude <span class="text-danger">*</span></label>
                                <input type="number" step="any" name="longitude" id="longitude"
                                       class="form-control @error('longitude') is-invalid @enderror"
                                       value="{{ old('longitude') }}" required placeholder="106.123456">
                                @error('longitude')<div class="invalid-feedback">{{ $message }}</div>@enderror
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <div class="input-group">
                            <input type="text" id="searchLocation" class="form-control" placeholder="Cari lokasi (contoh: Monas Jakarta)">
                            <button type="button" class="btn btn-outline-info" onclick="searchLocation()">
                                <i class="bi bi-search"></i> Cari
                            </button>
                        </div>
                        <small class="text-muted">Cari lokasi atau klik langsung pada peta untuk mendapatkan koordinat</small>
                    </div>

                    <div class="mb-3">
                        <div id="map" style="height: 300px; border-radius: 8px; border: 1px solid #dee2e6;"></div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Radius (meter) <span class="text-danger">*</span></label>
                        <input type="number" name="radius_meters" class="form-control @error('radius_meters') is-invalid @enderror"
                               value="{{ old('radius_meters', 100) }}" required min="10" max="5000">
                        @error('radius_meters')<div class="invalid-feedback">{{ $message }}</div>@enderror
                        <small class="text-muted">Jarak maksimal dari titik koordinat untuk absensi valid (10-5000 meter)</small>
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" name="is_active" class="form-check-input" id="is_active" checked>
                        <label class="form-check-label" for="is_active">
                            Lokasi aktif (dapat digunakan untuk absensi)
                        </label>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-save"></i> Simpan Lokasi
                        </button>
                        <a href="{{ route('admin.attendance-locations.index') }}" class="btn btn-secondary">Batal</a>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card shadow-sm">
            <div class="card-header bg-info text-white">
                <h5 class="mb-0"><i class="bi bi-info-circle"></i> Panduan</h5>
            </div>
            <div class="card-body">
                <p><strong>Cara mendapatkan koordinat:</strong></p>
                <ol class="small">
                    <li>Buka <a href="https://maps.google.com" target="_blank">Google Maps</a></li>
                    <li>Cari lokasi yang diinginkan</li>
                    <li>Klik kanan pada titik lokasi</li>
                    <li>Koordinat akan muncul (format: latitude, longitude)</li>
                    <li>Salin dan masukkan ke form</li>
                </ol>
                <hr>
                <p class="mb-0"><strong>Tips radius:</strong></p>
                <ul class="small mb-0">
                    <li>Gedung kecil: 50-100m</li>
                    <li>Gedung besar/kampus: 100-300m</li>
                    <li>Area industri: 300-500m</li>
                </ul>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
let map, marker, circle;

document.addEventListener('DOMContentLoaded', function() {
    // Default center (Jakarta)
    const defaultLat = -6.2088;
    const defaultLng = 106.8456;

    // Initialize map
    map = L.map('map').setView([defaultLat, defaultLng], 13);

    // Add OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
    }).addTo(map);

    // Add marker
    marker = L.marker([defaultLat, defaultLng], { draggable: true }).addTo(map);

    // Add radius circle
    const radius = document.querySelector('input[name="radius_meters"]').value || 100;
    circle = L.circle([defaultLat, defaultLng], { radius: parseInt(radius), color: 'blue', fillOpacity: 0.2 }).addTo(map);

    // Update coordinates when marker is dragged
    marker.on('dragend', function(e) {
        const pos = e.target.getLatLng();
        updateCoordinates(pos.lat, pos.lng);
    });

    // Click on map to set location
    map.on('click', function(e) {
        updateCoordinates(e.latlng.lat, e.latlng.lng);
    });

    // Update circle when radius changes
    document.querySelector('input[name="radius_meters"]').addEventListener('change', function() {
        circle.setRadius(parseInt(this.value) || 100);
    });

    // Update map when coordinates are manually changed
    document.getElementById('latitude').addEventListener('change', updateMapFromInputs);
    document.getElementById('longitude').addEventListener('change', updateMapFromInputs);
});

function updateCoordinates(lat, lng) {
    document.getElementById('latitude').value = lat.toFixed(8);
    document.getElementById('longitude').value = lng.toFixed(8);
    marker.setLatLng([lat, lng]);
    circle.setLatLng([lat, lng]);
    map.panTo([lat, lng]);
}

function updateMapFromInputs() {
    const lat = parseFloat(document.getElementById('latitude').value);
    const lng = parseFloat(document.getElementById('longitude').value);
    if (!isNaN(lat) && !isNaN(lng)) {
        marker.setLatLng([lat, lng]);
        circle.setLatLng([lat, lng]);
        map.panTo([lat, lng]);
    }
}

function searchLocation() {
    const query = document.getElementById('searchLocation').value;
    if (!query) {
        alert('Masukkan nama lokasi untuk dicari');
        return;
    }

    // Use Nominatim (OpenStreetMap) for geocoding
    fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1`)
        .then(response => response.json())
        .then(data => {
            if (data.length > 0) {
                const lat = parseFloat(data[0].lat);
                const lng = parseFloat(data[0].lon);
                updateCoordinates(lat, lng);
                map.setZoom(16);
            } else {
                alert('Lokasi tidak ditemukan. Coba kata kunci lain.');
            }
        })
        .catch(error => {
            alert('Gagal mencari lokasi: ' + error.message);
        });
}

// Allow search on Enter key
document.getElementById('searchLocation')?.addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        e.preventDefault();
        searchLocation();
    }
});
</script>
@endpush

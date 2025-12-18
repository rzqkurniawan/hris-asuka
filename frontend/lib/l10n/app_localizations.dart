import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'id': _idTranslations,
    'en': _enTranslations,
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['id']?[key] ??
        key;
  }

  // Convenience getters for common strings
  // ===== General =====
  String get appName => get('app_name');
  String get loading => get('loading');
  String get error => get('error');
  String get success => get('success');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get save => get('save');
  String get delete => get('delete');
  String get edit => get('edit');
  String get close => get('close');
  String get ok => get('ok');
  String get yes => get('yes');
  String get no => get('no');
  String get retry => get('retry');
  String get back => get('back');
  String get next => get('next');
  String get done => get('done');
  String get search => get('search');
  String get noData => get('no_data');
  String get refresh => get('refresh');

  // ===== Authentication =====
  String get login => get('login');
  String get logout => get('logout');
  String get register => get('register');
  String get username => get('username');
  String get password => get('password');
  String get confirmPassword => get('confirm_password');
  String get forgotPassword => get('forgot_password');
  String get resetPassword => get('reset_password');
  String get changePassword => get('change_password');
  String get currentPassword => get('current_password');
  String get newPassword => get('new_password');
  String get loginNow => get('login_now');
  String get loginSuccess => get('login_success');
  String get logoutSuccess => get('logout_success');
  String get registerSuccess => get('register_success');
  String get invalidCredentials => get('invalid_credentials');
  String get sessionExpired => get('session_expired');
  String get alreadyHaveAccount => get('already_have_account');
  String get dontHaveAccount => get('dont_have_account');

  // ===== Employee & Profile =====
  String get profile => get('profile');
  String get employee => get('employee');
  String get employeeId => get('employee_id');
  String get nik => get('nik');
  String get fullname => get('fullname');
  String get position => get('position');
  String get department => get('department');
  String get workingPeriod => get('working_period');
  String get investment => get('investment');
  String get selectEmployee => get('select_employee');
  String get searchEmployee => get('search_employee');
  String get personalData => get('personal_data');
  String get familyData => get('family_data');
  String get educationHistory => get('education_history');
  String get workExperience => get('work_experience');
  String get trainingHistory => get('training_history');
  String get positionHistory => get('position_history');

  // ===== Navigation & Menu =====
  String get home => get('home');
  String get attendance => get('attendance');
  String get menu => get('menu');
  String get settings => get('settings');
  String get about => get('about');
  String get help => get('help');

  // ===== Attendance =====
  String get checkIn => get('check_in');
  String get checkOut => get('check_out');
  String get attendanceHistory => get('attendance_history');
  String get attendanceSummary => get('attendance_summary');
  String get todayAttendance => get('today_attendance');
  String get verifyCheckIn => get('verify_check_in');
  String get verifyCheckOut => get('verify_check_out');
  String get checkInSuccess => get('check_in_success');
  String get checkOutSuccess => get('check_out_success');
  String get alreadyCheckedIn => get('already_checked_in');
  String get alreadyCheckedOut => get('already_checked_out');
  String get mustCheckInFirst => get('must_check_in_first');
  String get outsideRadius => get('outside_radius');
  String get present => get('present');
  String get absent => get('absent');
  String get late => get('late');
  String get earlyLeave => get('early_leave');
  String get overtime => get('overtime');
  String get workDays => get('work_days');

  // ===== Face Verification =====
  String get faceVerification => get('face_verification');
  String get verifyFace => get('verify_face');
  String get faceNotMatch => get('face_not_match');
  String get faceVerificationFailed => get('face_verification_failed');
  String get faceVerificationSuccess => get('face_verification_success');
  String get blinkEyes => get('blink_eyes');
  String get turnHeadLeft => get('turn_head_left');
  String get turnHeadRight => get('turn_head_right');
  String get smile => get('smile');
  String get positionFaceInFrame => get('position_face_in_frame');
  String get initializingCamera => get('initializing_camera');
  String get takeSelfie => get('take_selfie');
  String get retakePhoto => get('retake_photo');
  String get photoQualityBad => get('photo_quality_bad');
  String get livenessVerificationRequired => get('liveness_verification_required');
  String get repeatVerification => get('repeat_verification');
  String get faceRequired => get('face_required');
  String get continueToFaceVerification => get('continue_to_face_verification');
  String get faceVerificationInfo => get('face_verification_info');

  // ===== Location =====
  String get location => get('location');
  String get verifyLocation => get('verify_location');
  String get locationVerified => get('location_verified');
  String get locationNotVerified => get('location_not_verified');
  String get verifyLocationFirst => get('verify_location_first');
  String get gettingLocation => get('getting_location');
  String get locationPermissionDenied => get('location_permission_denied');
  String get enableLocationServices => get('enable_location_services');

  // ===== Leave =====
  String get leave => get('leave');
  String get leaveRequest => get('leave_request');
  String get leaveHistory => get('leave_history');
  String get leaveBalance => get('leave_balance');
  String get annualLeave => get('annual_leave');
  String get sickLeave => get('sick_leave');
  String get leaveType => get('leave_type');
  String get startDate => get('start_date');
  String get endDate => get('end_date');
  String get reason => get('reason');

  // ===== Overtime =====
  String get overtimeRequest => get('overtime_request');
  String get overtimeHistory => get('overtime_history');
  String get overtimeOrder => get('overtime_order');
  String get searchOrders => get('search_orders');

  // ===== Pay Slip =====
  String get paySlip => get('pay_slip');
  String get salary => get('salary');
  String get downloadPdf => get('download_pdf');
  String get changePeriod => get('change_period');
  String get period => get('period');

  // ===== Settings =====
  String get language => get('language');
  String get theme => get('theme');
  String get darkMode => get('dark_mode');
  String get lightMode => get('light_mode');
  String get notifications => get('notifications');
  String get biometric => get('biometric');
  String get privacyPolicy => get('privacy_policy');
  String get termsOfService => get('terms_of_service');
  String get version => get('version');

  // ===== Validation Messages =====
  String get fieldRequired => get('field_required');
  String get invalidFormat => get('invalid_format');
  String get minLength => get('min_length');
  String get maxLength => get('max_length');
  String get passwordNotMatch => get('password_not_match');
  String get usernameAlphanumeric => get('username_alphanumeric');
  String get passwordRequirements => get('password_requirements');
  String get nikDigits => get('nik_digits');

  // ===== Error Messages =====
  String get somethingWentWrong => get('something_went_wrong');
  String get connectionError => get('connection_error');
  String get serverError => get('server_error');
  String get timeout => get('timeout');
  String get unauthorized => get('unauthorized');
  String get forbidden => get('forbidden');
  String get notFound => get('not_found');
  String get tryAgain => get('try_again');
  String get contactHrd => get('contact_hrd');

  // ===== Time & Date =====
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get thisWeek => get('this_week');
  String get thisMonth => get('this_month');
  String get selectDate => get('select_date');
  String get selectTime => get('select_time');

  // ===== Status =====
  String get pending => get('pending');
  String get approved => get('approved');
  String get rejected => get('rejected');
  String get completed => get('completed');
  String get cancelled => get('cancelled');
  String get active => get('active');
  String get inactive => get('inactive');

  // ===== Greeting =====
  String get goodMorning => get('good_morning');
  String get goodAfternoon => get('good_afternoon');
  String get goodEvening => get('good_evening');
  String get goodNight => get('good_night');
  String get welcome => get('welcome');
  String get welcomeBack => get('welcome_back');

  // ===== Onboarding =====
  String get skip => get('skip');
  String get getStarted => get('get_started');
  String get onboardingTitle1 => get('onboarding_title_1');
  String get onboardingTitle2 => get('onboarding_title_2');
  String get onboardingTitle3 => get('onboarding_title_3');
  String get onboardingDesc1 => get('onboarding_desc_1');
  String get onboardingDesc2 => get('onboarding_desc_2');
  String get onboardingDesc3 => get('onboarding_desc_3');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['id', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Indonesian Translations
const Map<String, String> _idTranslations = {
  // General
  'app_name': 'HRIS Asuka',
  'loading': 'Memuat...',
  'error': 'Kesalahan',
  'success': 'Berhasil',
  'cancel': 'Batal',
  'confirm': 'Konfirmasi',
  'save': 'Simpan',
  'delete': 'Hapus',
  'edit': 'Ubah',
  'close': 'Tutup',
  'ok': 'OK',
  'yes': 'Ya',
  'no': 'Tidak',
  'retry': 'Coba Lagi',
  'back': 'Kembali',
  'next': 'Selanjutnya',
  'done': 'Selesai',
  'search': 'Cari',
  'no_data': 'Tidak ada data',
  'refresh': 'Perbarui',

  // Authentication
  'login': 'Masuk',
  'logout': 'Keluar',
  'register': 'Daftar',
  'username': 'Username',
  'password': 'Password',
  'confirm_password': 'Konfirmasi Password',
  'forgot_password': 'Lupa Password',
  'reset_password': 'Reset Password',
  'change_password': 'Ubah Password',
  'current_password': 'Password Saat Ini',
  'new_password': 'Password Baru',
  'login_now': 'Masuk Sekarang',
  'login_success': 'Berhasil masuk',
  'logout_success': 'Berhasil keluar',
  'logout_subtitle': 'Keluar dari akun',
  'logout_confirmation': 'Apakah Anda yakin ingin keluar dari akun?',
  'register_success': 'Registrasi berhasil! Silakan masuk.',
  'invalid_credentials': 'Username atau password salah',
  'session_expired': 'Sesi berakhir. Silakan masuk kembali.',
  'already_have_account': 'Sudah punya akun?',
  'dont_have_account': 'Belum punya akun?',

  // Employee & Profile
  'profile': 'Profil',
  'employee': 'Karyawan',
  'employee_id': 'ID Karyawan',
  'nik': 'NIK',
  'fullname': 'Nama Lengkap',
  'position': 'Jabatan',
  'department': 'Departemen',
  'working_period': 'Masa Kerja',
  'investment': 'Investasi',
  'select_employee': 'Pilih Karyawan',
  'search_employee': 'Cari karyawan...',
  'personal_data': 'Data Pribadi',
  'family_data': 'Data Keluarga',
  'education_history': 'Riwayat Pendidikan',
  'work_experience': 'Pengalaman Kerja',
  'training_history': 'Riwayat Pelatihan',
  'position_history': 'Riwayat Jabatan',

  // Navigation & Menu
  'home': 'Beranda',
  'attendance': 'Absensi',
  'menu': 'Menu',
  'settings': 'Pengaturan',
  'about': 'Tentang',
  'help': 'Bantuan',

  // Attendance
  'check_in': 'Check-In',
  'check_out': 'Check-Out',
  'attendance_history': 'Riwayat Absensi',
  'attendance_summary': 'Ringkasan Absensi',
  'today_attendance': 'Absensi Hari Ini',
  'verify_check_in': 'Verifikasi Check-In',
  'verify_check_out': 'Verifikasi Check-Out',
  'check_in_success': 'Check-In berhasil dicatat',
  'check_out_success': 'Check-Out berhasil dicatat',
  'already_checked_in': 'Anda sudah melakukan check-in hari ini',
  'already_checked_out': 'Anda sudah melakukan check-out hari ini',
  'must_check_in_first': 'Anda harus check-in terlebih dahulu',
  'outside_radius': 'Lokasi Anda di luar radius yang diizinkan',
  'present': 'Hadir',
  'absent': 'Tidak Hadir',
  'late': 'Terlambat',
  'early_leave': 'Pulang Awal',
  'overtime': 'Lembur',
  'work_days': 'Hari Kerja',

  // Face Verification
  'face_verification': 'Verifikasi Wajah',
  'verify_face': 'Verifikasi Wajah',
  'face_not_match': 'Wajah tidak cocok dengan foto karyawan terdaftar',
  'face_verification_failed': 'Verifikasi wajah gagal',
  'face_verification_success': 'Verifikasi wajah berhasil',
  'blink_eyes': 'Kedipkan Mata',
  'turn_head_left': 'Putar Kepala ke KIRI',
  'turn_head_right': 'Putar Kepala ke KANAN',
  'smile': 'Tersenyum',
  'position_face_in_frame': 'Posisikan wajah Anda di dalam bingkai',
  'initializing_camera': 'Menginisialisasi kamera...',
  'take_selfie': 'Ambil Foto',
  'retake_photo': 'Foto Ulang',
  'photo_quality_bad': 'Kualitas foto kurang baik. Silakan foto ulang.',
  'liveness_verification_required': 'Verifikasi liveness gagal. Pastikan Anda mengedipkan mata dan menggerakkan kepala.',
  'repeat_verification': 'Ulangi Verifikasi',
  'face_required': 'Silakan ambil foto wajah terlebih dahulu',
  'continue_to_face_verification': 'Lanjutkan ke Verifikasi Wajah',
  'face_verification_info': 'Setelah mengisi form, Anda akan diminta verifikasi wajah untuk memastikan identitas.',

  // Location
  'location': 'Lokasi',
  'verify_location': 'Verifikasi Lokasi',
  'location_verified': 'Lokasi terverifikasi',
  'location_not_verified': 'Lokasi belum terverifikasi',
  'verify_location_first': 'Silakan verifikasi lokasi terlebih dahulu',
  'getting_location': 'Mendapatkan lokasi...',
  'location_permission_denied': 'Izin lokasi ditolak',
  'enable_location_services': 'Aktifkan layanan lokasi',
  'checking_location': 'Memeriksa Lokasi...',
  'update_location': 'Perbarui Lokasi',
  'check_my_location': 'Cek Lokasi Saya',
  'coordinates': 'Koordinat',
  'attendance_locations': 'Lokasi Absensi',
  'nearest': 'Terdekat',
  'no_location_in_radius': 'Tidak ada lokasi dalam radius',
  'location_permission_permanent': 'Izin lokasi ditolak secara permanen. Silakan aktifkan di pengaturan.',
  'location_service_inactive': 'Layanan lokasi tidak aktif. Silakan aktifkan GPS.',

  // Leave
  'leave': 'Cuti',
  'leave_request': 'Pengajuan Cuti',
  'leave_history': 'Riwayat Cuti',
  'leave_balance': 'Saldo Cuti',
  'annual_leave': 'Cuti Tahunan',
  'sick_leave': 'Cuti Sakit',
  'leave_type': 'Jenis Cuti',
  'start_date': 'Tanggal Mulai',
  'end_date': 'Tanggal Selesai',
  'reason': 'Alasan',

  // Overtime
  'overtime_request': 'Pengajuan Lembur',
  'overtime_history': 'Riwayat Lembur',
  'overtime_order': 'Surat Perintah Lembur',
  'search_orders': 'Cari Surat Perintah...',

  // Pay Slip
  'pay_slip': 'Slip Gaji',
  'salary': 'Gaji',
  'download_pdf': 'Unduh PDF',
  'change_period': 'Ubah Periode',
  'period': 'Periode',

  // Settings
  'language': 'Bahasa',
  'theme': 'Tema',
  'dark_mode': 'Mode Gelap',
  'light_mode': 'Mode Terang',
  'notifications': 'Notifikasi',
  'biometric': 'Biometrik',
  'privacy_policy': 'Kebijakan Privasi',
  'terms_of_service': 'Syarat dan Ketentuan',
  'version': 'Versi',

  // Validation Messages
  'field_required': 'Field ini wajib diisi',
  'invalid_format': 'Format tidak valid',
  'min_length': 'Minimal {0} karakter',
  'max_length': 'Maksimal {0} karakter',
  'password_not_match': 'Password tidak cocok',
  'username_alphanumeric': 'Username hanya boleh mengandung huruf dan angka',
  'password_requirements': 'Password harus mengandung huruf besar, huruf kecil, angka, dan karakter khusus',
  'nik_digits': 'NIK harus 16 digit',

  // Error Messages
  'something_went_wrong': 'Terjadi kesalahan',
  'connection_error': 'Kesalahan koneksi. Periksa internet Anda.',
  'server_error': 'Kesalahan server. Coba lagi nanti.',
  'timeout': 'Waktu habis. Coba lagi.',
  'unauthorized': 'Tidak diizinkan',
  'forbidden': 'Akses ditolak',
  'not_found': 'Data tidak ditemukan',
  'try_again': 'Coba Lagi',
  'contact_hrd': 'Hubungi HRD',

  // Time & Date
  'today': 'Hari Ini',
  'yesterday': 'Kemarin',
  'this_week': 'Minggu Ini',
  'this_month': 'Bulan Ini',
  'select_date': 'Pilih Tanggal',
  'select_time': 'Pilih Waktu',

  // Status
  'pending': 'Menunggu',
  'approved': 'Disetujui',
  'rejected': 'Ditolak',
  'completed': 'Selesai',
  'cancelled': 'Dibatalkan',
  'active': 'Aktif',
  'inactive': 'Tidak Aktif',

  // Greeting
  'good_morning': 'Selamat Pagi',
  'good_afternoon': 'Selamat Siang',
  'good_evening': 'Selamat Sore',
  'good_night': 'Selamat Malam',
  'welcome': 'Selamat Datang',
  'welcome_back': 'Selamat Datang Kembali',

  // Onboarding
  'skip': 'Lewati',
  'get_started': 'Mulai',
  'onboarding_title_1': 'Selamat Datang di HRIS Asuka',
  'onboarding_title_2': 'Absensi Mudah & Cepat',
  'onboarding_title_3': 'Kelola Data Karyawan',
  'onboarding_desc_1': 'Aplikasi HRIS untuk memudahkan pengelolaan data karyawan PT. Asuka Primabudi',
  'onboarding_desc_2': 'Absensi dengan verifikasi wajah dan lokasi GPS untuk keamanan maksimal',
  'onboarding_desc_3': 'Akses data pribadi, slip gaji, cuti, dan lembur dengan mudah',

  // Profile Menu
  'profile_menu': 'Menu Profil',
  'check_clock_history': 'Riwayat Absensi',
  'attendance_records': 'Catatan kehadiran',
  'personal_info': 'Informasi pribadi',
  'family_info': 'Informasi keluarga',
  'career_progression': 'Riwayat karir',
  'certifications_courses': 'Sertifikasi & pelatihan',
  'previous_employment': 'Pekerjaan sebelumnya',
  'academic_background': 'Riwayat akademik',
  'change_password_subtitle': 'Ubah password akun Anda',

  // Login Screen
  'sign_in_to_continue': 'Masuk untuk melanjutkan',
  'enter_username': 'Masukkan username Anda',
  'enter_password': 'Masukkan password Anda',
  'remember_me': 'Ingat Saya',
  'register_now': 'Daftar Sekarang',
  'all_rights_reserved': '© 2025 HRIS Asuka. Hak cipta dilindungi.',
  'welcome_user': 'Selamat datang, {name}!',

  // Register Screen
  'create_account': 'Buat Akun',
  'register_to_start': 'Daftar untuk memulai',
  'type_to_search': 'Ketik minimal 3 karakter untuk mencari...',
  'employee_required': 'Pilihan karyawan wajib diisi',
  'nik_16_digit': 'NIK (16 Digit)',
  'enter_16_digit_nik': 'Masukkan NIK 16 digit',
  'enter_username_hint': 'Masukkan username (6-12 karakter)',
  'username_requirements': 'Ketentuan Username:',
  'username_requirements_detail': '• 6-12 karakter\n• Hanya huruf dan angka (a-z, A-Z, 0-9)',
  'enter_password_hint': 'Masukkan password (min. 12 karakter)',
  'password_requirements_title': 'Ketentuan Password:',
  'password_requirements_detail': '• Minimal 12 karakter\n• Huruf besar (A-Z)\n• Huruf kecil (a-z)\n• Angka (0-9)\n• Karakter khusus (!@#\$%^&*)',
  'confirm_your_password': 'Konfirmasi password Anda',

  // Forgot Password Screen
  'verify_identity': 'Verifikasi Identitas',
  'enter_username_nik_verify': 'Masukkan username dan NIK Anda untuk verifikasi identitas',
  'after_verify_face': 'Setelah verifikasi identitas, Anda akan diminta untuk melakukan verifikasi wajah.',
  'nik_full': 'NIK (Nomor Induk Kependudukan)',
  'enter_16_digit_nik_hint': 'Masukkan 16 digit NIK',
  'back_to_login': 'Kembali ke Login',

  // Reset Password Screen
  'password_reset_success': 'Password Berhasil Direset!',
  'login_with_new_password': 'Silakan login dengan password baru Anda.',
  'identity_verified': 'Identitas Terverifikasi',
  'create_new_password': 'Buat Password Baru',
  'enter_new_password_desc': 'Masukkan password baru untuk akun Anda',
  'password_min_12_chars': 'Password harus minimal 12 karakter dengan huruf besar, huruf kecil, angka, dan karakter khusus.',
  'enter_new_password': 'Masukkan password baru',
  'confirm_new_password': 'Konfirmasi Password Baru',
  'confirm_new_password_hint': 'Konfirmasi password baru',

  // Face Verification - Liveness Detection
  'no_camera_available': 'Tidak ada kamera yang tersedia',
  'camera_init_failed': 'Gagal menginisialisasi kamera',
  'liveness_verified': 'Liveness Terverifikasi',
  'verification_success': 'Verifikasi Berhasil!',
  'press_take_photo': 'Tekan tombol AMBIL FOTO',
  'start_verification': 'MULAI VERIFIKASI',
  'confirm_check_in': 'KONFIRMASI CHECK-IN',
  'confirm_check_out': 'KONFIRMASI CHECK-OUT',
  'save_attendance_failed': 'Gagal menyimpan absensi',
  'time_label': 'Waktu',
  'location_label': 'Lokasi',
  'fake_gps_detected': 'Fake GPS terdeteksi! Absensi tidak dapat dilakukan.',
  'nod_head': 'Anggukan Kepala',
  'raise_eyebrows': 'Angkat Alis',
  'open_mouth': 'Buka Mulut',
  'preparing_verification': 'Mempersiapkan verifikasi...',
  'look_at_camera': 'Lihat ke kamera',
  'challenge_completed': 'Tantangan selesai!',
  'verification_in_progress': 'Verifikasi sedang berlangsung...',

  // Change Password Validation
  'new_password_required': 'Password baru wajib diisi',
  'password_min_12': 'Password minimal 12 karakter',
  'password_max_128': 'Password maksimal 128 karakter',
  'password_need_uppercase': 'Password harus ada huruf besar (A-Z)',
  'password_need_lowercase': 'Password harus ada huruf kecil (a-z)',
  'password_need_number': 'Password harus ada angka (0-9)',
  'password_need_special': 'Password harus ada karakter khusus (!@#\$%^&*)',
  'password_too_common': 'Password terlalu umum',
  'password_must_different': 'Password baru harus berbeda dengan password lama',
  'password_changed_success': 'Password berhasil diubah',
  'password_change_failed': 'Gagal mengubah password',

  // Attendance
  'in_label': 'Masuk',
  'out_label': 'Keluar',
  'clear': 'Hapus',

  // Home Page
  'statistics_month': 'Statistik {month}',
  'last_month_statistics': 'Statistik Bulan Lalu',
  'main_menu': 'Menu Utama',
  'overtime_orders': 'Surat Perintah\nLembur',
  'employee_leave': 'Cuti\nKaryawan',
  'pay_slip_menu': 'Slip\nGaji',
  'attendance_history_menu': 'Riwayat\nAbsensi',
  'tap_to_retry': 'Tap untuk coba lagi',
  'coming_soon': 'Segera Hadir',
  'feature_coming_soon': 'Fitur {feature} akan segera tersedia!',

  // Onboarding
  'onboarding_1_title': 'Absensi Mudah',
  'onboarding_1_desc': 'Lakukan check-in dan check-out dengan mudah menggunakan GPS dan verifikasi wajah untuk keamanan maksimal.',
  'onboarding_2_title': 'Lokasi Terverifikasi',
  'onboarding_2_desc': 'Pastikan Anda berada di lokasi yang tepat. Sistem akan memvalidasi lokasi Anda secara otomatis.',
  'onboarding_3_title': 'Pengenalan Wajah',
  'onboarding_3_desc': 'Keamanan ekstra dengan teknologi pengenalan wajah. Pastikan yang absen adalah Anda sendiri.',
  'onboarding_4_title': 'Riwayat Lengkap',
  'onboarding_4_desc': 'Pantau riwayat kehadiran Anda dengan mudah. Lihat statistik dan detail absensi kapan saja.',
  'start_now': 'Mulai Sekarang',
  'continue_button': 'Lanjutkan',

  // Attendance Status Box
  'attendance_status': 'Status Kehadiran',
  'location_invalid': 'Lokasi Tidak Valid',
  'nearest_location_info': 'Lokasi terdekat: {location}\n({distance}m dari posisi Anda)',
  'status_work': 'MASUK',
  'status_late': 'TERLAMBAT',
  'status_absent': 'TIDAK HADIR',
  'status_leave': 'CUTI',
  'status_not_yet': 'BELUM',
};

// English Translations
const Map<String, String> _enTranslations = {
  // General
  'app_name': 'HRIS Asuka',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'close': 'Close',
  'ok': 'OK',
  'yes': 'Yes',
  'no': 'No',
  'retry': 'Retry',
  'back': 'Back',
  'next': 'Next',
  'done': 'Done',
  'search': 'Search',
  'no_data': 'No data',
  'refresh': 'Refresh',

  // Authentication
  'login': 'Login',
  'logout': 'Logout',
  'register': 'Register',
  'username': 'Username',
  'password': 'Password',
  'confirm_password': 'Confirm Password',
  'forgot_password': 'Forgot Password',
  'reset_password': 'Reset Password',
  'change_password': 'Change Password',
  'current_password': 'Current Password',
  'new_password': 'New Password',
  'login_now': 'Login Now',
  'login_success': 'Login successful',
  'logout_success': 'Logout successful',
  'logout_subtitle': 'Sign out from account',
  'logout_confirmation': 'Are you sure you want to sign out?',
  'register_success': 'Registration successful! Please login.',
  'invalid_credentials': 'Invalid username or password',
  'session_expired': 'Session expired. Please login again.',
  'already_have_account': 'Already have an account?',
  'dont_have_account': 'Don\'t have an account?',

  // Employee & Profile
  'profile': 'Profile',
  'employee': 'Employee',
  'employee_id': 'Employee ID',
  'nik': 'NIK',
  'fullname': 'Full Name',
  'position': 'Position',
  'department': 'Department',
  'working_period': 'Working Period',
  'investment': 'Investment',
  'select_employee': 'Select Employee',
  'search_employee': 'Search employee...',
  'personal_data': 'Personal Data',
  'family_data': 'Family Data',
  'education_history': 'Education History',
  'work_experience': 'Work Experience',
  'training_history': 'Training History',
  'position_history': 'Position History',

  // Navigation & Menu
  'home': 'Home',
  'attendance': 'Attendance',
  'menu': 'Menu',
  'settings': 'Settings',
  'about': 'About',
  'help': 'Help',

  // Attendance
  'check_in': 'Check-In',
  'check_out': 'Check-Out',
  'attendance_history': 'Attendance History',
  'attendance_summary': 'Attendance Summary',
  'today_attendance': 'Today\'s Attendance',
  'verify_check_in': 'Verify Check-In',
  'verify_check_out': 'Verify Check-Out',
  'check_in_success': 'Check-In recorded successfully',
  'check_out_success': 'Check-Out recorded successfully',
  'already_checked_in': 'You have already checked in today',
  'already_checked_out': 'You have already checked out today',
  'must_check_in_first': 'You must check in first',
  'outside_radius': 'Your location is outside the allowed radius',
  'present': 'Present',
  'absent': 'Absent',
  'late': 'Late',
  'early_leave': 'Early Leave',
  'overtime': 'Overtime',
  'work_days': 'Work Days',

  // Face Verification
  'face_verification': 'Face Verification',
  'verify_face': 'Verify Face',
  'face_not_match': 'Face does not match the registered employee photo',
  'face_verification_failed': 'Face verification failed',
  'face_verification_success': 'Face verification successful',
  'blink_eyes': 'Blink Your Eyes',
  'turn_head_left': 'Turn Head LEFT',
  'turn_head_right': 'Turn Head RIGHT',
  'smile': 'Smile',
  'position_face_in_frame': 'Position your face within the frame',
  'initializing_camera': 'Initializing camera...',
  'take_selfie': 'Take Photo',
  'retake_photo': 'Retake Photo',
  'photo_quality_bad': 'Photo quality is poor. Please retake.',
  'liveness_verification_required': 'Liveness verification failed. Make sure to blink and move your head.',
  'repeat_verification': 'Repeat Verification',
  'face_required': 'Please take a face photo first',
  'continue_to_face_verification': 'Continue to Face Verification',
  'face_verification_info': 'After filling the form, you will be asked to verify your face to confirm your identity.',

  // Location
  'location': 'Location',
  'verify_location': 'Verify Location',
  'location_verified': 'Location verified',
  'location_not_verified': 'Location not verified',
  'verify_location_first': 'Please verify your location first',
  'getting_location': 'Getting location...',
  'location_permission_denied': 'Location permission denied',
  'enable_location_services': 'Enable location services',
  'checking_location': 'Checking Location...',
  'update_location': 'Update Location',
  'check_my_location': 'Check My Location',
  'coordinates': 'Coordinates',
  'attendance_locations': 'Attendance Locations',
  'nearest': 'Nearest',
  'no_location_in_radius': 'No location within radius',

  // Leave
  'leave': 'Leave',
  'leave_request': 'Leave Request',
  'leave_history': 'Leave History',
  'leave_balance': 'Leave Balance',
  'annual_leave': 'Annual Leave',
  'sick_leave': 'Sick Leave',
  'leave_type': 'Leave Type',
  'start_date': 'Start Date',
  'end_date': 'End Date',
  'reason': 'Reason',

  // Overtime
  'overtime_request': 'Overtime Request',
  'overtime_history': 'Overtime History',
  'overtime_order': 'Overtime Order',
  'search_orders': 'Search Orders...',

  // Pay Slip
  'pay_slip': 'Pay Slip',
  'salary': 'Salary',
  'download_pdf': 'Download PDF',
  'change_period': 'Change Period',
  'period': 'Period',

  // Settings
  'language': 'Language',
  'theme': 'Theme',
  'dark_mode': 'Dark Mode',
  'light_mode': 'Light Mode',
  'notifications': 'Notifications',
  'biometric': 'Biometric',
  'privacy_policy': 'Privacy Policy',
  'terms_of_service': 'Terms of Service',
  'version': 'Version',

  // Validation Messages
  'field_required': 'This field is required',
  'invalid_format': 'Invalid format',
  'min_length': 'Minimum {0} characters',
  'max_length': 'Maximum {0} characters',
  'password_not_match': 'Passwords do not match',
  'username_alphanumeric': 'Username must contain only letters and numbers',
  'password_requirements': 'Password must contain uppercase, lowercase, number, and special character',
  'nik_digits': 'NIK must be 16 digits',

  // Error Messages
  'something_went_wrong': 'Something went wrong',
  'connection_error': 'Connection error. Check your internet.',
  'server_error': 'Server error. Try again later.',
  'timeout': 'Timeout. Please try again.',
  'unauthorized': 'Unauthorized',
  'forbidden': 'Access denied',
  'not_found': 'Data not found',
  'try_again': 'Try Again',
  'contact_hrd': 'Contact HRD',

  // Time & Date
  'today': 'Today',
  'yesterday': 'Yesterday',
  'this_week': 'This Week',
  'this_month': 'This Month',
  'select_date': 'Select Date',
  'select_time': 'Select Time',

  // Status
  'pending': 'Pending',
  'approved': 'Approved',
  'rejected': 'Rejected',
  'completed': 'Completed',
  'cancelled': 'Cancelled',
  'active': 'Active',
  'inactive': 'Inactive',

  // Greeting
  'good_morning': 'Good Morning',
  'good_afternoon': 'Good Afternoon',
  'good_evening': 'Good Evening',
  'good_night': 'Good Night',
  'welcome': 'Welcome',
  'welcome_back': 'Welcome Back',

  // Onboarding
  'skip': 'Skip',
  'get_started': 'Get Started',
  'onboarding_title_1': 'Welcome to HRIS Asuka',
  'onboarding_title_2': 'Easy & Fast Attendance',
  'onboarding_title_3': 'Manage Employee Data',
  'onboarding_desc_1': 'HRIS application to facilitate employee data management of PT. Asuka Primabudi',
  'onboarding_desc_2': 'Attendance with face verification and GPS location for maximum security',
  'onboarding_desc_3': 'Access personal data, pay slips, leave, and overtime easily',

  // Profile Menu
  'profile_menu': 'Profile Menu',
  'check_clock_history': 'Attendance History',
  'attendance_records': 'Attendance records',
  'personal_info': 'Personal information',
  'family_info': 'Family information',
  'career_progression': 'Career progression',
  'certifications_courses': 'Certifications & courses',
  'previous_employment': 'Previous employment',
  'academic_background': 'Academic background',
  'change_password_subtitle': 'Change your password',

  // Login Screen
  'sign_in_to_continue': 'Sign in to continue',
  'enter_username': 'Enter your username',
  'enter_password': 'Enter your password',
  'remember_me': 'Remember Me',
  'register_now': 'Register Now',
  'all_rights_reserved': '© 2025 HRIS Asuka. All rights reserved.',
  'welcome_user': 'Welcome, {name}!',

  // Register Screen
  'create_account': 'Create Account',
  'register_to_start': 'Register to get started',
  'type_to_search': 'Type at least 3 characters to search...',
  'employee_required': 'Employee selection is required',
  'nik_16_digit': 'NIK (16 Digits)',
  'enter_16_digit_nik': 'Enter 16 digit NIK',
  'enter_username_hint': 'Enter username (6-12 characters)',
  'username_requirements': 'Username Requirements:',
  'username_requirements_detail': '• 6-12 characters\n• Letters and numbers only (a-z, A-Z, 0-9)',
  'enter_password_hint': 'Enter password (min. 12 characters)',
  'password_requirements_title': 'Password Requirements:',
  'password_requirements_detail': '• Minimum 12 characters\n• Uppercase letter (A-Z)\n• Lowercase letter (a-z)\n• Number (0-9)\n• Special character (!@#\$%^&*)',
  'confirm_your_password': 'Confirm your password',

  // Forgot Password Screen
  'verify_identity': 'Verify Identity',
  'enter_username_nik_verify': 'Enter your username and NIK to verify your identity',
  'after_verify_face': 'After identity verification, you will be asked to perform face verification.',
  'nik_full': 'NIK (National ID Number)',
  'enter_16_digit_nik_hint': 'Enter 16 digit NIK',
  'back_to_login': 'Back to Login',

  // Reset Password Screen
  'password_reset_success': 'Password Reset Successful!',
  'login_with_new_password': 'Please login with your new password.',
  'identity_verified': 'Identity Verified',
  'create_new_password': 'Create New Password',
  'enter_new_password_desc': 'Enter a new password for your account',
  'password_min_12_chars': 'Password must be at least 12 characters with uppercase, lowercase, numbers, and special characters.',
  'enter_new_password': 'Enter new password',
  'confirm_new_password': 'Confirm New Password',
  'confirm_new_password_hint': 'Confirm new password',

  // Face Verification - Liveness Detection
  'no_camera_available': 'No camera available',
  'camera_init_failed': 'Failed to initialize camera',
  'liveness_verified': 'Liveness Verified',
  'verification_success': 'Verification Successful!',
  'press_take_photo': 'Press TAKE PHOTO button',
  'start_verification': 'START VERIFICATION',
  'confirm_check_in': 'CONFIRM CHECK-IN',
  'confirm_check_out': 'CONFIRM CHECK-OUT',
  'save_attendance_failed': 'Failed to save attendance',
  'time_label': 'Time',
  'location_label': 'Location',
  'fake_gps_detected': 'Fake GPS detected! Attendance cannot be recorded.',
  'location_permission_permanent': 'Location permission permanently denied. Please enable in settings.',
  'location_service_inactive': 'Location service is inactive. Please enable GPS.',
  'nod_head': 'Nod Your Head',
  'raise_eyebrows': 'Raise Eyebrows',
  'open_mouth': 'Open Mouth',
  'preparing_verification': 'Preparing verification...',
  'look_at_camera': 'Look at the camera',
  'challenge_completed': 'Challenge completed!',
  'verification_in_progress': 'Verification in progress...',

  // Change Password Validation
  'new_password_required': 'New password is required',
  'password_min_12': 'Password must be at least 12 characters',
  'password_max_128': 'Password must be at most 128 characters',
  'password_need_uppercase': 'Password must contain uppercase letter (A-Z)',
  'password_need_lowercase': 'Password must contain lowercase letter (a-z)',
  'password_need_number': 'Password must contain number (0-9)',
  'password_need_special': 'Password must contain special character (!@#\$%^&*)',
  'password_too_common': 'Password is too common',
  'password_must_different': 'New password must be different from current password',
  'password_changed_success': 'Password changed successfully',
  'password_change_failed': 'Failed to change password',

  // Attendance
  'in_label': 'In',
  'out_label': 'Out',
  'clear': 'Clear',

  // Home Page
  'statistics_month': '{month} Statistics',
  'last_month_statistics': 'Last Month Statistics',
  'main_menu': 'Main Menu',
  'overtime_orders': 'Overtime\nOrders',
  'employee_leave': 'Employee\nLeave',
  'pay_slip_menu': 'Pay\nSlip',
  'attendance_history_menu': 'Attendance\nHistory',
  'tap_to_retry': 'Tap to retry',
  'coming_soon': 'Coming Soon',
  'feature_coming_soon': '{feature} feature will be available soon!',

  // Onboarding
  'onboarding_1_title': 'Easy Attendance',
  'onboarding_1_desc': 'Check-in and check-out easily using GPS and face verification for maximum security.',
  'onboarding_2_title': 'Verified Location',
  'onboarding_2_desc': 'Make sure you are in the right location. The system will validate your location automatically.',
  'onboarding_3_title': 'Face Recognition',
  'onboarding_3_desc': 'Extra security with face recognition technology. Ensure that the one checking in is really you.',
  'onboarding_4_title': 'Complete History',
  'onboarding_4_desc': 'Track your attendance history easily. View statistics and attendance details anytime.',
  'start_now': 'Start Now',
  'continue_button': 'Continue',

  // Attendance Status Box
  'attendance_status': 'Attendance Status',
  'location_invalid': 'Invalid Location',
  'nearest_location_info': 'Nearest location: {location}\n({distance}m from your position)',
  'status_work': 'WORK',
  'status_late': 'LATE',
  'status_absent': 'ABSENT',
  'status_leave': 'LEAVE',
  'status_not_yet': 'NOT YET',
};

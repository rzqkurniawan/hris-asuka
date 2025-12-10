import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

enum EmptyStateType {
  noData,
  noResults,
  noConnection,
  error,
  noAttendance,
  noLeave,
  noOvertime,
  noHistory,
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyStateType.noData,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final data = _getDataForType();

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    color: data.color,
                    size: 40.sp,
                  ),
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                )
                .then()
                .animate()
                .fadeIn(duration: 500.ms),

            SizedBox(height: 24.h),

            // Title
            Text(
              title ?? data.title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.3, end: 0),

            SizedBox(height: 12.h),

            // Message
            Text(
              message ?? data.message,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 300.ms)
                .slideY(begin: 0.3, end: 0),

            if (onRetry != null) ...[
              SizedBox(height: 32.h),

              // Retry Button
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: data.color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  type == EmptyStateType.error || type == EmptyStateType.noConnection
                      ? Icons.refresh_rounded
                      : Icons.add_rounded,
                  size: 20.sp,
                ),
                label: Text(
                  retryLabel ?? (type == EmptyStateType.error || type == EmptyStateType.noConnection
                      ? 'Coba Lagi'
                      : 'Tambah'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
            ],
          ],
        ),
      ),
    );
  }

  _EmptyStateData _getDataForType() {
    switch (type) {
      case EmptyStateType.noData:
        return _EmptyStateData(
          icon: Icons.inbox_rounded,
          title: 'Tidak Ada Data',
          message: 'Data yang Anda cari tidak tersedia saat ini.',
          color: const Color(0xFF64748B),
        );
      case EmptyStateType.noResults:
        return _EmptyStateData(
          icon: Icons.search_off_rounded,
          title: 'Tidak Ditemukan',
          message: 'Pencarian Anda tidak menemukan hasil. Coba gunakan kata kunci lain.',
          color: const Color(0xFF0EA5E9),
        );
      case EmptyStateType.noConnection:
        return _EmptyStateData(
          icon: Icons.wifi_off_rounded,
          title: 'Tidak Ada Koneksi',
          message: 'Periksa koneksi internet Anda dan coba lagi.',
          color: const Color(0xFFF59E0B),
        );
      case EmptyStateType.error:
        return _EmptyStateData(
          icon: Icons.error_outline_rounded,
          title: 'Terjadi Kesalahan',
          message: 'Maaf, terjadi kesalahan. Silakan coba lagi nanti.',
          color: const Color(0xFFEF4444),
        );
      case EmptyStateType.noAttendance:
        return _EmptyStateData(
          icon: Icons.fingerprint_rounded,
          title: 'Belum Ada Absensi',
          message: 'Anda belum melakukan absensi hari ini. Tap tombol di bawah untuk absen.',
          color: const Color(0xFF10B981),
        );
      case EmptyStateType.noLeave:
        return _EmptyStateData(
          icon: Icons.beach_access_rounded,
          title: 'Tidak Ada Cuti',
          message: 'Anda belum memiliki pengajuan cuti. Ajukan cuti baru jika diperlukan.',
          color: const Color(0xFF8B5CF6),
        );
      case EmptyStateType.noOvertime:
        return _EmptyStateData(
          icon: Icons.access_time_rounded,
          title: 'Tidak Ada Lembur',
          message: 'Belum ada catatan lembur. Lembur akan muncul setelah disetujui.',
          color: const Color(0xFFEC4899),
        );
      case EmptyStateType.noHistory:
        return _EmptyStateData(
          icon: Icons.history_rounded,
          title: 'Tidak Ada Riwayat',
          message: 'Riwayat Anda masih kosong. Data akan muncul setelah ada aktivitas.',
          color: const Color(0xFF6366F1),
        );
    }
  }
}

class _EmptyStateData {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  _EmptyStateData({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}

/// Error state widget with more prominent styling
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFFEF4444).withOpacity(0.1)
                : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                  size: 40.sp,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .shake(hz: 2, duration: 500.ms)
                  .then(delay: 2000.ms),

              SizedBox(height: 20.h),

              Text(
                title ?? 'Oops! Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              Text(
                message ?? 'Mohon maaf, terjadi kesalahan saat memuat data. Silakan coba lagi.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF7F1D1D),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              if (onRetry != null) ...[
                SizedBox(height: 24.h),

                OutlinedButton.icon(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(Icons.refresh_rounded, size: 18.sp),
                  label: Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

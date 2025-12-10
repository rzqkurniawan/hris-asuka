import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceDetailPage extends StatefulWidget {
  final int month;
  final int year;
  final String monthYear;
  final MonthlySummary summary;

  const AttendanceDetailPage({
    super.key,
    required this.month,
    required this.year,
    required this.monthYear,
    required this.summary,
  });

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  final AttendanceService _attendanceService = AttendanceService();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<AttendanceRecord> records = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttendanceDetail();
  }

  Future<void> _loadAttendanceDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final detailResponse = await _attendanceService.getAttendanceDetail(
        month: widget.month,
        year: widget.year,
      );

      setState(() {
        records = detailResponse.records;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance detail: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode
            ? AppColors.surfaceDark
            : AppColors.primaryLight,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          children: [
            const Text(
              'Detail Check Clock',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.monthYear,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildQuickSummary(isDarkMode),
                Expanded(
                  child: _buildAttendanceTable(isDarkMode),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickSummary(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? AppColors.primaryGradientDark
            : AppColors.primaryGradientLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat(
            'Masuk',
            widget.summary.masuk.toString(),
            Icons.check_circle,
          ),
          _buildQuickStat(
            'Alpha',
            widget.summary.alpha.toString(),
            Icons.cancel,
          ),
          _buildQuickStat(
            'Izin',
            widget.summary.izin.toString(),
            Icons.event_note,
          ),
          _buildQuickStat(
            'Sakit',
            widget.summary.sakit.toString(),
            Icons.local_hospital,
          ),
          _buildQuickStat(
            'Cuti',
            widget.summary.cuti.toString(),
            Icons.beach_access,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTable(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(isDarkMode),
          Divider(
            height: 1,
            color: isDarkMode
                ? AppColors.surfaceAltDark
                : const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  child: _buildTableContent(isDarkMode),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.table_chart,
            color: isDarkMode
                ? AppColors.primaryDark
                : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Data Check Clock (${records.length} Records)',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent(bool isDarkMode) {
    return DataTable(
      columnSpacing: 24,
      horizontalMargin: 16,
      headingRowColor: MaterialStateProperty.all(
        isDarkMode ? AppColors.surfaceAltDark : const Color(0xFFF1F5F9),
      ),
      headingRowHeight: 56,
      dataRowHeight: 64,
      columns: [
        _buildDataColumn('No.', isDarkMode),
        _buildDataColumn('Check Clock Date', isDarkMode),
        _buildDataColumn('Day', isDarkMode),
        _buildDataColumn('Check In', isDarkMode),
        _buildDataColumn('Check Out', isDarkMode),
        _buildDataColumn('SPKL Start', isDarkMode),
        _buildDataColumn('SPKL End', isDarkMode),
        _buildDataColumn('Emergency Call', isDarkMode),
        _buildDataColumn('No Lunch', isDarkMode),
        _buildDataColumn('Holiday Notes', isDarkMode),
        _buildDataColumn('Shift', isDarkMode),
        _buildDataColumn('Work Schedule Type', isDarkMode),
        _buildDataColumn('Late Permission', isDarkMode),
      ],
      rows: records.map((record) {
        return DataRow(
          cells: [
            DataCell(_buildCell(record.no.toString(), isDarkMode)),
            DataCell(_buildCell(record.formattedDate, isDarkMode)),
            DataCell(_buildDayCell(record.day, record.isWeekend, isDarkMode)),
            DataCell(_buildTimeCell(record.checkIn, isDarkMode)),
            DataCell(_buildTimeCell(record.checkOut, isDarkMode)),
            DataCell(_buildCell(record.startCall, isDarkMode)),
            DataCell(_buildCell(record.endCall, isDarkMode)),
            DataCell(_buildBooleanCell(record.emergencyCall, isDarkMode)),
            DataCell(_buildBooleanCell(record.noLunch, isDarkMode)),
            DataCell(_buildHolidayCell(record.computedHolidayNotes, isDarkMode)),
            DataCell(_buildCell(record.shiftCategory, isDarkMode)),
            DataCell(_buildCell(record.typeWorkHour, isDarkMode)),
            DataCell(_buildBooleanCell(record.permissionLate, isDarkMode)),
          ],
        );
      }).toList(),
    );
  }

  DataColumn _buildDataColumn(String label, bool isDarkMode) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCell(String text, bool isDarkMode) {
    return Text(
      text,
      style: TextStyle(
        color: isDarkMode
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        fontSize: 13,
      ),
    );
  }

  Widget _buildDayCell(String day, bool isWeekend, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWeekend
            ? (isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
            : (isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        day,
        style: TextStyle(
          color: isWeekend
              ? (isDarkMode ? const Color(0xFFFCA5A5) : AppColors.statusAbsent)
              : (isDarkMode ? const Color(0xFF6EE7B7) : AppColors.statusWork),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeCell(String time, bool isDarkMode) {
    final isAbsent = time == '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAbsent
            ? (isDarkMode ? AppColors.surfaceAltDark : const Color(0xFFF1F5F9))
            : (isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: isAbsent
                ? (isDarkMode ? AppColors.textSecondaryDark : const Color(0xFF94A3B8))
                : (isDarkMode ? const Color(0xFF6EE7B7) : AppColors.statusWork),
          ),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              color: isAbsent
                  ? (isDarkMode ? AppColors.textSecondaryDark : const Color(0xFF94A3B8))
                  : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanCell(bool value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: value
            ? (isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
            : (isDarkMode ? AppColors.surfaceAltDark : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value
              ? (isDarkMode ? const Color(0xFF6EE7B7) : AppColors.statusWork)
              : (isDarkMode ? AppColors.surfaceAltDark : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: Text(
        value ? 'Ya' : 'Tidak',
        style: TextStyle(
          color: value
              ? (isDarkMode ? const Color(0xFF6EE7B7) : AppColors.statusWork)
              : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHolidayCell(String notes, bool isDarkMode) {
    final isOT = notes == 'LIBUR/OT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOT
            ? (isDarkMode ? const Color(0xFF0C4A6E) : const Color(0xFFDEEBFF))
            : (isDarkMode ? AppColors.surfaceAltDark : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOT
              ? (isDarkMode ? AppColors.primaryDark : AppColors.secondaryLight)
              : (isDarkMode ? AppColors.surfaceAltDark : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOT)
            Icon(
              Icons.work,
              size: 14,
              color: isDarkMode
                  ? AppColors.primaryDark
                  : AppColors.secondaryLight,
            ),
          if (isOT) const SizedBox(width: 4),
          Text(
            notes,
            style: TextStyle(
              color: isOT
                  ? (isDarkMode ? AppColors.primaryDark : AppColors.primaryLight)
                  : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              fontSize: 12,
              fontWeight: isOT ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

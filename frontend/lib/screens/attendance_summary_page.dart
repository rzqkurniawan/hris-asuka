import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/page_transitions.dart';
import 'attendance_detail_page.dart';

class AttendanceSummaryPage extends StatefulWidget {
  const AttendanceSummaryPage({super.key});

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  final AttendanceService _attendanceService = AttendanceService();

  List<int> availableYears = [];
  List<int> availableMonths = [];
  Map<int, List<int>> periodsByYear = {};

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  MonthlySummary? currentSummary;

  bool isLoading = true;
  bool isSummaryLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load available periods first
      final periodsResponse = await _attendanceService.getAvailablePeriods();

      // Ensure current year is always included
      final currentYear = DateTime.now().year;
      List<int> yearsList = List<int>.from(periodsResponse.availableYears);
      if (!yearsList.contains(currentYear)) {
        yearsList.insert(0, currentYear);
      }
      // Sort years descending
      yearsList.sort((a, b) => b.compareTo(a));

      setState(() {
        availableYears = yearsList;
        periodsByYear = periodsResponse.periodsByYear;

        // Set initial selected year if not available
        if (availableYears.isNotEmpty && !availableYears.contains(selectedYear)) {
          selectedYear = availableYears.first;
        }

        _updateAvailableMonths();
        isLoading = false;
      });

      // Load summary for selected period
      await _loadSummary();

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance data: $e')),
        );
      }
    }
  }

  void _updateAvailableMonths() {
    // Get months from periods or use all months for current year
    availableMonths = periodsByYear[selectedYear] ?? [];

    // If no months available (e.g., new year), show all months up to current
    if (availableMonths.isEmpty) {
      final now = DateTime.now();
      if (selectedYear == now.year) {
        // For current year, show months up to current month
        availableMonths = List.generate(now.month, (i) => i + 1);
      } else if (selectedYear > now.year) {
        // For future year, show January only
        availableMonths = [1];
      } else {
        // For past years without data, show all months
        availableMonths = List.generate(12, (i) => i + 1);
      }
    }

    // Set initial selected month if not available
    if (availableMonths.isNotEmpty && !availableMonths.contains(selectedMonth)) {
      selectedMonth = availableMonths.first;
    }
  }

  Future<void> _loadSummary() async {
    if (availableMonths.isEmpty) {
      setState(() {
        currentSummary = null;
      });
      return;
    }

    setState(() {
      isSummaryLoading = true;
    });

    try {
      final summary = await _attendanceService.getAttendanceSummary(
        month: selectedMonth,
        year: selectedYear,
      );

      setState(() {
        currentSummary = summary;
        isSummaryLoading = false;
      });
    } catch (e) {
      setState(() {
        isSummaryLoading = false;
        errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load summary: $e')),
        );
      }
    }
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
          icon: Icon(Icons.arrow_back, color: AppColors.overlayLight),
        ),
        title: Text(
          'Attendance Summary',
          style: TextStyle(
            color: AppColors.overlayLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoadingView()
          : currentSummary == null
              ? _buildNoDataView(isDarkMode)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection(isDarkMode),
                      const SizedBox(height: 24),
                      if (isSummaryLoading)
                        _buildLoadingSummary()
                      else ...[
                        _buildPeriodHeader(isDarkMode),
                        const SizedBox(height: 20),
                        _buildSummaryCards(isDarkMode),
                        const SizedBox(height: 24),
                        _buildDetailButton(isDarkMode),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildLoadingSummary() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNoDataView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data untuk periode ini',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 20,
                color: isDarkMode
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Periode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Tahun',
                  value: selectedYear,
                  items: availableYears,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedYear = value;
                        _updateAvailableMonths();
                      });
                      _loadSummary();
                    }
                  },
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Bulan',
                  value: selectedMonth,
                  items: availableMonths,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMonth = value;
                      });
                      _loadSummary();
                    }
                  },
                  isDarkMode: isDarkMode,
                  isMonth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
    required bool isDarkMode,
    bool isMonth = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.surfaceAltDark
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? AppColors.surfaceAltDark
                  : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              dropdownColor: isDarkMode
                  ? AppColors.surfaceAltDark
                  : AppColors.surfaceLight,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              items: items.map((int item) {
                return DropdownMenuItem<int>(
                  value: item,
                  child: Text(isMonth ? _getMonthName(item) : item.toString()),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }

  Widget _buildPeriodHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? AppColors.primaryGradientDark
            : AppColors.primaryGradientLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.overlayLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month,
              color: AppColors.overlayLight,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.overlayLight.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentSummary!.monthYear,
                  style: TextStyle(
                    fontSize: 22,
                    color: AppColors.overlayLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.overlayLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentSummary!.totalDays} Hari',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.overlayLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isDarkMode) {
    return Column(
      children: [
        // Masuk - Full width with horizontal layout
        _buildWideCard(
          'Masuk',
          currentSummary!.masuk.toString(),
          Icons.check_circle,
          AppColors.statusWork,
          isDarkMode,
        ),
        const SizedBox(height: 12),
        // Alpha | Izin
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Alpha',
                currentSummary!.alpha.toString(),
                Icons.cancel,
                AppColors.statusAbsent,
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Izin',
                currentSummary!.izin.toString(),
                Icons.event_note,
                AppColors.statusLeave,
                isDarkMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sakit | Cuti
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Sakit',
                currentSummary!.sakit.toString(),
                Icons.local_hospital,
                AppColors.statusLate,
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Cuti',
                currentSummary!.cuti.toString(),
                Icons.beach_access,
                isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlayDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 36,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            SlideRightRoute(
              page: AttendanceDetailPage(
                month: selectedMonth,
                year: selectedYear,
                monthYear: currentSummary!.monthYear,
                summary: currentSummary!,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode
              ? AppColors.primaryDark
              : AppColors.primaryLight,
          foregroundColor: AppColors.overlayLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.table_chart, size: 20),
            SizedBox(width: 8),
            Text(
              'Lihat Detail Check Clock',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

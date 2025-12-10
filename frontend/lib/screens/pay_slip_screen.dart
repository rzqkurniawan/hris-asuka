import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/pay_slip_model.dart';
import '../services/pay_slip_service.dart';

class PaySlipScreen extends StatefulWidget {
  const PaySlipScreen({super.key});

  @override
  State<PaySlipScreen> createState() => _PaySlipScreenState();
}

class _PaySlipScreenState extends State<PaySlipScreen> {
  final PaySlipService _paySlipService = PaySlipService();

  String? selectedPeriod;
  String? selectedMonth;
  String? selectedYear;
  bool showSlip = false;
  bool isLoadingPeriods = true;
  bool isLoadingDetail = false;

  List<String> periods = ['1 - 15', '16 - 31', '1 - 31'];
  List<String> months = [];
  List<String> years = [];

  PaySlipDetail? paySlipDetail;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailablePeriods();
  }

  Future<void> _loadAvailablePeriods() async {
    setState(() {
      isLoadingPeriods = true;
      errorMessage = null;
    });

    try {
      final periodsResponse = await _paySlipService.getAvailablePeriods();

      setState(() {
        years = periodsResponse.availableYears;
        months = periodsResponse.availableMonths.isNotEmpty
            ? periodsResponse.availableMonths
            : [
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December'
              ];
        isLoadingPeriods = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPeriods = false;
        errorMessage = e.toString();
        // Fallback to default values
        years = ['2023', '2024', '2025', '2026'];
        months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
      });
    }
  }

  Future<void> _loadPaySlipDetail() async {
    if (selectedMonth == null || selectedYear == null || selectedPeriod == null) {
      return;
    }

    setState(() {
      isLoadingDetail = true;
      errorMessage = null;
      showSlip = false;
    });

    try {
      final detail = await _paySlipService.getPaySlipDetail(
        month: selectedMonth!,
        year: selectedYear!,
        period: selectedPeriod!,
      );

      setState(() {
        paySlipDetail = detail;
        isLoadingDetail = false;
        showSlip = true;
      });
    } catch (e) {
      setState(() {
        isLoadingDetail = false;
        paySlipDetail = null;
        showSlip = true;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pay Slip'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoadingPeriods
          ? _buildLoadingView(isDarkMode)
          : (showSlip
              ? (paySlipDetail != null
                  ? _buildPaySlipView(isDarkMode)
                  : _buildNotFoundView(isDarkMode))
              : _buildFormView(isDarkMode)),
    );
  }

  Widget _buildLoadingView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading available periods...',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Select Pay Period',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the period to view your salary slip',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),

          // Year Dropdown
          _buildDropdown(
            label: 'Year',
            hint: 'Select year',
            value: selectedYear,
            items: years,
            onChanged: (value) {
              setState(() => selectedYear = value);
              HapticFeedback.lightImpact();
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),

          // Month Dropdown
          _buildDropdown(
            label: 'Month',
            hint: 'Select month',
            value: selectedMonth,
            items: months,
            onChanged: (value) {
              setState(() => selectedMonth = value);
              HapticFeedback.lightImpact();
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),

          // Pay Period Dropdown
          _buildDropdown(
            label: 'Pay Period',
            hint: 'Select period',
            value: selectedPeriod,
            items: periods,
            onChanged: (value) {
              setState(() => selectedPeriod = value);
              HapticFeedback.lightImpact();
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 40),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_canSubmit() && !isLoadingDetail)
                  ? () {
                      HapticFeedback.mediumImpact();
                      _loadPaySlipDetail();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                disabledBackgroundColor: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoadingDetail
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'View Pay Slip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _canSubmit()
                            ? Colors.white
                            : (isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDarkMode ? AppColors.surfaceAltDark : AppColors.mutedLight,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: TextStyle(
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              dropdownColor:
                  isDarkMode ? AppColors.surfaceAltDark : Colors.white,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return selectedPeriod != null &&
        selectedMonth != null &&
        selectedYear != null;
  }

  Widget _buildPaySlipView(bool isDarkMode) {
    if (paySlipDetail == null) return _buildNotFoundView(isDarkMode);

    final detail = paySlipDetail!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period: ${detail.period}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        detail.monthYear,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => showSlip = false);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change Period'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    side: BorderSide(
                      color: isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pay Slip Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSlipHeader(isDarkMode, detail),
                  _buildDivider(isDarkMode),
                  _buildEmployeeInfo(isDarkMode, detail),
                  _buildDivider(isDarkMode),
                  _buildEarnings(isDarkMode, detail),
                  _buildDivider(isDarkMode),
                  _buildDeductions(isDarkMode, detail),
                  _buildDivider(isDarkMode),
                  _buildNetPay(isDarkMode, detail),
                  _buildDivider(isDarkMode),
                  _buildSignature(isDarkMode, detail),
                ],
              ),
            ),
          ),

          // Download Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showDownloadDialog(isDarkMode);
                },
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlipHeader(bool isDarkMode, PaySlipDetail detail) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'SLIP GAJI KARYAWAN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bulan: ${detail.monthYear}',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo(bool isDarkMode, PaySlipDetail detail) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInfoRow('Nama', detail.employeeInfo.name, isDarkMode),
          const SizedBox(height: 12),
          _buildInfoRow('Emp ID', detail.employeeInfo.employeeNumber, isDarkMode),
          const SizedBox(height: 12),
          _buildInfoRow('Grade', detail.employeeInfo.grade, isDarkMode),
          const SizedBox(height: 12),
          _buildInfoRow('Jabatan', detail.employeeInfo.position, isDarkMode),
          const SizedBox(height: 12),
          _buildInfoRow('Department', detail.employeeInfo.department, isDarkMode),
          const SizedBox(height: 12),
          _buildInfoRow('Lokasi Kerja', detail.employeeInfo.workLocation, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildEarnings(bool isDarkMode, PaySlipDetail detail) {
    final earnings = detail.earnings;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          if (earnings['basic_salary']! > 0)
            _buildAmountRow('Gaji Pokok', detail.formatCurrency(earnings['basic_salary']!), isDarkMode),
          if (earnings['meal_allowance']! > 0)
            _buildAmountRow('Meal', detail.formatCurrency(earnings['meal_allowance']!), isDarkMode),
          if (earnings['transport_allowance']! > 0)
            _buildAmountRow('Transport', detail.formatCurrency(earnings['transport_allowance']!), isDarkMode),
          if (earnings['welfare_allowance']! > 0)
            _buildAmountRow('Welfare', detail.formatCurrency(earnings['welfare_allowance']!), isDarkMode),
          if (earnings['overtime']! > 0)
            _buildAmountRow('Lembur', detail.formatCurrency(earnings['overtime']!), isDarkMode, highlight: true),
          if (earnings['overtime_meal']! > 0)
            _buildAmountRow('Meal Lembur', detail.formatCurrency(earnings['overtime_meal']!), isDarkMode),
          if (earnings['jamsostek_allowance']! > 0)
            _buildAmountRow('Tunj. Jamsostek', detail.formatCurrency(earnings['jamsostek_allowance']!), isDarkMode),
          if (earnings['bpjs_allowance']! > 0)
            _buildAmountRow('Tunj. BPJS', detail.formatCurrency(earnings['bpjs_allowance']!), isDarkMode),
          if (earnings['emergency_call']! > 0)
            _buildAmountRow('Emergency Call', detail.formatCurrency(earnings['emergency_call']!), isDarkMode),
          if (earnings['additional_allowance']! > 0)
            _buildAmountRow('Tunjangan Lainnya', detail.formatCurrency(earnings['additional_allowance']!), isDarkMode),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primaryDark.withOpacity(0.1)
                  : AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pendapatan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  detail.formatCurrency(detail.totalEarnings),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductions(bool isDarkMode, PaySlipDetail detail) {
    final deductions = detail.deductions;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Potongan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          if (deductions['jamsostek_paid']! > 0)
            _buildAmountRow('BPJS Ketenagakerjaan', detail.formatCurrency(deductions['jamsostek_paid']!), isDarkMode),
          if (deductions['bpjs_paid']! > 0)
            _buildAmountRow('BPJS Kesehatan', detail.formatCurrency(deductions['bpjs_paid']!), isDarkMode),
          if (deductions['jht']! > 0)
            _buildAmountRow('JHT', detail.formatCurrency(deductions['jht']!), isDarkMode),
          if (deductions['jaminan_pensiun']! > 0)
            _buildAmountRow('JP', detail.formatCurrency(deductions['jaminan_pensiun']!), isDarkMode),
          if (deductions['bpjs']! > 0)
            _buildAmountRow('JKN', detail.formatCurrency(deductions['bpjs']!), isDarkMode),
          if (deductions['pph1']! > 0 || deductions['pph2']! > 0)
            _buildAmountRow('Income Tax', detail.formatCurrency(deductions['pph1']! + deductions['pph2']!), isDarkMode),
          if (deductions['late_deduction']! > 0)
            _buildAmountRow('Pot. Terlambat', detail.formatCurrency(deductions['late_deduction']!), isDarkMode),
          if (deductions['deduction_k3_amount']! > 0)
            _buildAmountRow('Investasi Jaminan Kerja', detail.formatCurrency(deductions['deduction_k3_amount']!), isDarkMode),
          if (deductions['cooperative']! > 0)
            _buildAmountRow('Pot. Koperasi', detail.formatCurrency(deductions['cooperative']!), isDarkMode),
          if (deductions['loan_cooperative']! > 0)
            _buildAmountRow('Pinjaman Koperasi', detail.formatCurrency(deductions['loan_cooperative']!), isDarkMode),
          if (deductions['moneybox']! > 0)
            _buildAmountRow('Celengan', detail.formatCurrency(deductions['moneybox']!), isDarkMode),
          if (deductions['other_deduction']! > 0)
            _buildAmountRow('Potongan Lainnya', detail.formatCurrency(deductions['other_deduction']!), isDarkMode),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.red.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Potongan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  detail.formatCurrency(detail.totalDeductions),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetPay(bool isDarkMode, PaySlipDetail detail) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [AppColors.primaryDark, AppColors.secondaryDark]
              : [const Color(0xFF082f49), const Color(0xFF0c4a6e)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gaji Bersih',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                detail.formatCurrency(detail.netPay),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'TAKE HOME PAY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detail.formatCurrency(detail.takeHomePay),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (detail.totalSavings > 0) ...[
            const SizedBox(height: 8),
            Text(
              '*Total Simpanan Jaminan Kerja: ${detail.formatCurrency(detail.totalSavings)}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignature(bool isDarkMode, PaySlipDetail detail) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dicetak pada:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? AppColors.surfaceAltDark
                    : AppColors.mutedLight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Receipt by,',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  detail.employeeInfo.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.employeeInfo.position,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, String amount, bool isDarkMode,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: highlight
                  ? (isDarkMode
                      ? AppColors.primaryDark
                      : AppColors.primaryLight)
                  : (isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDarkMode
          ? AppColors.surfaceAltDark
          : AppColors.mutedLight.withOpacity(0.3),
    );
  }

  Widget _buildNotFoundView(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.dangerDark.withOpacity(0.2)
                        : AppColors.dangerLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: isDarkMode
                        ? AppColors.dangerDark
                        : AppColors.dangerLight,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pay Slip Not Found',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.dangerDark
                        : AppColors.dangerLight,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pay slip untuk periode yang dipilih tidak tersedia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Period: ${selectedPeriod ?? "-"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedMonth ?? "-"} ${selectedYear ?? "-"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => showSlip = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? AppColors.dangerDark
                          : AppColors.dangerLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Change Period',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.surfaceAltDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.primaryDark.withOpacity(0.2)
                    : AppColors.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color:
                    isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Download Success',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          'Pay slip telah berhasil diunduh ke folder Downloads.',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: TextStyle(
                color:
                    isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

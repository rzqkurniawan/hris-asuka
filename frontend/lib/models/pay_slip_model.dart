class PaySlipPeriod {
  final String monthYear;
  final String month;
  final String year;
  final String period;

  PaySlipPeriod({
    required this.monthYear,
    required this.month,
    required this.year,
    required this.period,
  });

  factory PaySlipPeriod.fromJson(Map<String, dynamic> json) {
    return PaySlipPeriod(
      monthYear: json['month_year'] as String,
      month: json['month'] as String,
      year: json['year'] as String,
      period: json['period'] as String? ?? '1 - 31',
    );
  }
}

class EmployeeInfo {
  final String name;
  final String employeeNumber;
  final String grade;
  final String position;
  final String department;
  final String workLocation;
  final String employeeStatus;
  final String npwp;
  final String accountNumber;

  EmployeeInfo({
    required this.name,
    required this.employeeNumber,
    required this.grade,
    required this.position,
    required this.department,
    required this.workLocation,
    required this.employeeStatus,
    required this.npwp,
    required this.accountNumber,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      name: json['name'] as String? ?? '-',
      employeeNumber: json['employee_number'] as String? ?? '-',
      grade: json['grade'] as String? ?? '-',
      position: json['position'] as String? ?? '-',
      department: json['department'] as String? ?? '-',
      workLocation: json['work_location'] as String? ?? '-',
      employeeStatus: json['employee_status'] as String? ?? '-',
      npwp: json['npwp'] as String? ?? '-',
      accountNumber: json['account_number'] as String? ?? '-',
    );
  }
}

class PaySlipDetail {
  final String period;
  final String month;
  final String year;
  final String monthYear;
  final EmployeeInfo employeeInfo;
  final Map<String, double> earnings;
  final double totalEarnings;
  final Map<String, double> deductions;
  final double totalDeductions;
  final double netPay;
  final double takeHomePay;
  final double totalSavings;
  final String? createdDate;

  PaySlipDetail({
    required this.period,
    required this.month,
    required this.year,
    required this.monthYear,
    required this.employeeInfo,
    required this.earnings,
    required this.totalEarnings,
    required this.deductions,
    required this.totalDeductions,
    required this.netPay,
    required this.takeHomePay,
    required this.totalSavings,
    this.createdDate,
  });

  factory PaySlipDetail.fromJson(Map<String, dynamic> json) {
    final earningsJson = json['earnings'] as Map<String, dynamic>;
    final deductionsJson = json['deductions'] as Map<String, dynamic>;

    // Convert earnings to Map<String, double>
    final earnings = earningsJson.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    // Convert deductions to Map<String, double>
    final deductions = deductionsJson.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return PaySlipDetail(
      period: json['period'] as String,
      month: json['month'] as String,
      year: json['year'] as String,
      monthYear: json['month_year'] as String,
      employeeInfo: EmployeeInfo.fromJson(json['employee_info'] as Map<String, dynamic>),
      earnings: earnings,
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      deductions: deductions,
      totalDeductions: (json['total_deductions'] as num).toDouble(),
      netPay: (json['net_pay'] as num).toDouble(),
      takeHomePay: (json['take_home_pay'] as num).toDouble(),
      totalSavings: (json['total_savings'] as num).toDouble(),
      createdDate: json['created_date'] as String?,
    );
  }

  // Helper to format currency
  String formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  // Get specific earning by key
  double getEarning(String key) {
    return earnings[key] ?? 0;
  }

  // Get specific deduction by key
  double getDeduction(String key) {
    return deductions[key] ?? 0;
  }
}

class AvailablePeriodsResponse {
  final List<PaySlipPeriod> periods;
  final List<String> availableYears;
  final List<String> availableMonths;

  AvailablePeriodsResponse({
    required this.periods,
    required this.availableYears,
    required this.availableMonths,
  });

  factory AvailablePeriodsResponse.fromJson(Map<String, dynamic> json) {
    final periodsJson = json['periods'] as List<dynamic>;
    final periods = periodsJson
        .map((p) => PaySlipPeriod.fromJson(p as Map<String, dynamic>))
        .toList();

    final yearsJson = json['available_years'] as List<dynamic>;
    final availableYears = yearsJson.map((y) => y.toString()).toList();

    final monthsJson = json['available_months'] as List<dynamic>;
    final availableMonths = monthsJson.map((m) => m.toString()).toList();

    return AvailablePeriodsResponse(
      periods: periods,
      availableYears: availableYears,
      availableMonths: availableMonths,
    );
  }
}

import 'employee.dart';

class EmployeeOvertimeDetail {
  final String employeeId;
  final String employeeName;
  final String position;
  final String initials;
  final String? employeeFileName;
  final DateTime overtimeDate;
  final String startTime;
  final String finishTime;
  final String remarks;

  EmployeeOvertimeDetail({
    required this.employeeId,
    required this.employeeName,
    required this.position,
    required this.initials,
    this.employeeFileName,
    required this.overtimeDate,
    required this.startTime,
    required this.finishTime,
    required this.remarks,
  });

  // Factory constructor for creating EmployeeOvertimeDetail from API JSON
  factory EmployeeOvertimeDetail.fromJson(Map<String, dynamic> json) {
    return EmployeeOvertimeDetail(
      employeeId: json['employee_id'] as String? ?? '-',
      employeeName: json['employee_name'] as String? ?? '-',
      position: json['position'] as String? ?? '-',
      initials: json['initials'] as String? ?? '-',
      employeeFileName: json['employee_file_name'] as String?,
      overtimeDate: _parseDate(json['overtime_date']),
      startTime: json['start_time'] as String? ?? '-',
      finishTime: json['finish_time'] as String? ?? '-',
      remarks: json['remarks'] as String? ?? '-',
    );
  }

  // Convert EmployeeOvertimeDetail to JSON
  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'position': position,
      'initials': initials,
      'employee_file_name': employeeFileName,
      'overtime_date': overtimeDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'finish_time': finishTime,
      'remarks': remarks,
      'duration_hours': durationHours,
    };
  }

  // Helper to parse date string
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      final parsed = _parseFlexibleDate(value.trim());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static DateTime? _parseFlexibleDate(String value) {
    try {
      return DateTime.parse(
        value.contains('T') ? value : value.replaceFirst(' ', 'T'),
      );
    } catch (_) {
      final normalized = value.replaceAll('/', '-');
      final parts = normalized.split(' ');
      final datePart = parts.first;
      final timePart =
          parts.length > 1 ? parts.sublist(1).join(' ').trim() : null;
      final dateSegments = datePart.split('-');

      if (dateSegments.length == 3 &&
          dateSegments[0].length <= 2 &&
          dateSegments[2].length == 4) {
        final day = dateSegments[0].padLeft(2, '0');
        final month = dateSegments[1].padLeft(2, '0');
        final year = dateSegments[2];
        var isoString = '$year-$month-$day';
        if (timePart != null && timePart.isNotEmpty) {
          isoString = '$isoString ${timePart.replaceAll('.', ':')}';
        }

        try {
          return DateTime.parse(
            isoString.contains(' ')
                ? isoString.replaceFirst(' ', 'T')
                : isoString,
          );
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  // Calculate duration in hours
  int get durationHours {
    final start = _parseTime(startTime);
    final finish = _parseTime(finishTime);
    return finish.difference(start).inHours;
  }

  // Helper to parse time string "HH:MM" to DateTime
  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(2024, 1, 1, hour, minute);
  }

  // Sample data mapped to overtime orders
  static Map<String, List<EmployeeOvertimeDetail>>
      getSampleEmployeeOvertimes() {
    final employeeMap = {
      for (final employee in Employee.getSampleEmployees())
        employee.id: employee,
    };

    EmployeeOvertimeDetail createDetail(
      String employeeId, {
      required DateTime date,
      required String position,
      required String start,
      required String finish,
      required String remarks,
    }) {
      final employee = employeeMap[employeeId]!;
      return EmployeeOvertimeDetail(
        employeeId: employee.id,
        employeeName: employee.name,
        position: position,
        initials: employee.initials,
        overtimeDate: date,
        startTime: start,
        finishTime: finish,
        remarks: remarks,
      );
    }

    return {
      'OT-2024-001': [
        createDetail(
          'K01122',
          date: DateTime(2024, 11, 10),
          position: 'Mobile Developer',
          start: '18:00',
          finish: '22:30',
          remarks:
              'Leading mobile deployment validation and push notification smoke tests for the release candidate.\n\nSpecial requirements:\n• Production monitoring dashboard access\n• Device lab reservation\n• Release checklist updated',
        ),
        createDetail(
          'K02024',
          date: DateTime(2024, 11, 10),
          position: 'Lead Backend Engineer',
          start: '18:00',
          finish: '22:00',
          remarks:
              'Securing API rollout and coordinating database migration fallbacks with infrastructure team.\n\nSpecial requirements:\n• API gateway credentials\n• Rollback playbook printed\n• Slack war-room channel active',
        ),
        createDetail(
          'P00965',
          date: DateTime(2024, 11, 10),
          position: 'IT Supervisor',
          start: '17:30',
          finish: '23:00',
          remarks:
              'Monitoring server health metrics and validating failover scenarios during migration window.\n\nSpecial requirements:\n• SSH access to core servers\n• Incident bridge open\n• Backup generator checklist ready',
        ),
        createDetail(
          'K02506',
          date: DateTime(2024, 11, 10),
          position: 'QA Analyst',
          start: '18:30',
          finish: '22:30',
          remarks:
              'Executing regression packs focused on payment flow, attendance sync, and background sync scenarios.\n\nSpecial requirements:\n• Latest regression suite\n• TestRail access\n• Defect triage board prepared',
        ),
      ],
      'OT-2024-002': [
        createDetail(
          'K01122',
          date: DateTime(2024, 11, 12),
          position: 'Mobile Developer',
          start: '19:30',
          finish: '23:30',
          remarks:
              'Configuring handheld scanners integration tests and validating telemetry for conveyor systems.',
        ),
        createDetail(
          'K01107',
          date: DateTime(2024, 11, 12),
          position: 'Operations Supervisor',
          start: '18:30',
          finish: '23:00',
          remarks:
              'Coordinating plant shutdown checklist, safety briefing, and supplier notification for maintenance.',
        ),
        createDetail(
          'T9925',
          date: DateTime(2024, 11, 12),
          position: 'Logistics Coordinator',
          start: '19:00',
          finish: '22:30',
          remarks:
              'Updating outbound routing plans and ensuring alternative lanes for Monday shipments.',
        ),
        createDetail(
          'T10799',
          date: DateTime(2024, 11, 12),
          position: 'Inventory Specialist',
          start: '19:00',
          finish: '22:00',
          remarks:
              'Recalibrating weight sensors and validating stock variance after conveyor maintenance.',
        ),
      ],
      'OT-2024-003': [
        createDetail(
          'K01122',
          date: DateTime(2024, 11, 15),
          position: 'Mobile Developer',
          start: '20:00',
          finish: '01:00',
          remarks:
              'Maintaining finance dashboard availability and verifying nightly settlement push notifications.',
        ),
        createDetail(
          'K02109',
          date: DateTime(2024, 11, 15),
          position: 'Finance Controller',
          start: '19:30',
          finish: '00:30',
          remarks:
              'Performing consolidation reconciliations and reviewing cross-entity journal adjustments.',
        ),
        createDetail(
          'K04459',
          date: DateTime(2024, 11, 15),
          position: 'Tax Analyst',
          start: '20:00',
          finish: '23:30',
          remarks:
              'Reviewing VAT input/output variance and aligning supporting documents for audit trail.',
        ),
        createDetail(
          'K02423',
          date: DateTime(2024, 11, 15),
          position: 'Budget Officer',
          start: '20:00',
          finish: '23:00',
          remarks:
              'Updating budget tracking spreadsheets and issuing variance commentary for management.',
        ),
      ],
      'OT-2024-004': [
        createDetail(
          'K01122',
          date: DateTime(2024, 11, 18),
          position: 'Mobile Developer',
          start: '17:30',
          finish: '22:30',
          remarks:
              'Ensuring live-chat mobile widgets remain responsive and monitoring crash analytics during migration.',
        ),
        createDetail(
          'K01762',
          date: DateTime(2024, 11, 18),
          position: 'Customer Care Lead',
          start: '17:00',
          finish: '22:00',
          remarks:
              'Managing escalation routing and coordinating with field teams for premium client issues.',
        ),
        createDetail(
          'K01961',
          date: DateTime(2024, 11, 18),
          position: 'Service Quality Analyst',
          start: '17:00',
          finish: '21:30',
          remarks:
              'Auditing ticket transcripts, tagging incident patterns, and updating knowledge base articles.',
        ),
        createDetail(
          'K02863',
          date: DateTime(2024, 11, 18),
          position: 'Field Support Technician',
          start: '17:00',
          finish: '22:00',
          remarks:
              'Coordinating with on-site engineers for device swap requests and confirming SLA restoration.',
        ),
      ],
      'OT-2024-005': [
        createDetail(
          'K01122',
          date: DateTime(2024, 11, 20),
          position: 'Mobile Developer',
          start: '18:00',
          finish: '22:00',
          remarks:
              'Supporting warehouse application hotfix and ensuring device sync after inventory recount.',
        ),
        createDetail(
          'P00469',
          date: DateTime(2024, 11, 20),
          position: 'Warehouse Manager',
          start: '17:30',
          finish: '22:00',
          remarks:
              'Supervising cycle count execution and reviewing variance dashboard before export deadline.',
        ),
        createDetail(
          'P00469',
          date: DateTime(2024, 11, 20),
          position: 'Procurement Officer',
          start: '18:00',
          finish: '21:30',
          remarks:
              'Coordinating urgent supplier pickups and confirming replacement parts for conveyor maintenance.',
        ),
        createDetail(
          'T10799',
          date: DateTime(2024, 11, 20),
          position: 'Inventory Specialist',
          start: '18:00',
          finish: '21:30',
          remarks:
              'Reconciling physical counts with WMS data and updating discrepancy reports for morning briefing.',
        ),
      ],
    };
  }

  // Get employees for specific order
  static List<EmployeeOvertimeDetail> getEmployeesForOrder(String orderNumber) {
    final allData = getSampleEmployeeOvertimes();
    return allData[orderNumber] ?? [];
  }
}

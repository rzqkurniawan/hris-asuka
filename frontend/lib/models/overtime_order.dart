class OvertimeOrder {
  final int? id; // overtime_workorder_id from database
  final String orderNumber;
  final String jobCode;
  final String workLocation;
  final String department;
  final String workDescription;
  final DateTime proposedDate;
  final String requestedBy;
  final bool isApproved;
  final String? approval1Name;
  final DateTime? approval1Date;
  final String? approval2Name;
  final DateTime? approval2Date;
  final bool approval2Approved;
  final String? verifiedBy;
  final DateTime? verifiedDate;
  final List<int> employeeIds;

  const OvertimeOrder({
    this.id,
    required this.orderNumber,
    required this.jobCode,
    required this.workLocation,
    required this.department,
    required this.workDescription,
    required this.proposedDate,
    required this.requestedBy,
    required this.isApproved,
    this.approval1Name,
    this.approval1Date,
    this.approval2Name,
    this.approval2Date,
    required this.approval2Approved,
    this.verifiedBy,
    this.verifiedDate,
    required this.employeeIds,
  });

  factory OvertimeOrder.fromJson(Map<String, dynamic> json) {
    return OvertimeOrder(
      id: json['id'] as int?,
      orderNumber: json['order_number'] as String? ?? '-',
      jobCode: json['job_code'] as String? ?? '-',
      workLocation: json['work_location'] as String? ?? '-',
      department: json['department'] as String? ?? '-',
      workDescription: json['work_description'] as String? ?? '-',
      proposedDate: _parseDate(json['proposed_date']),
      requestedBy: json['requested_by'] as String? ?? '-',
      isApproved: json['is_approved'] as bool? ?? false,
      approval1Name: json['approval1_name'] as String?,
      approval1Date: _parseDateTime(json['approval1_date']),
      approval2Name: json['approval2_name'] as String?,
      approval2Date: _parseDateTime(json['approval2_date']),
      approval2Approved: json['approval2_approved'] as bool? ?? false,
      verifiedBy: json['verified_by'] as String?,
      verifiedDate: _parseDateTime(json['verified_date']),
      employeeIds: (json['employee_ids'] as List<dynamic>?)
              ?.map((value) {
                if (value is int) return value;
                return int.tryParse(value.toString());
              })
              .whereType<int>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'job_code': jobCode,
      'work_location': workLocation,
      'department': department,
      'work_description': workDescription,
      'proposed_date': proposedDate.toIso8601String().split('T')[0],
      'requested_by': requestedBy,
      'is_approved': isApproved,
      'approval1_name': approval1Name,
      'approval1_date': approval1Date?.toIso8601String(),
      'approval2_name': approval2Name,
      'approval2_date': approval2Date?.toIso8601String(),
      'approval2_approved': approval2Approved,
      'verified_by': verifiedBy,
      'verified_date': verifiedDate?.toIso8601String(),
      'employee_ids': employeeIds,
      'employee_count': employeeCount,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      final parsed = _parseFlexibleDate(value.trim());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return _parseFlexibleDate(value.trim());
    }
    return null;
  }

  static DateTime? _parseFlexibleDate(String value) {
    try {
      return DateTime.parse(value.contains('T')
          ? value
          : value.replaceFirst(' ', 'T'));
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
            isoString.contains(' ') ? isoString.replaceFirst(' ', 'T') : isoString,
          );
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  bool get isPending =>
      !isApproved && (approval1Date == null || approval2Date == null);

  bool get isRejected => !isApproved && !isPending;

  String get statusText {
    if (isApproved) return 'APPROVED';
    if (isRejected) return 'REJECTED';
    return 'PENDING';
  }

  int get employeeCount => employeeIds.length;
}

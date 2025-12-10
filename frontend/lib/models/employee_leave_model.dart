class LeaveCategory {
  final int leaveCategoryId;
  final String leaveCategoryName;
  final int unit;
  final String reportSymbol;

  LeaveCategory({
    required this.leaveCategoryId,
    required this.leaveCategoryName,
    required this.unit,
    required this.reportSymbol,
  });

  factory LeaveCategory.fromJson(Map<String, dynamic> json) {
    return LeaveCategory(
      leaveCategoryId: json['leave_category_id'] as int,
      leaveCategoryName: json['leave_category_name'] as String,
      unit: json['unit'] as int,
      reportSymbol: json['report_symbol'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_category_id': leaveCategoryId,
      'leave_category_name': leaveCategoryName,
      'unit': unit,
      'report_symbol': reportSymbol,
    };
  }
}

class Employee {
  final int employeeId;
  final String employeeNumber;
  final String fullname;
  final String? employeeFileName;

  Employee({
    required this.employeeId,
    required this.employeeNumber,
    required this.fullname,
    this.employeeFileName,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employee_id'] as int,
      employeeNumber: json['employee_number'] as String,
      fullname: json['fullname'] as String,
      employeeFileName: json['employee_file_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_number': employeeNumber,
      'fullname': fullname,
      'employee_file_name': employeeFileName,
    };
  }

  // Helper to get initials from fullname
  String get initials {
    if (fullname.isEmpty) return '?';
    final parts = fullname.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

class EmployeeLeave {
  final int employeeLeaveId;
  final String employeeLeaveNumber;
  final int leaveCategoryId;
  final String leaveCategoryName;
  final String reportSymbol;
  final DateTime? dateBegin;
  final DateTime? dateEnd;
  final String dateBeginFormatted;
  final String dateEndFormatted;
  final int durationDays;
  final String notes;
  final String? addressLeave;
  final String? phoneLeave;
  final Employee? substituteEmployee;
  final bool isApproved;
  final DateTime? approvedDate;
  final String status;
  final int sisaCuti;
  final DateTime? createdDate;

  EmployeeLeave({
    required this.employeeLeaveId,
    required this.employeeLeaveNumber,
    required this.leaveCategoryId,
    required this.leaveCategoryName,
    required this.reportSymbol,
    this.dateBegin,
    this.dateEnd,
    required this.dateBeginFormatted,
    required this.dateEndFormatted,
    required this.durationDays,
    required this.notes,
    this.addressLeave,
    this.phoneLeave,
    this.substituteEmployee,
    required this.isApproved,
    this.approvedDate,
    required this.status,
    required this.sisaCuti,
    this.createdDate,
  });

  factory EmployeeLeave.fromJson(Map<String, dynamic> json) {
    return EmployeeLeave(
      employeeLeaveId: json['employee_leave_id'] as int,
      employeeLeaveNumber: json['employee_leave_number'] as String? ?? '',
      leaveCategoryId: json['leave_category_id'] as int,
      leaveCategoryName: json['leave_category_name'] as String,
      reportSymbol: json['report_symbol'] as String? ?? '-',
      dateBegin: json['date_begin'] != null
          ? DateTime.tryParse(json['date_begin'] as String)
          : null,
      dateEnd: json['date_end'] != null
          ? DateTime.tryParse(json['date_end'] as String)
          : null,
      dateBeginFormatted: json['date_begin_formatted'] as String? ?? '-',
      dateEndFormatted: json['date_end_formatted'] as String? ?? '-',
      durationDays: json['duration_days'] as int,
      notes: json['notes'] as String? ?? '-',
      addressLeave: json['address_leave'] as String?,
      phoneLeave: json['phone_leave'] as String?,
      substituteEmployee: json['substitute_employee'] != null
          ? Employee.fromJson(json['substitute_employee'] as Map<String, dynamic>)
          : null,
      isApproved: json['is_approved'] as bool? ?? false,
      approvedDate: json['approved_date'] != null
          ? DateTime.parse(json['approved_date'] as String)
          : null,
      status: json['status'] as String,
      sisaCuti: json['sisa_cuti'] as int? ?? 0,
      createdDate: json['created_date'] != null
          ? DateTime.parse(json['created_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_leave_id': employeeLeaveId,
      'employee_leave_number': employeeLeaveNumber,
      'leave_category_id': leaveCategoryId,
      'leave_category_name': leaveCategoryName,
      'report_symbol': reportSymbol,
      'date_begin': dateBegin?.toIso8601String().split('T')[0],
      'date_end': dateEnd?.toIso8601String().split('T')[0],
      'date_begin_formatted': dateBeginFormatted,
      'date_end_formatted': dateEndFormatted,
      'duration_days': durationDays,
      'notes': notes,
      'address_leave': addressLeave,
      'phone_leave': phoneLeave,
      'substitute_employee': substituteEmployee?.toJson(),
      'is_approved': isApproved,
      'approved_date': approvedDate?.toIso8601String().split('T')[0],
      'status': status,
      'sisa_cuti': sisaCuti,
      'created_date': createdDate?.toIso8601String(),
    };
  }

  String get statusText {
    if (isApproved) return 'Disetujui';
    final lowered = status.toLowerCase();
    if (lowered.contains('reject') || lowered.contains('tolak')) {
      return 'Ditolak';
    }
    return 'Menunggu Persetujuan';
  }

  String get statusColor {
    if (isApproved) return 'green';
    final lowered = status.toLowerCase();
    if (lowered.contains('reject') || lowered.contains('tolak')) {
      return 'red';
    }
    return 'orange';
  }
}

class CreateLeaveRequest {
  final int leaveCategoryId;
  final int? substituteEmployeeId;
  final DateTime dateProposed;
  final DateTime dateBegin;
  final DateTime dateEnd;
  final DateTime dateWork;
  final String? notes;
  final String? addressLeave;
  final String? phoneLeave;

  CreateLeaveRequest({
    required this.leaveCategoryId,
    this.substituteEmployeeId,
    required this.dateProposed,
    required this.dateBegin,
    required this.dateEnd,
    required this.dateWork,
    this.notes,
    this.addressLeave,
    this.phoneLeave,
  });

  Map<String, dynamic> toJson() {
    return {
      'leave_category_id': leaveCategoryId,
      if (substituteEmployeeId != null)
        'substitute_employee_id': substituteEmployeeId,
      'date_proposed': dateProposed.toIso8601String().split('T')[0],
      'date_begin': dateBegin.toIso8601String().split('T')[0],
      'date_end': dateEnd.toIso8601String().split('T')[0],
      'date_work': dateWork.toIso8601String().split('T')[0],
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (addressLeave != null && addressLeave!.isNotEmpty)
        'address_leave': addressLeave,
      if (phoneLeave != null && phoneLeave!.isNotEmpty)
        'phone_leave': phoneLeave,
    };
  }
}

class UpdateLeaveRequest {
  final int? leaveCategoryId;
  final DateTime? dateBegin;
  final DateTime? dateEnd;
  final DateTime? dateWork;
  final String? notes;
  final String? addressLeave;
  final String? phoneLeave;

  UpdateLeaveRequest({
    this.leaveCategoryId,
    this.dateBegin,
    this.dateEnd,
    this.dateWork,
    this.notes,
    this.addressLeave,
    this.phoneLeave,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (leaveCategoryId != null) {
      map['leave_category_id'] = leaveCategoryId;
    }
    if (dateBegin != null) {
      map['date_begin'] = dateBegin!.toIso8601String().split('T')[0];
    }
    if (dateEnd != null) {
      map['date_end'] = dateEnd!.toIso8601String().split('T')[0];
    }
    if (dateWork != null) {
      map['date_work'] = dateWork!.toIso8601String().split('T')[0];
    }
    if (notes != null) {
      map['notes'] = notes;
    }
    if (addressLeave != null) {
      map['address_leave'] = addressLeave;
    }
    if (phoneLeave != null) {
      map['phone_leave'] = phoneLeave;
    }

    return map;
  }
}

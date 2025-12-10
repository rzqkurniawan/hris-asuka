class UserModel {
  final int id;
  final int employeeId;
  final String employeeNumber; // Badge ID (K01122, P00965, etc)
  final String username;
  final String fullname;
  final String position;
  final String workingPeriod;
  final String investmentAmount;
  final String? employeeFileName; // Photo filename from ki_employee table
  final String? identityFileName; // KTP filename from ki_employee table
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.employeeId,
    required this.employeeNumber,
    required this.username,
    required this.fullname,
    required this.position,
    required this.workingPeriod,
    required this.investmentAmount,
    this.employeeFileName,
    this.identityFileName,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      employeeId: json['employee_id'] as int? ?? 0,
      employeeNumber: (json['employee_number'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      fullname: (json['fullname'] ?? json['full_name'] ?? '') as String,
      position: (json['position'] ?? '') as String,
      workingPeriod: (json['working_period'] ?? '0Y 0M') as String,
      investmentAmount: (json['investment_amount'] ?? 'Rp 0') as String,
      employeeFileName: json['employee_file_name'] as String?,
      identityFileName: json['identity_file_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_number': employeeNumber,
      'username': username,
      'fullname': fullname,
      'position': position,
      'working_period': workingPeriod,
      'investment_amount': investmentAmount,
      'employee_file_name': employeeFileName,
      'identity_file_name': identityFileName,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get displayName => fullname.isNotEmpty ? fullname : username;

  String get initials {
    if (fullname.isNotEmpty) {
      // Split by space and filter out empty strings
      final names = fullname.trim().split(' ').where((name) => name.isNotEmpty).toList();

      if (names.isNotEmpty) {
        // Take first letter from each word and join them
        return names.map((name) => name[0]).join().toUpperCase();
      }

      // Fallback if split didn't work
      if (fullname.length >= 2) {
        return fullname.substring(0, 2).toUpperCase();
      }
      return fullname[0].toUpperCase();
    }

    // Fallback to username
    if (username.length >= 2) {
      return username.substring(0, 2).toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }
}

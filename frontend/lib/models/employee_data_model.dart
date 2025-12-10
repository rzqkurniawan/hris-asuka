class EmployeeDataModel {
  final PersonalData personalData;
  final EmploymentData employmentData;

  EmployeeDataModel({
    required this.personalData,
    required this.employmentData,
  });

  factory EmployeeDataModel.fromJson(Map<String, dynamic> json) {
    return EmployeeDataModel(
      personalData: PersonalData.fromJson(json['personal_data'] ?? {}),
      employmentData: EmploymentData.fromJson(json['employment_data'] ?? {}),
    );
  }
}

class PersonalData {
  final String fullname;
  final String nickname;
  final String gender;
  final String bloodType;
  final String placeDateBirth;
  final String religion;
  final String maritalStatus;
  final String address;
  final String nik;
  final String? identityFile;
  final String mobilePhone;
  final String email;
  final String npwp;
  final String bpjsHealth;
  final String bpjsEmployment;

  PersonalData({
    required this.fullname,
    required this.nickname,
    required this.gender,
    required this.bloodType,
    required this.placeDateBirth,
    required this.religion,
    required this.maritalStatus,
    required this.address,
    required this.nik,
    this.identityFile,
    required this.mobilePhone,
    required this.email,
    required this.npwp,
    required this.bpjsHealth,
    required this.bpjsEmployment,
  });

  factory PersonalData.fromJson(Map<String, dynamic> json) {
    return PersonalData(
      fullname: json['fullname'] as String? ?? '-',
      nickname: json['nickname'] as String? ?? '-',
      gender: json['gender'] as String? ?? '-',
      bloodType: json['blood_type'] as String? ?? '-',
      placeDateBirth: json['place_date_birth'] as String? ?? '-',
      religion: json['religion'] as String? ?? '-',
      maritalStatus: json['marital_status'] as String? ?? '-',
      address: json['address'] as String? ?? '-',
      nik: json['nik'] as String? ?? '-',
      identityFile: json['identity_file'] as String?,
      mobilePhone: json['mobile_phone'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      npwp: json['npwp'] as String? ?? '-',
      bpjsHealth: json['bpjs_health'] as String? ?? '-',
      bpjsEmployment: json['bpjs_employment'] as String? ?? '-',
    );
  }
}

class EmploymentData {
  final String employeeNumber;
  final String jobTitle;
  final String employeeGrade;
  final String department;
  final String jobOrder;
  final String workbase;
  final String employeeStatus;
  final String workingStatus;

  EmploymentData({
    required this.employeeNumber,
    required this.jobTitle,
    required this.employeeGrade,
    required this.department,
    required this.jobOrder,
    required this.workbase,
    required this.employeeStatus,
    required this.workingStatus,
  });

  factory EmploymentData.fromJson(Map<String, dynamic> json) {
    return EmploymentData(
      employeeNumber: json['employee_number'] as String? ?? '-',
      jobTitle: json['job_title'] as String? ?? '-',
      employeeGrade: json['employee_grade'] as String? ?? '-',
      department: json['department'] as String? ?? '-',
      jobOrder: json['job_order'] as String? ?? '-',
      workbase: json['workbase'] as String? ?? '-',
      employeeStatus: json['employee_status'] as String? ?? '-',
      workingStatus: json['working_status'] as String? ?? '-',
    );
  }
}

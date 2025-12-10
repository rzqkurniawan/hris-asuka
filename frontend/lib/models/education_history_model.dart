class EducationHistoryModel {
  final int educationCount;
  final List<EducationHistoryItem> educations;

  EducationHistoryModel({
    required this.educationCount,
    required this.educations,
  });

  factory EducationHistoryModel.fromJson(Map<String, dynamic> json) {
    return EducationHistoryModel(
      educationCount: json['education_count'] as int? ?? 0,
      educations: (json['educations'] as List<dynamic>?)
              ?.map((item) => EducationHistoryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EducationHistoryItem {
  final String education;
  final String schoolName;
  final String major;
  final int yearOfEntry;
  final int yearOfGraduation;

  EducationHistoryItem({
    required this.education,
    required this.schoolName,
    required this.major,
    required this.yearOfEntry,
    required this.yearOfGraduation,
  });

  factory EducationHistoryItem.fromJson(Map<String, dynamic> json) {
    return EducationHistoryItem(
      education: json['education'] as String? ?? '-',
      schoolName: json['school_name'] as String? ?? '-',
      major: json['major'] as String? ?? '',
      yearOfEntry: json['year_of_entry'] as int? ?? 0,
      yearOfGraduation: json['year_of_graduation'] as int? ?? 0,
    );
  }
}

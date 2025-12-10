class WorkExperienceModel {
  final int experienceCount;
  final List<WorkExperienceItem> experiences;

  WorkExperienceModel({
    required this.experienceCount,
    required this.experiences,
  });

  factory WorkExperienceModel.fromJson(Map<String, dynamic> json) {
    return WorkExperienceModel(
      experienceCount: json['experience_count'] as int? ?? 0,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((item) => WorkExperienceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkExperienceItem {
  final String company;
  final String position;
  final String startDate;
  final String endDate;

  WorkExperienceItem({
    required this.company,
    required this.position,
    required this.startDate,
    required this.endDate,
  });

  factory WorkExperienceItem.fromJson(Map<String, dynamic> json) {
    return WorkExperienceItem(
      company: json['company'] as String? ?? '-',
      position: json['position'] as String? ?? '-',
      startDate: json['start_date'] as String? ?? '-',
      endDate: json['end_date'] as String? ?? '-',
    );
  }
}

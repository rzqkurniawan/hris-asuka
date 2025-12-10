class FamilyDataModel {
  final int familyCount;
  final List<FamilyMember> families;

  FamilyDataModel({
    required this.familyCount,
    required this.families,
  });

  factory FamilyDataModel.fromJson(Map<String, dynamic> json) {
    return FamilyDataModel(
      familyCount: json['family_count'] as int? ?? 0,
      families: (json['families'] as List<dynamic>?)
              ?.map((item) => FamilyMember.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FamilyMember {
  final String name;
  final String relationship;
  final String birthDate;
  final String gender;
  final String education;
  final String job;

  FamilyMember({
    required this.name,
    required this.relationship,
    required this.birthDate,
    required this.gender,
    required this.education,
    required this.job,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      name: json['name'] as String? ?? '-',
      relationship: json['relationship'] as String? ?? '-',
      birthDate: json['birth_date'] as String? ?? '-',
      gender: json['gender'] as String? ?? '-',
      education: json['education'] as String? ?? '-',
      job: json['job'] as String? ?? '-',
    );
  }

  // Remove the static getSampleData method as we'll use real API data
}

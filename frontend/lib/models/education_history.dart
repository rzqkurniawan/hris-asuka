class EducationHistory {
  final String education;
  final String schoolName;
  final String major;
  final int yearOfEntry;
  final int yearOfGraduation;

  EducationHistory({
    required this.education,
    required this.schoolName,
    required this.major,
    required this.yearOfEntry,
    required this.yearOfGraduation,
  });

  static List<EducationHistory> getSampleData() {
    return [
      EducationHistory(
        education: 'SMK',
        schoolName: 'SMKN 1 Cerme',
        major: 'Teknik Komputer dan Jaringan',
        yearOfEntry: 2015,
        yearOfGraduation: 2018,
      ),
      EducationHistory(
        education: 'SMP',
        schoolName: 'SMPN 2 Gresik',
        major: '',
        yearOfEntry: 2012,
        yearOfGraduation: 2015,
      ),
      EducationHistory(
        education: 'SD',
        schoolName: 'SD Muhammadiyah 2 Gresik',
        major: '',
        yearOfEntry: 2006,
        yearOfGraduation: 2012,
      ),
    ];
  }
}

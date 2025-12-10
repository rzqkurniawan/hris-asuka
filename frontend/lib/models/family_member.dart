class FamilyMember {
  final String name;
  final String birthDate;
  final String relationship;
  final String gender;
  final String education;
  final String job;

  FamilyMember({
    required this.name,
    required this.birthDate,
    required this.relationship,
    required this.gender,
    required this.education,
    required this.job,
  });

  static List<FamilyMember> getSampleData() {
    return [
      FamilyMember(
        name: 'Achmad Santoso',
        birthDate: '13 Juli 1966',
        relationship: 'Bapak',
        gender: 'Laki - Laki',
        education: 'SMA',
        job: 'Karyawan Swasta',
      ),
      FamilyMember(
        name: 'Munimah Wati',
        birthDate: '22 Desember 1962',
        relationship: 'Ibu',
        gender: 'Perempuan',
        education: 'D4',
        job: 'Guru',
      ),
    ];
  }
}

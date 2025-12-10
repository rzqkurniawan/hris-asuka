class WorkExperience {
  final String startDate;
  final String endDate;
  final String company;
  final String position;

  WorkExperience({
    required this.startDate,
    required this.endDate,
    required this.company,
    required this.position,
  });

  static List<WorkExperience> getSampleData() {
    return [
      WorkExperience(
        startDate: '01-07-2019',
        endDate: 'Present',
        company: 'PT Asuka Indonesia',
        position: 'Mobile Developer',
      ),
      WorkExperience(
        startDate: '15-02-2018',
        endDate: '30-06-2019',
        company: 'PT Solusi Digital Indonesia',
        position: 'Junior Mobile Developer',
      ),
      WorkExperience(
        startDate: '10-08-2017',
        endDate: '10-02-2018',
        company: 'CV Kreatif Tech Solutions',
        position: 'Mobile App Intern',
      ),
    ];
  }
}

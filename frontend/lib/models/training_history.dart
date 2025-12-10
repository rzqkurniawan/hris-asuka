class TrainingHistory {
  final String name;
  final String place;
  final String provider;
  final String startDate;
  final String endDate;
  final int durationDays;
  final String evaluationDate;
  final String notes;

  TrainingHistory({
    required this.name,
    required this.place,
    required this.provider,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.evaluationDate,
    required this.notes,
  });

  static List<TrainingHistory> getSampleData() {
    return [
      TrainingHistory(
        name: 'Flutter Development Bootcamp',
        place: 'Jakarta Convention Center',
        provider: 'Google Developer Indonesia',
        startDate: '15-01-2024',
        endDate: '19-01-2024',
        durationDays: 5,
        evaluationDate: '26-01-2024',
        notes: 'Excellent performance, completed all practical assignments',
      ),
      TrainingHistory(
        name: 'Mobile UI/UX Design Principles',
        place: 'Online - Zoom',
        provider: 'Dicoding Indonesia',
        startDate: '10-03-2023',
        endDate: '12-03-2023',
        durationDays: 3,
        evaluationDate: '17-03-2023',
        notes: 'Successfully completed with certification',
      ),
      TrainingHistory(
        name: 'Git & GitHub for Teams',
        place: 'Surabaya Tech Hub',
        provider: 'Tech Academy',
        startDate: '05-08-2022',
        endDate: '06-08-2022',
        durationDays: 2,
        evaluationDate: '12-08-2022',
        notes: 'Good understanding of version control workflows',
      ),
      TrainingHistory(
        name: 'Agile Scrum Master Fundamentals',
        place: 'Bali IT Conference',
        provider: 'Scrum Alliance',
        startDate: '20-11-2021',
        endDate: '23-11-2021',
        durationDays: 4,
        evaluationDate: '30-11-2021',
        notes: 'Certified Scrum Master, demonstrated strong facilitation skills',
      ),
      TrainingHistory(
        name: 'Firebase Backend Integration',
        place: 'Online - Google Meet',
        provider: 'Firebase Indonesia Community',
        startDate: '14-05-2023',
        endDate: '16-05-2023',
        durationDays: 3,
        evaluationDate: '21-05-2023',
        notes: 'Implemented real-time database successfully',
      ),
    ];
  }
}

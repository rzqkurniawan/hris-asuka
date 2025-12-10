class TrainingHistoryModel {
  final int trainingCount;
  final List<TrainingHistory> trainings;

  TrainingHistoryModel({
    required this.trainingCount,
    required this.trainings,
  });

  factory TrainingHistoryModel.fromJson(Map<String, dynamic> json) {
    return TrainingHistoryModel(
      trainingCount: json['training_count'] as int? ?? 0,
      trainings: (json['trainings'] as List<dynamic>?)
              ?.map((item) => TrainingHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

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

  factory TrainingHistory.fromJson(Map<String, dynamic> json) {
    return TrainingHistory(
      name: json['name'] as String? ?? '-',
      place: json['place'] as String? ?? '-',
      provider: json['provider'] as String? ?? '-',
      startDate: json['start_date'] as String? ?? '-',
      endDate: json['end_date'] as String? ?? '-',
      durationDays: json['duration_days'] as int? ?? 0,
      evaluationDate: json['evaluation_date'] as String? ?? '-',
      notes: json['notes'] as String? ?? '-',
    );
  }
}

class PositionHistoryModel {
  final WorkHistory workHistory;
  final List<ContractHistory> contractHistory;
  final Remarks remarks;

  PositionHistoryModel({
    required this.workHistory,
    required this.contractHistory,
    required this.remarks,
  });

  factory PositionHistoryModel.fromJson(Map<String, dynamic> json) {
    return PositionHistoryModel(
      workHistory: WorkHistory.fromJson(json['work_history'] ?? {}),
      contractHistory: (json['contract_history'] as List<dynamic>?)
              ?.map((item) => ContractHistory.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      remarks: Remarks.fromJson(json['remarks'] ?? {}),
    );
  }
}

class WorkHistory {
  final String startOfWork;
  final String appointed;
  final String endOfWork;
  final String leaving;
  final String reasonForLeaving;

  WorkHistory({
    required this.startOfWork,
    required this.appointed,
    required this.endOfWork,
    required this.leaving,
    required this.reasonForLeaving,
  });

  factory WorkHistory.fromJson(Map<String, dynamic> json) {
    return WorkHistory(
      startOfWork: json['start_of_work'] as String? ?? '-',
      appointed: json['appointed'] as String? ?? '-',
      endOfWork: json['end_of_work'] as String? ?? '-',
      leaving: json['leaving'] as String? ?? '-',
      reasonForLeaving: json['reason_for_leaving'] as String? ?? '-',
    );
  }
}

class ContractHistory {
  final int no;
  final String description;
  final String grade;
  final String inDate;
  final String outDate;

  ContractHistory({
    required this.no,
    required this.description,
    required this.grade,
    required this.inDate,
    required this.outDate,
  });

  factory ContractHistory.fromJson(Map<String, dynamic> json) {
    return ContractHistory(
      no: json['no'] as int? ?? 0,
      description: json['description'] as String? ?? '-',
      grade: json['grade'] as String? ?? '-',
      inDate: json['in_date'] as String? ?? '-',
      outDate: json['out_date'] as String? ?? '-',
    );
  }
}

class Remarks {
  final String salary;
  final String notes;

  Remarks({
    required this.salary,
    required this.notes,
  });

  factory Remarks.fromJson(Map<String, dynamic> json) {
    return Remarks(
      salary: json['salary'] as String? ?? '-',
      notes: json['notes'] as String? ?? '-',
    );
  }
}

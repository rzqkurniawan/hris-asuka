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
}

class PositionHistory {
  final List<ContractHistory> contracts;
  final String remarks;

  PositionHistory({
    required this.contracts,
    required this.remarks,
  });

  static PositionHistory getSampleData() {
    return PositionHistory(
      contracts: [
        ContractHistory(
          no: 1,
          description: 'Kontrak Baru',
          grade: 'Office O5C 2023',
          inDate: '28-02-2025',
          outDate: '28-02-2026',
        ),
        ContractHistory(
          no: 2,
          description: 'Kontrak Pertama',
          grade: 'Staff IT O2A',
          inDate: '01-03-2023',
          outDate: '28-02-2025',
        ),
        ContractHistory(
          no: 3,
          description: 'OFF',
          grade: 'Staff IT O2A',
          inDate: '01-02-2023',
          outDate: '28-02-2023',
        ),
        ContractHistory(
          no: 4,
          description: 'Renewal',
          grade: 'Support ITO0AL',
          inDate: '01-02-2022',
          outDate: '31-01-2023',
        ),
        ContractHistory(
          no: 5,
          description: 'OFF',
          grade: 'Support ITO0AL',
          inDate: '01-01-2022',
          outDate: '31-01-2022',
        ),
        ContractHistory(
          no: 6,
          description: 'Kontrak Kedua',
          grade: 'Support ITO0AL',
          inDate: '01-01-2021',
          outDate: '31-12-2021',
        ),
        ContractHistory(
          no: 7,
          description: 'Kontrak Pertama',
          grade: 'Support ITO0AL',
          inDate: '01-07-2019',
          outDate: '31-12-2020',
        ),
      ],
      remarks:
          'Grade semula Support ITO0AL menjadi O-0A per 1 November 2019. Kenaikan Grade dari Support ITO0AL ke Support IT 02A per Bulan Februari 2023. Kenaikan Grade ke O4C 2023 per 29 Februari 2024',
    );
  }
}

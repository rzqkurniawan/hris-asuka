import 'package:intl/intl.dart';

class AttendanceRecord {
  final int no;
  final DateTime checkClockDate;
  final String onDuty;
  final String offDuty;
  final String checkIn;
  final String checkOut;
  final String startCall;
  final String endCall;
  final bool emergencyCall;
  final bool noLunch;
  final String description;
  final String noteForShift;
  final String shiftCategory;
  final String typeWorkHour;
  final bool permissionLate;
  final String computedHolidayNotes;

  AttendanceRecord({
    required this.no,
    required this.checkClockDate,
    this.onDuty = '-',
    this.offDuty = '-',
    required this.checkIn,
    required this.checkOut,
    this.startCall = '-',
    this.endCall = '-',
    this.emergencyCall = false,
    this.noLunch = false,
    this.description = '-',
    this.noteForShift = '-',
    this.shiftCategory = '-',
    this.typeWorkHour = 'NT',
    this.permissionLate = false,
    this.computedHolidayNotes = '-',
  });

  /// Factory constructor from API response
  factory AttendanceRecord.fromApi(Map<String, dynamic> json) {
    return AttendanceRecord(
      no: json['no'] as int,
      checkClockDate: _parseDate(json['date_check_clock'] as String),
      onDuty: json['on_duty'] as String? ?? '-',
      offDuty: json['off_duty'] as String? ?? '-',
      checkIn: json['check_in'] as String? ?? '-',
      checkOut: json['check_out'] as String? ?? '-',
      startCall: json['start_call'] as String? ?? '-',
      endCall: json['end_call'] as String? ?? '-',
      emergencyCall: json['emergency_call'] as bool? ?? false,
      noLunch: json['no_lunch'] as bool? ?? false,
      description: json['description'] as String? ?? '-',
      noteForShift: json['note_for_shift'] as String? ?? '-',
      shiftCategory: json['shift_category'] as String? ?? '-',
      typeWorkHour: json['type_work_hour'] as String? ?? 'NT',
      permissionLate: json['permission_late'] as bool? ?? false,
      computedHolidayNotes: json['computed_holiday_notes'] as String? ?? '-',
    );
  }

  /// Parse date from dd/MM/yyyy format
  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $dateStr');
    }
    return DateTime.now();
  }

  String get day {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[checkClockDate.weekday % 7];
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(checkClockDate);
  }

  bool get isWeekend {
    return checkClockDate.weekday == DateTime.saturday || 
           checkClockDate.weekday == DateTime.sunday;
  }

  // Use the computed holiday notes from backend
  // Already provided in computedHolidayNotes field
}

class MonthlySummary {
  final int month;
  final int year;
  final String monthName;
  final int totalDays;
  final int masuk;
  final int alpha;
  final int izin;
  final int sakit;
  final int cuti;
  final List<AttendanceRecord> records;

  MonthlySummary({
    required this.month,
    required this.year,
    required this.monthName,
    required this.totalDays,
    required this.masuk,
    required this.alpha,
    required this.izin,
    required this.sakit,
    required this.cuti,
    this.records = const [],
  });

  /// Factory constructor from API response
  factory MonthlySummary.fromApi(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json['month'] as int,
      year: json['year'] as int,
      monthName: json['month_name'] as String,
      totalDays: json['total_days'] as int,
      masuk: json['masuk'] as int,
      alpha: json['alpha'] as int,
      izin: json['izin'] as int,
      sakit: json['sakit'] as int,
      cuti: json['cuti'] as int,
      records: const [], // Records come from separate detail endpoint
    );
  }

  String get monthYear {
    return '$monthName $year';
  }

  /// Factory constructor from records (for offline/testing)
  factory MonthlySummary.fromRecords(
    int month,
    int year,
    List<AttendanceRecord> records,
  ) {
    int masukCount = 0;
    int alphaCount = 0;
    int izinCount = 0;
    int sakitCount = 0;
    int cutiCount = 0;

    const monthNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    for (var record in records) {
      final description = record.description.trim();

      if (description == 'Masuk') {
        masukCount++;
      } else if (description == 'Alpha') {
        alphaCount++;
      } else if (description == 'Ijin' || description == 'IjinNormatif') {
        izinCount++;
      } else if (description == 'Sakit') {
        sakitCount++;
      } else if (description == 'Cuti') {
        cutiCount++;
      }
    }

    return MonthlySummary(
      month: month,
      year: year,
      monthName: monthNames[month],
      totalDays: records.length,
      masuk: masukCount,
      alpha: alphaCount,
      izin: izinCount,
      sakit: sakitCount,
      cuti: cutiCount,
      records: records,
    );
  }
}

// Dummy data generator untuk 3 bulan
class AttendanceDataGenerator {
  static List<AttendanceRecord> generateDummyData() {
    final List<AttendanceRecord> allRecords = [];
    int recordNo = 1;

    // September 2024 (23 working days)
    allRecords.addAll(_generateMonthData(recordNo, 9, 2024, 23));
    recordNo += 23;

    // Oktober 2024 (23 working days)
    allRecords.addAll(_generateMonthData(recordNo, 10, 2024, 23));
    recordNo += 23;

    // November 2024 (21 working days)
    allRecords.addAll(_generateMonthData(recordNo, 11, 2024, 21));

    return allRecords;
  }

  static List<AttendanceRecord> _generateMonthData(
    int startNo,
    int month,
    int year,
    int workingDays,
  ) {
    final List<AttendanceRecord> records = [];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < workingDays; i++) {
      final date = DateTime(year, month, i + 1);
      final dayIndex = (startNo + i) % 10;
      
      // Variasi data berdasarkan index
      String checkIn = '08:00';
      String checkOut = '17:00';
      String startCall = '-';
      String endCall = '-';
      bool emergencyCall = false;
      bool noLunch = false;
      String description = 'Masuk';
      String shiftCategory = '-';
      String typeWorkHour = 'NT';
      bool permissionLate = false;

      // Pattern variasi
      switch (dayIndex) {
        case 0: // Normal
          break;
        case 1: // Late
          checkIn = '08:15';
          permissionLate = true;
          break;
        case 2: // Overtime
          startCall = '17:00';
          endCall = '20:00';
          break;
        case 3: // Emergency call
          emergencyCall = true;
          startCall = '17:00';
          endCall = '20:00';
          break;
        case 4: // No lunch
          noLunch = true;
          break;
        case 5: // Shift 1
          checkIn = '07:00';
          checkOut = '15:00';
          shiftCategory = 'Shift 1';
          typeWorkHour = 'Shift 1';
          break;
        case 6: // Absent
          checkIn = '-';
          checkOut = '-';
          description = 'Absent';
          break;
        case 7: // Weekend OT
          if (date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday) {
            checkIn = '09:00';
            checkOut = '14:00';
            description = 'LIBUR/OT';
          }
          break;
        case 8: // Late + Overtime
          checkIn = '08:20';
          checkOut = '18:00';
          startCall = '18:00';
          endCall = '21:00';
          permissionLate = true;
          break;
        case 9: // Shift 2
          checkIn = '15:00';
          checkOut = '23:00';
          shiftCategory = 'Shift 2';
          typeWorkHour = 'Shift 2';
          break;
      }

      records.add(AttendanceRecord(
        no: startNo + i,
        checkClockDate: date,
        checkIn: checkIn,
        checkOut: checkOut,
        startCall: startCall,
        endCall: endCall,
        emergencyCall: emergencyCall,
        noLunch: noLunch,
        description: description,
        shiftCategory: shiftCategory,
        typeWorkHour: typeWorkHour,
        permissionLate: permissionLate,
        computedHolidayNotes: description,
      ));
    }

    return records;
  }

  static Map<String, MonthlySummary> getMonthlySummaries() {
    final allRecords = generateDummyData();
    final Map<String, MonthlySummary> summaries = {};

    // Group by month
    final Map<String, List<AttendanceRecord>> groupedRecords = {};
    
    for (var record in allRecords) {
      final key = '${record.checkClockDate.year}-${record.checkClockDate.month}';
      if (!groupedRecords.containsKey(key)) {
        groupedRecords[key] = [];
      }
      groupedRecords[key]!.add(record);
    }

    // Create monthly summaries
    groupedRecords.forEach((key, records) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      
      summaries[key] = MonthlySummary.fromRecords(month, year, records);
    });

    return summaries;
  }
}

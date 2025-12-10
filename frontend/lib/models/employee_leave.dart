import 'employee.dart';

class EmployeeLeave {
  final String leaveNumber;
  final DateTime leaveDate;
  final DateTime proposedDate;
  final String leaveCategory;
  final bool isApproved;
  final String requestedBy;
  final String requestedById;
  final DateTime startOfLeave;
  final DateTime endOfLeave;
  final DateTime workingDate;
  final String replacementEmployee;
  final String replacementEmployeeId;
  final String leaveAddress;
  final String phone;
  final String status;
  final String? approvedBy;
  final DateTime? approvedDate;
  final String? processedBy;
  final DateTime? processedDate;
  final String? notes;

  EmployeeLeave({
    required this.leaveNumber,
    required this.leaveDate,
    required this.proposedDate,
    required this.leaveCategory,
    required this.isApproved,
    required this.requestedBy,
    required this.requestedById,
    required this.startOfLeave,
    required this.endOfLeave,
    required this.workingDate,
    required this.replacementEmployee,
    required this.replacementEmployeeId,
    required this.leaveAddress,
    required this.phone,
    required this.status,
    this.approvedBy,
    this.approvedDate,
    this.processedBy,
    this.processedDate,
    this.notes,
  });

  String get statusText => isApproved ? 'APPROVED' : 'REJECTED';

  int get durationDays {
    return endOfLeave.difference(startOfLeave).inDays + 1;
  }

  static List<String> getLeaveCategories() {
    return [
      'Cuti Tahunan',
      'Cuti Kematian Istri/Suami/Anak/Orang Tua',
      'Cuti Hamil',
      'Cuti Nikah Karyawan',
      'Cuti Kematian Dalam 1 Rumah',
      'Cuti Pernikahan Anak',
      'Cuti Khitan Anak',
      'Cuti Istri Karyawan Melahirkan',
      'Haid Pertama',
      'Cuti Karyawan Melahirkan',
    ];
  }

  static List<EmployeeLeave> getSampleLeaves() {
    final employeeMap = {
      for (final employee in Employee.getSampleEmployees())
        employee.id: employee,
    };
    String name(String id) => employeeMap[id]!.name;

    return [
      EmployeeLeave(
        leaveNumber: 'ASK-EL-25.0001',
        leaveDate: DateTime(2024, 11, 1),
        proposedDate: DateTime(2024, 10, 28),
        leaveCategory: 'Cuti Tahunan',
        isApproved: true,
        requestedBy: name('K01122'),
        requestedById: 'K01122',
        startOfLeave: DateTime(2024, 11, 18),
        endOfLeave: DateTime(2024, 11, 22),
        workingDate: DateTime(2024, 11, 25),
        replacementEmployee: name('P00965'),
        replacementEmployeeId: 'P00965',
        leaveAddress: 'Jl. Pemuda No. 123, Semarang, Jawa Tengah',
        phone: '081234567890',
        status: 'Used',
        approvedBy: name('P00469'),
        approvedDate: DateTime(2024, 10, 29, 9, 30),
        processedBy: name('K01508'),
        processedDate: DateTime(2024, 10, 29, 10, 15),
        notes: 'Liburan keluarga yang sudah direncanakan sejak awal tahun',
      ),
      EmployeeLeave(
        leaveNumber: 'ASK-EL-25.0002',
        leaveDate: DateTime(2024, 11, 3),
        proposedDate: DateTime(2024, 11, 1),
        leaveCategory: 'Cuti Istri Karyawan Melahirkan',
        isApproved: true,
        requestedBy: name('K01122'),
        requestedById: 'K01122',
        startOfLeave: DateTime(2024, 11, 10),
        endOfLeave: DateTime(2024, 11, 11),
        workingDate: DateTime(2024, 11, 12),
        replacementEmployee: name('P00965'),
        replacementEmployeeId: 'P00965',
        leaveAddress: 'RS Telogorejo, Semarang',
        phone: '081234567890',
        status: 'Used',
        approvedBy: name('P00469'),
        approvedDate: DateTime(2024, 11, 2, 8, 45),
        processedBy: name('K01508'),
        processedDate: DateTime(2024, 11, 2, 9, 20),
        notes: 'Pendampingan istri melahirkan anak kedua',
      ),
      EmployeeLeave(
        leaveNumber: 'ASK-EL-25.0003',
        leaveDate: DateTime(2024, 11, 5),
        proposedDate: DateTime(2024, 11, 4),
        leaveCategory: 'Cuti Tahunan',
        isApproved: false,
        requestedBy: name('K01122'),
        requestedById: 'K01122',
        startOfLeave: DateTime(2024, 12, 24),
        endOfLeave: DateTime(2024, 12, 31),
        workingDate: DateTime(2025, 1, 2),
        replacementEmployee: name('P00965'),
        replacementEmployeeId: 'P00965',
        leaveAddress: 'Bali',
        phone: '081234567890',
        status: 'Pending',
        approvedBy: name('P00469'),
        approvedDate: DateTime(2024, 11, 5, 14, 20),
        processedBy: name('K01508'),
        processedDate: DateTime(2024, 11, 5, 14, 35),
        notes: 'Tidak disetujui karena peak season end of year',
      ),
      EmployeeLeave(
        leaveNumber: 'ASK-EL-25.0004',
        leaveDate: DateTime(2024, 10, 15),
        proposedDate: DateTime(2024, 10, 10),
        leaveCategory: 'Cuti Nikah Karyawan',
        isApproved: true,
        requestedBy: name('K01122'),
        requestedById: 'K01122',
        startOfLeave: DateTime(2024, 10, 25),
        endOfLeave: DateTime(2024, 10, 27),
        workingDate: DateTime(2024, 10, 28),
        replacementEmployee: name('P00965'),
        replacementEmployeeId: 'P00965',
        leaveAddress: 'Gedung Pernikahan Graha Santika, Semarang',
        phone: '081234567890',
        status: 'Used',
        approvedBy: name('P00469'),
        approvedDate: DateTime(2024, 10, 11, 10, 0),
        processedBy: name('K01508'),
        processedDate: DateTime(2024, 10, 11, 10, 45),
        notes: 'Pernikahan dengan pasangan yang sudah 3 tahun pacaran',
      ),
      EmployeeLeave(
        leaveNumber: 'ASK-EL-25.0005',
        leaveDate: DateTime(2024, 9, 20),
        proposedDate: DateTime(2024, 9, 15),
        leaveCategory: 'Cuti Tahunan',
        isApproved: true,
        requestedBy: name('K01122'),
        requestedById: 'K01122',
        startOfLeave: DateTime(2024, 10, 1),
        endOfLeave: DateTime(2024, 10, 5),
        workingDate: DateTime(2024, 10, 6),
        replacementEmployee: name('P00965'),
        replacementEmployeeId: 'P00965',
        leaveAddress: 'Yogyakarta',
        phone: '081234567890',
        status: 'Used',
        approvedBy: name('P00469'),
        approvedDate: DateTime(2024, 9, 16, 11, 30),
        processedBy: name('K01508'),
        processedDate: DateTime(2024, 9, 16, 12, 0),
        notes: 'Cuti tahunan pertengahan tahun',
      ),
    ];
  }
}

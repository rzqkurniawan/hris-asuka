class Employee {
  final String id;
  final String name;
  final String initials;
  final String? employeeFileName; // Photo filename from API

  Employee({
    required this.id,
    required this.name,
    required this.initials,
    this.employeeFileName,
  });

  // Helper method to get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'
        .toUpperCase();
  }

  // Sample data
  static List<Employee> getSampleEmployees() {
    return [
      Employee(id: 'K01122', name: 'Rachmat Rizqi Kurniawan', initials: 'RZQ'),
      Employee(id: 'K02024', name: 'Fakhrur Rozi', initials: 'FR'),
      Employee(id: 'P00965', name: 'Arip Sugiyanto', initials: 'AS'),
      Employee(id: 'K01107', name: 'Ahmad Tohir', initials: 'AT'),
      Employee(
          id: 'K01508', name: 'Muhammad Fadli Adi Saputra', initials: 'FAS'),
      Employee(
          id: 'K01961', name: 'Muhammad Faisol Hibatullah', initials: 'FH'),
      Employee(id: 'K03312', name: 'Muhammad Cahyani', initials: 'MC'),
      Employee(id: 'P00469', name: 'Aunur Rofiq', initials: 'AR'),
      Employee(id: 'K02423', name: 'Gabrillah Mullah Sandra', initials: 'GMS'),
      Employee(id: 'K01762', name: 'Prita Rosalina', initials: 'PR'),
      Employee(id: 'K02109', name: 'Safira Indriani Agustin', initials: 'SIA'),
      Employee(id: 'K04459', name: 'Frida Divianatasya', initials: 'FD'),
      Employee(id: 'K02506', name: 'Yusria Latifa', initials: 'YL'),
      Employee(id: 'T10799', name: 'Deandra Rizky Maulidya', initials: 'DRM'),
      Employee(id: 'T9925', name: 'Rajid Yamaq Mahfud', initials: 'RYM'),
      Employee(id: 'K02863', name: 'Rifan Syah', initials: 'RS'),
    ];
  }
}

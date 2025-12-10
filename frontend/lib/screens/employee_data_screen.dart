import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../models/employee_data_model.dart';
import '../services/employee_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class EmployeeDataScreen extends StatefulWidget {
  const EmployeeDataScreen({super.key});

  @override
  State<EmployeeDataScreen> createState() => _EmployeeDataScreenState();
}

class _EmployeeDataScreenState extends State<EmployeeDataScreen> {
  final EmployeeService _employeeService = EmployeeService();
  EmployeeDataModel? _employeeData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    try {
      final data = await _employeeService.getEmployeeData();
      setState(() {
        _employeeData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        title: Text(
          'Employee Data',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color:
                    isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load employee data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadEmployeeData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Data Section
                      _buildSectionCard(
                        context,
                        isDarkMode,
                        title: 'Personal Data',
                        icon: Icons.person,
                        children: [
                          _buildDataRow('Employee Name',
                              _employeeData!.personalData.fullname, isDarkMode),
                          _buildDataRow('Nickname',
                              _employeeData!.personalData.nickname, isDarkMode),
                          _buildDataRow('Gender',
                              _employeeData!.personalData.gender, isDarkMode),
                          _buildDataRow(
                              'Blood Type',
                              _employeeData!.personalData.bloodType,
                              isDarkMode),
                          _buildDataRow(
                              'Place, Date of Birth',
                              _employeeData!.personalData.placeDateBirth,
                              isDarkMode),
                          _buildDataRow('Religion',
                              _employeeData!.personalData.religion, isDarkMode),
                          _buildDataRow(
                              'Marital Status',
                              _employeeData!.personalData.maritalStatus,
                              isDarkMode),
                          _buildDataRow('Address',
                              _employeeData!.personalData.address, isDarkMode),
                          _buildDataRowWithButton(
                            context,
                            'NIK',
                            _employeeData!.personalData.nik,
                            isDarkMode,
                            onTap: _employeeData!.personalData.identityFile !=
                                    null
                                ? () => _showKTPImage(context, isDarkMode,
                                    _employeeData!.personalData.identityFile!)
                                : null,
                          ),
                          _buildDataRow(
                              'Mobile Phone',
                              _employeeData!.personalData.mobilePhone,
                              isDarkMode),
                          _buildDataRow('Email',
                              _employeeData!.personalData.email, isDarkMode),
                          _buildDataRow('NPWP',
                              _employeeData!.personalData.npwp, isDarkMode),
                          _buildDataRow(
                              'BPJS Kesehatan',
                              _employeeData!.personalData.bpjsHealth,
                              isDarkMode),
                          _buildDataRow(
                              'BPJS Ketenagakerjaan',
                              _employeeData!.personalData.bpjsEmployment,
                              isDarkMode),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Employment Data Section
                      _buildSectionCard(
                        context,
                        isDarkMode,
                        title: 'Employment Data',
                        icon: Icons.work,
                        children: [
                          _buildDataRow(
                              'ID Badge',
                              _employeeData!.employmentData.employeeNumber,
                              isDarkMode),
                          _buildDataRow(
                              'Job Title',
                              _employeeData!.employmentData.jobTitle,
                              isDarkMode),
                          _buildDataRow(
                              'Employee Grade',
                              _employeeData!.employmentData.employeeGrade,
                              isDarkMode),
                          _buildDataRow(
                              'Department',
                              _employeeData!.employmentData.department,
                              isDarkMode),
                          _buildDataRow(
                              'Job Code',
                              _employeeData!.employmentData.jobOrder,
                              isDarkMode),
                          _buildDataRow(
                              'Workbase',
                              _employeeData!.employmentData.workbase,
                              isDarkMode),
                          _buildDataRow(
                              'Employee Status',
                              _employeeData!.employmentData.employeeStatus,
                              isDarkMode),
                          _buildDataRow(
                              'Working Status',
                              _employeeData!.employmentData.workingStatus,
                              isDarkMode),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    bool isDarkMode, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? AppColors.primaryDark : AppColors.secondaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRowWithButton(
    BuildContext context,
    String label,
    String value,
    bool isDarkMode, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (onTap != null)
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.primaryDark.withOpacity(0.2)
                            : AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image,
                            size: 16,
                            color: isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View KTP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showKTPImage(
      BuildContext context, bool isDarkMode, String fileName) async {
    HapticFeedback.mediumImpact();

    // Build image URL - using same endpoint as avatar since both use same storage path
    final encodedFileName = Uri.encodeComponent(fileName);
    final imageUrl = '${ApiConfig.baseUrl}/employees/photo/$encodedFileName';

    // Get auth token
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      // Show error if no token available
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? AppColors.primaryGradientDark
                          : AppColors.secondaryGradientLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'KTP / Identity Card',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  httpHeaders: {
                    'Authorization': 'Bearer $token',
                  },
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.surfaceAltDark
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Loading KTP...',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.surfaceAltDark
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load KTP image',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'File: $fileName',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

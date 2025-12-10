import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/employee_leave_model.dart';
import '../services/employee_leave_service.dart';
import '../widgets/employee_leave_card.dart';
import '../widgets/shimmer_skeleton.dart';
import '../constants/app_colors.dart';
import '../utils/page_transitions.dart';
import '../utils/toast_utils.dart';
import 'employee_leave_detail_screen.dart';
import 'employee_leave_form_screen.dart';

class EmployeeLeaveListScreen extends StatefulWidget {
  const EmployeeLeaveListScreen({super.key});

  @override
  State<EmployeeLeaveListScreen> createState() =>
      _EmployeeLeaveListScreenState();
}

class _EmployeeLeaveListScreenState extends State<EmployeeLeaveListScreen> {
  final EmployeeLeaveService _leaveService = EmployeeLeaveService();
  List<EmployeeLeave> _leaves = [];
  List<EmployeeLeave> _filteredLeaves = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLeaves);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _leaveService.getEmployeeLeaves();
      if (mounted) {
        setState(() {
          _leaves = response.leaves;
          _filteredLeaves = _leaves;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        ToastUtils.showError(context, 'Failed to load employee leaves');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLeaves() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLeaves = _leaves;
      } else {
        _filteredLeaves = _leaves.where((leave) {
          return leave.employeeLeaveNumber.toLowerCase().contains(query) ||
              leave.leaveCategoryName.toLowerCase().contains(query) ||
              leave.notes.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  bool _isPending(EmployeeLeave leave) {
    if (leave.isApproved) return false;
    final status = leave.status.toLowerCase();
    // Treat common pending keywords as pending; otherwise, fall back to pending when not approved and not explicitly rejected
    if (status.contains('pending') || status.contains('menunggu')) {
      return true;
    }
    if (status.contains('approve')) return false;
    if (status.contains('reject') || status.contains('tolak')) return false;
    return true;
  }

  bool _isRejected(EmployeeLeave leave) {
    if (leave.isApproved) return false;
    if (_isPending(leave)) return false;
    final status = leave.status.toLowerCase();
    return status.contains('reject') || status.contains('tolak');
  }

  int get _approvedCount => _leaves.where((leave) => leave.isApproved).length;
  int get _pendingCount => _leaves.where(_isPending).length;
  int get _rejectedCount => _leaves.where(_isRejected).length;

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
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        title: Text(
          'Employee Leave',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? _buildLoadingState(context)
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      72 + MediaQuery.of(context).padding.bottom,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards (layout matches overtime dashboard)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            const spacing = 15.0;
                            final double topCardWidth = width <= spacing
                                ? width / 2
                                : (width - spacing) / 2;

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: topCardWidth,
                                      child: _buildSummaryCard(
                                        title: 'Pending',
                                        count: _pendingCount,
                                        gradient: AppColors.statusLateGradient,
                                        icon: Icons.access_time,
                                      ),
                                    ),
                                    const SizedBox(width: spacing),
                                    SizedBox(
                                      width: topCardWidth,
                                      child: _buildSummaryCard(
                                        title: 'Rejected',
                                        count: _rejectedCount,
                                        gradient: AppColors.statusAbsentGradient,
                                        icon: Icons.cancel,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: width,
                                  child: _buildSummaryCard(
                                    title: 'Approved',
                                    count: _approvedCount,
                                    gradient: AppColors.statusWorkGradient,
                                    icon: Icons.check_circle,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 25),

                        // Leaves List
                        if (_filteredLeaves.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: isDarkMode
                                        ? AppColors.textSecondaryDark
                                            .withOpacity(0.3)
                                        : AppColors.textSecondaryLight
                                            .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No employee leaves found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          AnimationLimiter(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredLeaves.length,
                              itemBuilder: (context, index) {
                                final leave = _filteredLeaves[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: EmployeeLeaveCard(
                                        leave: leave,
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          final result = await Navigator.push(
                                            context,
                                            SlideRightRoute(
                                              page: EmployeeLeaveDetailScreen(
                                                leave: leave,
                                              ),
                                            ),
                                          );
                                          // Reload if deleted - use Future.microtask to avoid Navigator lock
                                          if (result == true && mounted) {
                                            Future.microtask(() => _loadData());
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Floating Action Button
                  Positioned(
                    right: 20,
                    bottom: 20 + MediaQuery.of(context).padding.bottom,
                    child: FloatingActionButton.extended(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final result = await Navigator.push(
                          context,
                          SlideRightRoute(
                            page: const EmployeeLeaveFormScreen(),
                          ),
                        );
                        // Reload data if leave was created successfully - use Future.microtask to avoid Navigator lock
                        if (result == true && mounted) {
                          Future.microtask(() => _loadData());
                        }
                      },
                      backgroundColor: isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      icon: Icon(Icons.add, color: AppColors.overlayLight),
                      label: Text(
                        'Create',
                        style: TextStyle(
                          color: AppColors.overlayLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: ShimmerCard(height: 100)),
              SizedBox(width: 15),
              Expanded(child: ShimmerCard(height: 100)),
            ],
          ),
          const SizedBox(height: 15),
          const ShimmerCard(height: 100),
          const SizedBox(height: 25),
          const Expanded(
            child: ShimmerList(itemCount: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required LinearGradient gradient,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: AppColors.overlayLight.withOpacity(0.9),
                size: 28,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.overlayLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.overlayLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.overlayLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

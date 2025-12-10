import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/overtime_order.dart';
import '../services/overtime_service.dart';
import '../widgets/overtime_order_card.dart';
import '../widgets/shimmer_skeleton.dart';
import '../constants/app_colors.dart';
import '../utils/page_transitions.dart';
import 'overtime_detail_screen.dart';

class OvertimeListScreen extends StatefulWidget {
  const OvertimeListScreen({
    super.key,
  });

  @override
  State<OvertimeListScreen> createState() => _OvertimeListScreenState();
}

class _OvertimeListScreenState extends State<OvertimeListScreen> {
  List<OvertimeOrder> _orders = [];
  List<OvertimeOrder> _filteredOrders = [];
  final TextEditingController _searchController = TextEditingController();
  final OvertimeService _overtimeService = OvertimeService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterOrders);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to get overtime list
      final response = await _overtimeService.getOvertimeList();

      setState(() {
        _orders = response.overtimes;
        _filteredOrders = _orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load overtime list: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) {
          return order.orderNumber.toLowerCase().contains(query) ||
              order.department.toLowerCase().contains(query) ||
              order.requestedBy.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  int get _approvedCount => _orders.where((order) => order.isApproved).length;

  int get _pendingCount => _orders.where((order) => order.isPending).length;

  int get _rejectedCount => _orders.where((order) => order.isRejected).length;

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
          'Overtime Orders',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Show search dialog
              _showSearchDialog();
            },
            icon: Icon(
              Icons.search,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? _buildLoadingState(context)
            : _errorMessage != null
                ? _buildErrorState(context)
                : SingleChildScrollView(
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
                    // Summary Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        const spacing = 15.0;
                        final double topCardWidth =
                            width <= spacing ? width / 2 : (width - spacing) / 2;

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

                    // Orders List
                    if (_filteredOrders.isEmpty)
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
                                'No overtime orders found',
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
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: OvertimeOrderCard(
                                    order: order,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.push(
                                        context,
                                        SlideRightRoute(
                                          page: OvertimeDetailScreen(
                                            order: order,
                                          ),
                                        ),
                                      );
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
                color: Colors.white.withOpacity(0.9),
                size: 28,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final bottomPadding = 72 + MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ShimmerSkeleton.rectangular(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: ShimmerSkeleton.rectangular(
                  width: double.infinity,
                  height: 100,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ],
          ),
          SizedBox(height: 25),
          ShimmerList(itemCount: 5),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = 72 + MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.error_outline,
              size: 80,
              color: isDarkMode
                  ? AppColors.textSecondaryDark.withOpacity(0.5)
                  : AppColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Search Orders'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Order number, department, etc...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _searchController.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/text_fields.dart';
import '../../data/admin_repository.dart';
import '../../../fleet/data/fleet_repository.dart';

class AdminPortalScreen extends ConsumerStatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  ConsumerState<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends ConsumerState<AdminPortalScreen> {
  String _selectedSection = 'dashboard';
  bool _isLoading = false;

  // Data arrays
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _coupons = [];
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _fraudAlerts = [];
  List<Map<String, dynamic>> _dynamicPricing = [];
  List<Map<String, dynamic>> _managedStaff = [];
  List<Map<String, dynamic>> _buses = [];

  // Add dialog controllers
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _couponCodeController = TextEditingController();
  final _couponPercentController = TextEditingController();

  // Staff form controllers
  final _staffNameCtrl = TextEditingController();
  final _staffEmailCtrl = TextEditingController();
  final _staffPhoneCtrl = TextEditingController();
  final _staffPasswordCtrl = TextEditingController();
  final _busNumberCtrl = TextEditingController();
  final _busModelCtrl = TextEditingController();
  final _busCapacityCtrl = TextEditingController(text: '40');
  String _busStatus = 'active';
  String _staffRole = 'driver'; // 'driver' or 'conductor'

  // Dynamic pricing toggle variables
  bool _dynamicPricingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _couponCodeController.dispose();
    _couponPercentController.dispose();
    _staffNameCtrl.dispose();
    _staffEmailCtrl.dispose();
    _staffPhoneCtrl.dispose();
    _staffPasswordCtrl.dispose();
    _busNumberCtrl.dispose();
    _busModelCtrl.dispose();
    _busCapacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);

      final comps = await repo.getCompanies();
      final branches = await repo.getBranches();
      final coupons = await repo.getCoupons();
      final tickets = await repo.getSupportTickets();
      final payments = await repo.getPayments();
      final logs = await repo.getAuditLogs();
      final frauds = await repo.getFraudDetections();
      final pricing = await repo.getDynamicPricingModifications();
      final staff = await repo.getManagedStaff();
      final buses = await ref.read(fleetRepositoryProvider).getBuses();

      if (mounted) {
        setState(() {
          _companies = comps;
          _branches = branches;
          _coupons = coupons;
          _tickets = tickets;
          _payments = payments;
          _auditLogs = logs;
          _fraudAlerts = frauds;
          _dynamicPricing = pricing;
          _managedStaff = staff;
          _buses = buses;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _triggerReportExport(String reportType, String format) async {
    setState(() => _isLoading = true);
    try {
      final filename = await ref.read(adminRepositoryProvider).exportReport(
        reportType: reportType,
        format: format,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully exported $filename to downloads!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCompany() async {
    if (_companyNameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).addCompany({
        'name': _companyNameController.text.trim(),
        'contact_email': _companyEmailController.text.trim(),
        'contact_phone': _companyPhoneController.text.trim(),
      });
      _companyNameController.clear();
      _companyEmailController.clear();
      _companyPhoneController.clear();
      await _loadAllAdminData();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add company: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCoupon() async {
    if (_couponCodeController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final discount = double.tryParse(_couponPercentController.text) ?? 10.0;
      await ref.read(adminRepositoryProvider).addCoupon({
        'code': _couponCodeController.text.trim().toUpperCase(),
        'discount_percent': discount,
        'valid_from': DateTime.now().toUtc().toIso8601String(),
        'valid_to': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
      });
      _couponCodeController.clear();
      _couponPercentController.clear();
      await _loadAllAdminData();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add coupon: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCompany(String id) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).deleteCompany(id);
      await _loadAllAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete company: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCoupon(String id) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).deleteCoupon(id);
      await _loadAllAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete coupon: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resolveTicket(String ticketId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).updateTicketStatus(ticketId, 'resolved');
      await _loadAllAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve ticket: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    Widget mainContent;
    switch (_selectedSection) {
      case 'companies':
        mainContent = _buildCompaniesSection();
        break;
      case 'branches':
        mainContent = _buildBranchesSection();
        break;
      case 'coupons':
        mainContent = _buildCouponsSection();
        break;
      case 'audit_logs':
        mainContent = _buildAuditLogsSection();
        break;
      case 'support':
        mainContent = _buildSupportTicketsSection();
        break;
      case 'ai_desk':
        mainContent = _buildAIDeskSection();
        break;
      case 'manage_staff':
        mainContent = _buildManageStaffSection();
        break;
      case 'buses':
        mainContent = _buildBusesSection();
        break;
      case 'dashboard':
      default:
        mainContent = _buildDashboardOverview();
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Somali Smart Bus Enterprise Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAllAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      drawer: !isDesktop ? Drawer(child: _buildSidebarContent(isDrawer: true)) : null,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(right: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: _buildSidebarContent(isDrawer: false),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: mainContent,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR DESIGN (DESKTOP & DRAWER RESPONSIVE) ---
  Widget _buildSidebarContent({required bool isDrawer}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header profile info
        Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ENTERPRISE CONTROL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Somali Smart Bus System',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildSidebarTile(title: 'Overview Dashboard', section: 'dashboard', icon: Icons.dashboard_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Manage Staff', section: 'manage_staff', icon: Icons.badge_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Manage Buses (Fleet)', section: 'buses', icon: Icons.directions_bus_filled_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Transit Companies', section: 'companies', icon: Icons.domain_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Regional Branches', section: 'branches', icon: Icons.location_city_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Coupons & Promos', section: 'coupons', icon: Icons.local_offer_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'AI Intelligence Desk', section: 'ai_desk', icon: Icons.auto_awesome_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Audit Logging Logs', section: 'audit_logs', icon: Icons.security_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Support Desk Tickets', section: 'support', icon: Icons.support_agent_rounded, isDrawer: isDrawer),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarTile({required String title, required String section, required IconData icon, required bool isDrawer}) {
    final isSelected = _selectedSection == section;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isDark ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.primaryBlue.withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon, 
          color: isSelected 
              ? AppColors.primaryBlue 
              : (isDark ? Colors.white60 : Colors.grey[600]),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
                ? AppColors.primaryBlue 
                : (isDark ? Colors.white70 : Colors.grey[800]),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          setState(() {
            _selectedSection = section;
          });
          if (isDrawer) Navigator.pop(context);
        },
      ),
    );
  }

  // --- 1. OVERVIEW DASHBOARD & DYNAMIC CHARTS ---
  Widget _buildDashboardOverview() {
    final double totalRevenue = _payments.where((p) => p['status'] == 'completed').fold<double>(0.0, (sum, element) => sum + (double.tryParse(element['amount'].toString()) ?? 0.0));
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview Dashboard', 
                    style: AppTypography.h1.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live metrics, revenue performance analytics, and dynamic pricing updates', 
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _triggerReportExport('revenue_weekly', 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Export Weekly PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  AppSpacing.gapW12,
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _triggerReportExport('revenue_monthly', 'xlsx'),
                    icon: const Icon(Icons.table_view_rounded, size: 18),
                    label: const Text('Export Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              )
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview Dashboard', 
                style: AppTypography.h1.copyWith(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live metrics, revenue performance analytics, and dynamic pricing updates', 
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH16,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _triggerReportExport('revenue_weekly', 'pdf'),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _triggerReportExport('revenue_monthly', 'xlsx'),
                      icon: const Icon(Icons.table_view_rounded, size: 18),
                      label: const Text('Export Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              )
            ],
          ),
        AppSpacing.gapH24,

        // High-level Stats Cards
        _buildStatsSection(totalRevenue),
        AppSpacing.gapH32,

        // Custom Analytics Chart Mock
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRevenueChartCard(),
              ),
              AppSpacing.gapW20,
              Expanded(
                child: _buildRouteDensitiesCard(),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildRevenueChartCard(),
              AppSpacing.gapH16,
              _buildRouteDensitiesCard(),
            ],
          )
      ],
    );
  }

  Widget _buildRevenueChartCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 8,
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
              Text(
                'Monthly Revenue Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AI Estimated Demand',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Visual graph mock representation using container bar indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildChartBar(label: 'Jan', heightPercent: 0.35, val: '\$1,200'),
              _buildChartBar(label: 'Feb', heightPercent: 0.50, val: '\$2,100'),
              _buildChartBar(label: 'Mar', heightPercent: 0.45, val: '\$1,900'),
              _buildChartBar(label: 'Apr', heightPercent: 0.70, val: '\$3,200'),
              _buildChartBar(label: 'May', heightPercent: 0.85, val: '\$4,500'),
              _buildChartBar(label: 'Jun', heightPercent: 0.95, val: '\$5,100', color: AppColors.successGreen),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRouteDensitiesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Densities Heatmap Load',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildRouteLoadBar(route: 'Mogadishu ➔ Garowe', density: 0.92, label: '92% (High demand modifier)'),
          _buildRouteLoadBar(route: 'Hargeisa ➔ Burao', density: 0.55, label: '55% (Mid load factor)'),
          _buildRouteLoadBar(route: 'Mogadishu ➔ Kismayo', density: 0.78, label: '78% (Peak weekend traffic)'),
        ],
      ),
    );
  }

  Widget _buildStatsSection(double totalRevenue) {
    final width = MediaQuery.of(context).size.width;
    final card1 = _buildStatCard(title: 'Active Companies', value: '${_companies.length}', subtitle: 'Transit Partners', icon: Icons.domain_rounded, color: AppColors.primaryBlue);
    final card2 = _buildStatCard(title: 'Total Revenue Logged', value: '\$${totalRevenue.toStringAsFixed(2)}', subtitle: 'Payments completed', icon: Icons.payments_rounded, color: AppColors.successGreen);
    final card3 = _buildStatCard(title: 'AI Fraud Risk Flags', value: '${_fraudAlerts.length}', subtitle: 'Flagged transactions', icon: Icons.gpp_maybe_rounded, color: AppColors.errorRed);
    final card4 = _buildStatCard(title: 'Active Promos', value: '${_coupons.length}', subtitle: 'Campaigns running', icon: Icons.local_offer_rounded, color: AppColors.accentGold);

    if (width > 1200) {
      return Row(
        children: [
          Expanded(child: card1),
          AppSpacing.gapW16,
          Expanded(child: card2),
          AppSpacing.gapW16,
          Expanded(child: card3),
          AppSpacing.gapW16,
          Expanded(child: card4),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: card1),
              AppSpacing.gapW16,
              Expanded(child: card2),
            ],
          ),
          AppSpacing.gapH16,
          Row(
            children: [
              Expanded(child: card3),
              AppSpacing.gapW16,
              Expanded(child: card4),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title/Label
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Icon in a colored bubble
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Large Bold Value
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Subtitle / context status-dot
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar({required String label, required double heightPercent, required String val, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          val, 
          style: TextStyle(
            fontSize: 11, 
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 150 * heightPercent,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: color != null
                  ? [color, color.withValues(alpha: 0.7)]
                  : [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.7)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: (color ?? AppColors.primaryBlue).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildFareShiftsCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.pAll24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dynamic Pricing Fare Shifts', style: AppTypography.subtitle),
            AppSpacing.gapH16,
            for (var item in _dynamicPricing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['route'].toString(), style: AppTypography.bodyMedium),
                          Text(item['reason'].toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(
                      '${item['base_price']} ➔ \$${item['calculated_fare']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildFraudDetectionsCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.pAll24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Security Fraud Detections', style: AppTypography.subtitle),
            AppSpacing.gapH16,
            for (var item in _fraudAlerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${item['passenger']}', style: AppTypography.bodyMedium),
                          Text(item['reason'].toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['risk_score'].toString(),
                        style: const TextStyle(color: AppColors.errorRed, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildRouteLoadBar({required String route, required double density, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = density > 0.85 
        ? AppColors.errorRed 
        : (density > 0.70 ? AppColors.warningOrange : AppColors.primaryBlue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                route,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(density * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: density,
              minHeight: 8,
              color: color,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. TRANSIT COMPANIES CRUD PANEL ---
  Widget _buildCompaniesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            if (isDesktop) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transit Operators Directory', style: AppTypography.h1),
                      Text('Register and manage Somali Smart Bus Transit Companies', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                    onPressed: () => _showAddCompanyDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Transit Partner'),
                  )
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transit Operators Directory', style: AppTypography.h1),
                  const Text('Register and manage Somali Smart Bus Transit Companies', style: TextStyle(color: Colors.grey)),
                  AppSpacing.gapH12,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                      onPressed: () => _showAddCompanyDialog(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Transit Partner'),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        AppSpacing.gapH24,

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _companies.length,
          itemBuilder: (context, index) {
            final company = _companies[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryBlue,
                  child: Icon(Icons.domain_rounded, color: Colors.white),
                ),
                title: Text(company['name'].toString(), style: AppTypography.subtitle),
                subtitle: Text('Email: ${company['contact_email']} | Phone: ${company['contact_phone']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                  onPressed: () => _deleteCompany(company['id'].toString()),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  void _showAddCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Transit Company'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Company Name', hintText: 'Enter company name', controller: _companyNameController, prefixIcon: Icons.business_rounded),
              AppSpacing.gapH12,
              AppTextField(label: 'Contact Email', hintText: 'E.g. operator@email.com', controller: _companyEmailController, prefixIcon: Icons.email_outlined),
              AppSpacing.gapH12,
              AppTextField(label: 'Contact Phone', hintText: 'E.g. +252 61 5551122', controller: _companyPhoneController, prefixIcon: Icons.phone_android),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _addCompany, child: const Text('Register')),
          ],
        );
      },
    );
  }

  // --- 3. REGIONAL BRANCHES PANEL ---
  Widget _buildBranchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Regional Depot Branches', style: AppTypography.h1),
        const Text('Regional central stations and booking depots listings', style: TextStyle(color: Colors.grey)),
        AppSpacing.gapH24,

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _branches.length,
          itemBuilder: (context, index) {
            final branch = _branches[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_rounded, color: AppColors.accentGold, size: 28),
                title: Text('${branch['name']} (${branch['code']})', style: AppTypography.subtitle),
                subtitle: Text('City: ${branch['city']} | Manager: ${branch['manager_name']} | Phone: ${branch['contact_phone']}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('ACTIVE', style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  // --- 4. COUPONS & CAMPAIGNS ---
  Widget _buildCouponsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            if (isDesktop) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Promotions & Coupon Codes', style: AppTypography.h1),
                      Text('Generate marketing codes and ticket discounts', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.white),
                    onPressed: () => _showAddCouponDialog(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Generate Code'),
                  )
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Promotions & Coupon Codes', style: AppTypography.h1),
                  const Text('Generate marketing codes and ticket discounts', style: TextStyle(color: Colors.grey)),
                  AppSpacing.gapH12,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.white),
                      onPressed: () => _showAddCouponDialog(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Generate Code'),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        AppSpacing.gapH24,

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _coupons.length,
          itemBuilder: (context, index) {
            final cp = _coupons[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.local_offer_rounded, color: AppColors.accentGold),
                title: Text(cp['code'].toString(), style: AppTypography.subtitle.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                subtitle: Text('Discount: ${cp['discount_percent']}% | Expiry: ${cp['valid_to']} | Uses: ${cp['used_count']}/${cp['usage_limit'] ?? "∞"}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                  onPressed: () => _deleteCoupon(cp['id'].toString()),
                ),
              ),
            );
          },
        )
      ],
    );
  }

  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Coupon Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Promo Code (Uppercase)', hintText: 'E.g. XAGAA2026', controller: _couponCodeController, prefixIcon: Icons.label_rounded),
              AppSpacing.gapH12,
              AppTextField(label: 'Discount Percentage (%)', hintText: 'E.g. 15', controller: _couponPercentController, prefixIcon: Icons.percent_rounded, keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _addCoupon, child: const Text('Activate Promo')),
          ],
        );
      },
    );
  }

  // --- 5. SYSTEM AUDIT SECURITY LOGS ---
  Widget _buildAuditLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('System Audit Logging', style: AppTypography.h1),
        const Text('Unmodifiable administrative activities and database write updates logs (RLS Guarded)', style: TextStyle(color: Colors.grey)),
        AppSpacing.gapH24,

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _auditLogs.length,
          itemBuilder: (context, index) {
            final log = _auditLogs[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.security_rounded, color: Colors.blueGrey),
                title: Text('${log['action']} ➔ Table: ${log['table_name']}', style: AppTypography.subtitle),
                subtitle: Text('User: ${log['user_email']} | IP: ${log['ip_address']}'),
                trailing: Text(log['created_at'].toString(), style: AppTypography.bodySmall),
              ),
            );
          },
        )
      ],
    );
  }

  // --- 6. SUPPORT TICKETS RESOLUTION DESK ---
  Widget _buildSupportTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Support Desk Console', style: AppTypography.h1),
        const Text('Review passenger queries, booking delays, and wallet disputes', style: TextStyle(color: Colors.grey)),
        AppSpacing.gapH24,

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tickets.length,
          itemBuilder: (context, index) {
            final tk = _tickets[index];
            final status = tk['status'].toString();

            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.support_agent_rounded,
                  color: status == 'resolved' ? AppColors.successGreen : AppColors.warningOrange,
                ),
                title: Text(tk['subject'].toString(), style: AppTypography.subtitle),
                subtitle: Text('Category: ${tk['category'].toUpperCase()} | Priority: ${tk['priority'].toUpperCase()} | Date: ${tk['created_at']}'),
                trailing: status == 'resolved'
                    ? const Text('RESOLVED', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold))
                    : ElevatedButton(
                        onPressed: () => _resolveTicket(tk['id'].toString()),
                        child: const Text('Resolve'),
                      ),
              ),
            );
          },
        )
      ],
    );
  }

  // --- 7. AI SYSTEM INTEGRATION PANEL ---
  Widget _buildAIDeskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Optimization Console', style: AppTypography.h1),
        const Text('Configure machine learning demand prediction, automated dynamic pricing, and fraud rules', style: TextStyle(color: Colors.grey)),
        AppSpacing.gapH24,

        // AI Configuration controls card
        Card(
          child: Padding(
            padding: AppSpacing.pAll24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dynamic Pricing Modifier Settings', style: AppTypography.subtitle),
                AppSpacing.gapH12,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dynamic Pricing Algorithm Toggler', style: AppTypography.bodyLarge),
                          Text('Automatically increases ticket fares by 10% during route passenger load peaks.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    AppSpacing.gapW16,
                    Switch.adaptive(
                      value: _dynamicPricingEnabled,
                      onChanged: (val) {
                        setState(() {
                          _dynamicPricingEnabled = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Dynamic Pricing Algorithm Enabled' : 'Dynamic Pricing Algorithm Disabled'),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapH24,

        Builder(
          builder: (context) {
            final isDesktop = MediaQuery.of(context).size.width > 900;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFareShiftsCard(),
                  ),
                  AppSpacing.gapW20,
                  Expanded(
                    child: _buildFraudDetectionsCard(),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildFareShiftsCard(),
                  AppSpacing.gapH16,
                  _buildFraudDetectionsCard(),
                ],
              );
            }
          },
        )
      ],
    );
  }

  // --- BUS FLEET MANAGEMENT SECTION ---
  Widget _buildBusesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bus Fleet Management', style: AppTypography.h2),
                Text('Monitor, register and retire buses in the active transit fleet', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showAddBusDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Xaree Bus (New)'),
            )
          ],
        ),
        AppSpacing.gapH24,
        _buses.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: Text('No buses registered yet.')))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _buses.length,
                itemBuilder: (context, index) {
                  final bus = _buses[index];
                  final status = bus['status'].toString();
                  final busNo = bus['bus_number'].toString();

                  Color statusColor;
                  switch (status) {
                    case 'active':
                      statusColor = AppColors.successGreen;
                      break;
                    case 'maintenance':
                      statusColor = AppColors.warningOrange;
                      break;
                    case 'out_of_service':
                    default:
                      statusColor = AppColors.errorRed;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: AppSpacing.radiusMedium,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        child: Icon(Icons.directions_bus_filled_rounded, color: statusColor),
                      ),
                      title: Text(busNo, style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Model: ${bus['model']} | Capacity: ${bus['capacity']} Seats'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.radiusSmall,
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, color: AppColors.primaryBlue),
                            onPressed: () => _showViewBusDialog(bus),
                            tooltip: 'View Details',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.accentGold),
                            onPressed: () => _showEditBusDialog(bus),
                            tooltip: 'Edit Bus',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Retire Bus?'),
                                  content: Text('Are you sure you want to delete bus $busNo from the system?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteBus(busNo);
                                      },
                                      child: const Text('Delete'),
                                    )
                                  ],
                                ),
                              );
                            },
                            tooltip: 'Retire Bus',
                          )
                        ],
                      ),
                    ),
                  );
                },
              )
      ],
    );
  }

  void _showAddBusDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Xaree Bus Cusub (Register New Bus)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Bus License Number (Plate)',
                      hintText: 'e.g. MOG-KIS-09',
                      controller: _busNumberCtrl,
                      prefixIcon: Icons.tag,
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Bus Model',
                      hintText: 'e.g. Toyota Coaster 2024',
                      controller: _busModelCtrl,
                      prefixIcon: Icons.directions_bus_rounded,
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Seat Capacity',
                      hintText: 'e.g. 40',
                      controller: _busCapacityCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.chair_rounded,
                    ),
                    AppSpacing.gapH16,
                    DropdownButtonFormField<String>(
                      initialValue: _busStatus,
                      decoration: const InputDecoration(labelText: 'Initial Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active (Shaqeenaya)')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance (Cilad bixis)')),
                        DropdownMenuItem(value: 'out_of_service', child: Text('Out of Service')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            _busStatus = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: _addBus,
                  child: const Text('Register Bus'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addBus() async {
    final number = _busNumberCtrl.text.trim();
    final model = _busModelCtrl.text.trim();
    final capacity = int.tryParse(_busCapacityCtrl.text.trim()) ?? 40;

    if (number.isEmpty || model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields for the new bus'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(fleetRepositoryProvider).addBus({
        'bus_number': number,
        'model': model,
        'capacity': capacity,
        'status': _busStatus,
        'fuel_level': 100.0,
        'latitude': 2.0469,
        'longitude': 45.3182,
        'speed': 0.0,
        'passenger_count': 0,
      });

      _busNumberCtrl.clear();
      _busModelCtrl.clear();
      _busCapacityCtrl.text = '40';
      _busStatus = 'active';

      if (mounted) {
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus successfully registered in system!'), backgroundColor: AppColors.successGreen),
        );
      }
      await _loadAllAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register bus: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBus(String busNumber) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(fleetRepositoryProvider).deleteBus(busNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus successfully removed from fleet'), backgroundColor: AppColors.successGreen),
        );
      }
      await _loadAllAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete bus: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showViewBusDialog(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) {
        final lat = double.tryParse(bus['latitude'].toString()) ?? 2.0469;
        final lng = double.tryParse(bus['longitude'].toString()) ?? 45.3182;
        final fuel = bus['fuel_level'] ?? 100.0;
        final speed = bus['speed'] ?? 0.0;
        final pax = bus['passenger_count'] ?? 0;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.directions_bus_rounded, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(bus['bus_number'].toString()),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewRow('Model Name', bus['model'].toString()),
                _buildViewRow('Seating Capacity', '${bus['capacity']} Seats'),
                _buildViewRow('Active Status', bus['status'].toString().toUpperCase()),
                const Divider(),
                const Text('Real-time Telemetry (GPS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryBlue)),
                const SizedBox(height: 8),
                _buildViewRow('GPS Coordinates', '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'),
                _buildViewRow('Vehicle Speed', '$speed km/h'),
                _buildViewRow('Fuel Level', '$fuel %'),
                _buildViewRow('Passengers Onboard', '$pax Commuters'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showEditBusDialog(Map<String, dynamic> bus) {
    final busNo = bus['bus_number'].toString();
    _busModelCtrl.text = bus['model'].toString();
    _busCapacityCtrl.text = bus['capacity'].toString();
    _busStatus = bus['status'].toString();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Bus $busNo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Bus Model',
                      hintText: 'e.g. Toyota Coaster 2024',
                      controller: _busModelCtrl,
                      prefixIcon: Icons.directions_bus_rounded,
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Seat Capacity',
                      hintText: 'e.g. 40',
                      controller: _busCapacityCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.chair_rounded,
                    ),
                    AppSpacing.gapH16,
                    DropdownButtonFormField<String>(
                      initialValue: _busStatus,
                      decoration: const InputDecoration(labelText: 'Initial Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active (Shaqeenaya)')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance (Cilad bixis)')),
                        DropdownMenuItem(value: 'out_of_service', child: Text('Out of Service')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            _busStatus = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  onPressed: () => _updateBus(busNo),
                  child: const Text('Save Changes'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateBus(String busNumber) async {
    final model = _busModelCtrl.text.trim();
    final capacity = int.tryParse(_busCapacityCtrl.text.trim()) ?? 40;

    if (model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(fleetRepositoryProvider).updateBus(busNumber, {
        'model': model,
        'capacity': capacity,
        'status': _busStatus,
      });

      _busModelCtrl.clear();
      _busCapacityCtrl.text = '40';
      _busStatus = 'active';

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus successfully updated!'), backgroundColor: AppColors.successGreen),
        );
      }
      await _loadAllAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bus: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── MANAGE STAFF SECTION (Driver & Conductor) ─────────────────────────────
  Widget _buildManageStaffSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drivers =
        _managedStaff.where((s) => s['role'] == 'driver').toList();
    final conductors =
        _managedStaff.where((s) => s['role'] == 'conductor').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Staff', style: AppTypography.h1),
                  Text(
                    'Add and manage drivers and conductors for your company.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddStaffSheet,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add Staff'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.radiusMedium),
              ),
            ),
          ],
        ),
        AppSpacing.gapH16,

        // Security notice
        Container(
          padding: AppSpacing.pAll12,
          decoration: BoxDecoration(
            color: AppColors.warningOrange.withValues(alpha: 0.08),
            borderRadius: AppSpacing.radiusMedium,
            border: Border.all(
                color: AppColors.warningOrange.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_rounded,
                  color: AppColors.warningOrange, size: 18),
              AppSpacing.gapW12,
              Expanded(
                child: Text(
                  'Drivers iyo Conductors admin kaliya ayaa abuuraa. Signup ma oga. Passenger kaliya ayaa signup garanaya.',
                  style: TextStyle(color: AppColors.warningOrange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapH24,

        // Drivers section
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.12),
                borderRadius: AppSpacing.radiusSmall,
              ),
              child: Text(
                'DRIVERS (${drivers.length})',
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,
        if (drivers.isEmpty)
          _buildEmptyStaffCard('No drivers yet. Tap "Add Staff" to create one.',
              Icons.drive_eta_rounded, isDark)
        else
          ...drivers.map(
              (d) => _buildStaffCard(d, isDark, AppColors.successGreen)),

        AppSpacing.gapH24,

        // Conductors section
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withValues(alpha: 0.12),
                borderRadius: AppSpacing.radiusSmall,
              ),
              child: Text(
                'CONDUCTORS (${conductors.length})',
                style: const TextStyle(
                  color: AppColors.secondaryTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,
        if (conductors.isEmpty)
          _buildEmptyStaffCard(
              'No conductors yet. Tap "Add Staff" to create one.',
              Icons.badge_rounded,
              isDark)
        else
          ...conductors.map(
              (c) => _buildStaffCard(c, isDark, AppColors.secondaryTeal)),
      ],
    );
  }

  Widget _buildStaffCard(
      Map<String, dynamic> staff, bool isDark, Color color) {
    final role = staff['role'] as String? ?? 'driver';
    final icon =
        role == 'driver' ? Icons.drive_eta_rounded : Icons.badge_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: AppSpacing.pAll16,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppSpacing.radiusMedium,
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff['full_name'] as String? ?? '—',
                      style: AppTypography.subtitle),
                  Text(staff['email'] as String? ?? '—',
                      style: AppTypography.bodySmall),
                  Text(staff['phone_number'] as String? ?? '—',
                      style: AppTypography.bodySmall),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.12),
                borderRadius: AppSpacing.radiusSmall,
              ),
              child: Text(
                (staff['status'] as String? ?? 'active').toUpperCase(),
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.errorRed),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Tirtir Staff'),
                    content: Text(
                        'Ma hubtaa inaad tirtireyso "${staff['full_name']}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Maya'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.errorRed),
                        child: const Text('Haa, Tirtir'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(adminRepositoryProvider)
                      .deleteStaffMember(staff['id'] as String);
                  await _loadAllAdminData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStaffCard(String msg, IconData icon, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 36),
          AppSpacing.gapH8,
          Text(msg,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showAddStaffSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark =
              Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              borderRadius: AppSpacing.radiusXLarge,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue
                                .withValues(alpha: 0.12),
                            borderRadius: AppSpacing.radiusSmall,
                          ),
                          child: const Icon(Icons.person_add_rounded,
                              color: AppColors.primaryBlue, size: 20),
                        ),
                        AppSpacing.gapW12,
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Staff Member',
                                  style: AppTypography.h3),
                              Text(
                                  'Admin kaliya ayaa abuuri kara',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    AppSpacing.gapH20,

                    // Role selector
                    const Text('Role', style: AppTypography.label),
                    AppSpacing.gapH8,
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(
                                () => _staffRole = 'driver'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _staffRole == 'driver'
                                    ? AppColors.primaryBlue
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: AppSpacing.radiusMedium,
                                border: Border.all(
                                  color: _staffRole == 'driver'
                                      ? AppColors.primaryBlue
                                      : Colors.grey,
                                  width: _staffRole == 'driver' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.drive_eta_rounded,
                                      color: _staffRole == 'driver'
                                          ? AppColors.primaryBlue
                                          : Colors.grey,
                                      size: 20),
                                  AppSpacing.gapW8,
                                  Text(
                                    'Driver',
                                    style: TextStyle(
                                      color: _staffRole == 'driver'
                                          ? AppColors.primaryBlue
                                          : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(
                                () => _staffRole = 'conductor'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _staffRole == 'conductor'
                                    ? AppColors.secondaryTeal
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: AppSpacing.radiusMedium,
                                border: Border.all(
                                  color: _staffRole == 'conductor'
                                      ? AppColors.secondaryTeal
                                      : Colors.grey,
                                  width:
                                      _staffRole == 'conductor' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge_rounded,
                                      color: _staffRole == 'conductor'
                                          ? AppColors.secondaryTeal
                                          : Colors.grey,
                                      size: 20),
                                  AppSpacing.gapW8,
                                  Text(
                                    'Conductor',
                                    style: TextStyle(
                                      color: _staffRole == 'conductor'
                                          ? AppColors.secondaryTeal
                                          : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Full Name',
                      hintText: 'Magaca buuxa',
                      controller: _staffNameCtrl,
                      prefixIcon: Icons.person_outline,
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Email',
                      hintText: 'driver@company.so',
                      controller: _staffEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Phone Number',
                      hintText: '+252 61 xxxxxxx',
                      controller: _staffPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Temporary Password',
                      hintText: 'Password ku meel gaadh',
                      controller: _staffPasswordCtrl,
                      isPassword: true,
                      prefixIcon: Icons.lock_outlined,
                    ),
                    AppSpacing.gapH24,
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_staffNameCtrl.text.isEmpty ||
                              _staffEmailCtrl.text.isEmpty ||
                              _staffPasswordCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Buuxi dhammaan goobaha'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                            return;
                          }
                          final repo =
                              ref.read(adminRepositoryProvider);
                          await repo.createStaffMember({
                            'full_name': _staffNameCtrl.text.trim(),
                            'email': _staffEmailCtrl.text.trim(),
                            'phone_number':
                                _staffPhoneCtrl.text.trim(),
                            'password':
                                _staffPasswordCtrl.text.trim(),
                            'role': _staffRole,
                          });
                          _staffNameCtrl.clear();
                          _staffEmailCtrl.clear();
                          _staffPhoneCtrl.clear();
                          _staffPasswordCtrl.clear();
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadAllAdminData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${_staffRole == 'driver' ? 'Driver' : 'Conductor'} si guul ah ayaa loo abuuray ✓'),
                                backgroundColor:
                                    AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                            Icons.check_circle_outline_rounded),
                        label: Text(
                          'Create ${_staffRole == 'driver' ? 'Driver' : 'Conductor'} Account',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.radiusMedium),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


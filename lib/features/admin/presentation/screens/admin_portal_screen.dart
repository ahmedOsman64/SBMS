import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/text_fields.dart';
import '../../data/admin_repository.dart';

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
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
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
      _isLoading = false;
    });
  }

  Future<void> _triggerReportExport(String reportType, String format) async {
    setState(() => _isLoading = true);
    final filename = await ref.read(adminRepositoryProvider).exportReport(
      reportType: reportType,
      format: format,
    );
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully exported $filename to downloads!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _addCompany() async {
    if (_companyNameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
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
  }

  Future<void> _addCoupon() async {
    if (_couponCodeController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final discount = double.tryParse(_couponPercentController.text) ?? 10.0;

    await ref.read(adminRepositoryProvider).addCoupon({
      'code': _couponCodeController.text.trim().toUpperCase(),
      'discount_percent': discount,
      'valid_from': DateTime.now().toIso8601String(),
      'valid_to': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    });
    _couponCodeController.clear();
    _couponPercentController.clear();
    await _loadAllAdminData();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteCompany(String id) async {
    setState(() => _isLoading = true);
    await ref.read(adminRepositoryProvider).deleteCompany(id);
    await _loadAllAdminData();
  }

  Future<void> _deleteCoupon(String id) async {
    setState(() => _isLoading = true);
    await ref.read(adminRepositoryProvider).deleteCoupon(id);
    await _loadAllAdminData();
  }

  Future<void> _resolveTicket(String ticketId) async {
    setState(() => _isLoading = true);
    await ref.read(adminRepositoryProvider).updateTicketStatus(ticketId, 'resolved');
    await _loadAllAdminData();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header profile info
        Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ENTERPRISE CONTROL',
                style: AppTypography.label.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              AppSpacing.gapH4,
              const Text('Somali Smart Bus System', style: AppTypography.subtitle),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildSidebarTile(title: 'Overview Dashboard', section: 'dashboard', icon: Icons.dashboard_rounded, isDrawer: isDrawer),
              _buildSidebarTile(title: 'Manage Staff', section: 'manage_staff', icon: Icons.badge_rounded, isDrawer: isDrawer),
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
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryBlue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryBlue : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    );
  }

  // --- 1. OVERVIEW DASHBOARD & DYNAMIC CHARTS ---
  Widget _buildDashboardOverview() {
    final double totalRevenue = _payments.where((p) => p['status'] == 'completed').fold<double>(0.0, (sum, element) => sum + (double.tryParse(element['amount'].toString()) ?? 0.0));
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview Dashboard', style: AppTypography.h1),
                  Text('Live metrics, revenue performance analytics, and dynamic pricing updates', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _triggerReportExport('revenue_weekly', 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Export Weekly PDF'),
                  ),
                  AppSpacing.gapW12,
                  ElevatedButton.icon(
                    onPressed: () => _triggerReportExport('revenue_monthly', 'xlsx'),
                    icon: const Icon(Icons.table_view_rounded),
                    label: const Text('Export Excel'),
                  ),
                ],
              )
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview Dashboard', style: AppTypography.h1),
              const Text('Live metrics, revenue performance analytics, and dynamic pricing updates', style: TextStyle(color: Colors.grey)),
              AppSpacing.gapH16,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _triggerReportExport('revenue_weekly', 'pdf'),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Export PDF'),
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _triggerReportExport('revenue_monthly', 'xlsx'),
                      icon: const Icon(Icons.table_view_rounded),
                      label: const Text('Export Excel'),
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
    return Card(
      child: Padding(
        padding: AppSpacing.pAll24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Revenue Trends (AI Estimated Demand)', style: AppTypography.subtitle),
            AppSpacing.gapH24,
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
      ),
    );
  }

  Widget _buildRouteDensitiesCard() {
    return Card(
      child: Padding(
        padding: AppSpacing.pAll24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route Densities Heatmap Load', style: AppTypography.subtitle),
            AppSpacing.gapH20,
            _buildRouteLoadBar(route: 'Mogadishu ➔ Garowe', density: 0.92, label: '92% (High demand modifier)'),
            _buildRouteLoadBar(route: 'Hargeisa ➔ Burao', density: 0.55, label: '55% (Mid load factor)'),
            _buildRouteLoadBar(route: 'Mogadishu ➔ Kismayo', density: 0.78, label: '78% (Peak weekend traffic)'),
          ],
        ),
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

  Widget _buildStatCard({required String title, required String value, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              AppSpacing.gapW8,
              Expanded(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.end,
                  style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          Text(value, style: AppTypography.h1.copyWith(fontWeight: FontWeight.bold)),
          AppSpacing.gapH4,
          Text(title, style: AppTypography.subtitle),
        ],
      ),
    );
  }

  Widget _buildChartBar({required String label, required double heightPercent, required String val, Color? color}) {
    return Column(
      children: [
        Text(val, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
        AppSpacing.gapH8,
        Container(
          width: 30,
          height: 150 * heightPercent,
          decoration: BoxDecoration(
            color: color ?? AppColors.primaryBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        AppSpacing.gapH8,
        Text(label),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(route, style: AppTypography.bodyMedium),
          AppSpacing.gapH8,
          LinearProgressIndicator(
            value: density,
            color: density > 0.85 ? AppColors.errorRed : AppColors.primaryBlue,
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
          ),
          AppSpacing.gapH4,
          Text(label, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
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


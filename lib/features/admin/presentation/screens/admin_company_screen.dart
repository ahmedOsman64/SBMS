import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/glass_container.dart';
import '../../../../core/shared/widgets/text_fields.dart';
import '../../data/admin_repository.dart';

class AdminCompanyScreen extends ConsumerStatefulWidget {
  const AdminCompanyScreen({super.key});

  @override
  ConsumerState<AdminCompanyScreen> createState() => _AdminCompanyScreenState();
}

class _AdminCompanyScreenState extends ConsumerState<AdminCompanyScreen> {
  String _selectedSection = 'dashboard';
  bool _isLoading = false;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _coupons = [];
  List<Map<String, dynamic>> _trips = [];

  String get _companyId => 'c-1';
  String get _companyName => 'Soomaal Transit Corp';

  final _couponCodeController = TextEditingController();
  final _couponDiscountController = TextEditingController(text: '10');
  final _couponFromController = TextEditingController();
  final _couponToController = TextEditingController();

  String _staffFilter = 'all';
  String _staffSearch = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    _couponDiscountController.dispose();
    _couponFromController.dispose();
    _couponToController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final repo = ref.read(adminRepositoryProvider);
    final results = await Future.wait([
      repo.getCompanyStats(_companyId),
      repo.getCompanyBranches(_companyId),
      repo.getCompanyStaff(_companyId),
      repo.getCompanyCoupons(_companyId),
      repo.getCompanyTrips(_companyId),
    ]);
    setState(() {
      _stats = results[0] as Map<String, dynamic>;
      _branches = results[1] as List<Map<String, dynamic>>;
      _staff = results[2] as List<Map<String, dynamic>>;
      _coupons = results[3] as List<Map<String, dynamic>>;
      _trips = results[4] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  Future<void> _addCoupon() async {
    if (_couponCodeController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final discount = double.tryParse(_couponDiscountController.text) ?? 10.0;
    await ref.read(adminRepositoryProvider).addCompanyCoupon(_companyId, {
      'code': _couponCodeController.text.trim().toUpperCase(),
      'discount_percent': discount,
      'valid_from': _couponFromController.text.trim().isEmpty
          ? DateTime.now().toIso8601String().substring(0, 10)
          : _couponFromController.text.trim(),
      'valid_to': _couponToController.text.trim().isEmpty
          ? DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10)
          : _couponToController.text.trim(),
      'usage_limit': 100,
    });
    _couponCodeController.clear();
    _couponDiscountController.text = '10';
    _couponFromController.clear();
    _couponToController.clear();
    if (mounted) Navigator.of(context).pop();
    await _loadAll();
  }

  Future<void> _deactivateCoupon(String id) async {
    setState(() => _isLoading = true);
    await ref.read(adminRepositoryProvider).deactivateCoupon(id);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    Widget content;
    switch (_selectedSection) {
      case 'branches': content = _buildBranchesSection(isDark); break;
      case 'staff':    content = _buildStaffSection(isDark); break;
      case 'coupons':  content = _buildCouponsSection(isDark); break;
      case 'trips':    content = _buildTripsSection(isDark); break;
      default:         content = _buildDashboard(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.domain_rounded, color: Colors.white, size: 20),
          ),
          AppSpacing.gapW12,
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_companyName, style: AppTypography.subtitle.copyWith(color: isDark ? Colors.white : AppColors.lightTextPrimary)),
            Text('Company Manager Portal', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
        leading: !isDesktop
            ? Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(ctx).openDrawer()))
            : null,
      ),
      drawer: !isDesktop ? Drawer(child: _buildSidebar(isDark, isDrawer: true)) : null,
      body: Row(children: [
        if (isDesktop)
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(right: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: _buildSidebar(isDark, isDrawer: false),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: content)),
        ),
      ]),
    );
  }

  // ── SIDEBAR ──

  Widget _buildSidebar(bool isDark, {required bool isDrawer}) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue.withValues(alpha: 0.15), AppColors.primaryBlue.withValues(alpha: 0.03)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.domain_rounded, color: Colors.white, size: 22),
            ),
            AppSpacing.gapW12,
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_companyName, style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryBlue), maxLines: 2),
              Text('Company Portal', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
            ])),
          ]),
          AppSpacing.gapH16,
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _miniStat('${_stats['branch_count'] ?? 0}', 'Branches'),
            _miniStat('${(_stats['driver_count'] ?? 0) + (_stats['conductor_count'] ?? 0)}', 'Staff'),
            _miniStat('${_stats['active_trips_today'] ?? 0}', 'Active'),
          ]),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _navItem('dashboard', 'Company Dashboard', Icons.dashboard_rounded, isDark, isDrawer),
            _navItem('branches', 'My Branches', Icons.location_city_rounded, isDark, isDrawer, badge: '${_branches.length}'),
            _navItem('staff', 'Staff Directory', Icons.badge_rounded, isDark, isDrawer, badge: '${_staff.length}'),
            _navItem('coupons', 'Promotions & Coupons', Icons.local_offer_rounded, isDark, isDrawer, badge: '${_coupons.length}'),
            _navItem('trips', 'Trip Reports', Icons.route_rounded, isDark, isDrawer, badge: '${_trips.length}'),
          ],
        ),
      ),
    ]);
  }

  Widget _miniStat(String v, String l) => Column(children: [
    Text(v, style: AppTypography.subtitle.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
    Text(l, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
  ]);

  Widget _navItem(String section, String label, IconData icon, bool isDark, bool isDrawer, {String? badge}) {
    final sel = _selectedSection == section;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: sel ? BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryBlue.withValues(alpha: 0.15), AppColors.primaryBlue.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(10),
      ) : null,
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: sel ? AppColors.primaryBlue.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: sel ? AppColors.primaryBlue : Colors.grey),
        ),
        title: Text(label, style: AppTypography.label.copyWith(
          color: sel ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
        )),
        trailing: badge != null ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: sel ? AppColors.primaryBlue : Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
          child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.grey)),
        ) : null,
        onTap: () {
          setState(() => _selectedSection = section);
          if (isDrawer) Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── DASHBOARD ──

  Widget _buildDashboard(bool isDark) {
    final rev = _stats['total_revenue_month'] as double? ?? 0.0;
    final isWide = MediaQuery.of(context).size.width > 1100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Company Dashboard', style: AppTypography.h2),
          Text('Real-time overview — $_companyName', style: AppTypography.bodyMedium.copyWith(color: Colors.grey)),
        ]),
        _statusBadge('Operational', AppColors.successGreen),
      ]),
      AppSpacing.gapH24,
      if (isWide)
        Row(children: [
          Expanded(child: _statCard('Monthly Revenue', '\$${rev.toStringAsFixed(2)}', 'Completed payments', Icons.payments_rounded, AppColors.successGreen, isDark)),
          AppSpacing.gapW16,
          Expanded(child: _statCard('Active Buses', '${_stats['active_buses'] ?? 0}', 'On the road', Icons.directions_bus_rounded, AppColors.primaryBlue, isDark)),
          AppSpacing.gapW16,
          Expanded(child: _statCard('Trips Today', '${_stats['active_trips_today'] ?? 0}', 'Running', Icons.route_rounded, AppColors.accentGold, isDark)),
          AppSpacing.gapW16,
          Expanded(child: _statCard('Avg Occupancy', '${_stats['avg_occupancy'] ?? 0}%', 'Fill rate', Icons.people_alt_rounded, AppColors.secondaryTeal, isDark)),
        ])
      else
        Column(children: [
          Row(children: [
            Expanded(child: _statCard('Revenue', '\$${rev.toStringAsFixed(0)}', 'Month', Icons.payments_rounded, AppColors.successGreen, isDark)),
            AppSpacing.gapW12,
            Expanded(child: _statCard('Buses', '${_stats['active_buses'] ?? 0}', 'Active', Icons.directions_bus_rounded, AppColors.primaryBlue, isDark)),
          ]),
          AppSpacing.gapH12,
          Row(children: [
            Expanded(child: _statCard('Trips', '${_stats['active_trips_today'] ?? 0}', 'Today', Icons.route_rounded, AppColors.accentGold, isDark)),
            AppSpacing.gapW12,
            Expanded(child: _statCard('Occupancy', '${_stats['avg_occupancy'] ?? 0}%', 'Fill', Icons.people_alt_rounded, AppColors.secondaryTeal, isDark)),
          ]),
        ]),
      AppSpacing.gapH24,
      if (isWide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: _todayTripsCard(isDark)),
          AppSpacing.gapW20,
          Expanded(child: _staffSummaryCard(isDark)),
        ])
      else
        Column(children: [_todayTripsCard(isDark), AppSpacing.gapH16, _staffSummaryCard(isDark)]),
      AppSpacing.gapH20,
      _branchSummaryCard(isDark),
    ]);
  }

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      AppSpacing.gapW8,
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );

  Widget _statCard(String title, String value, String sub, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
          Text(sub, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
        ]),
        AppSpacing.gapH16,
        Text(value, style: AppTypography.h2.copyWith(color: color, fontWeight: FontWeight.bold)),
        AppSpacing.gapH4,
        Text(title, style: AppTypography.label.copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ]),
    );
  }

  Widget _todayTripsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: AppSpacing.radiusMedium, border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Today's Trips", style: AppTypography.subtitle),
          TextButton(onPressed: () => setState(() => _selectedSection = 'trips'), child: const Text('View All')),
        ]),
        AppSpacing.gapH12,
        ..._trips.take(4).map((t) => _compactTripRow(t, isDark)),
      ]),
    );
  }

  Widget _compactTripRow(Map<String, dynamic> trip, bool isDark) {
    final status = trip['status'] as String? ?? 'scheduled';
    final booked = trip['booked_seats'] as int? ?? 0;
    final total = trip['total_seats'] as int? ?? 40;
    Color sc;
    switch (status) {
      case 'completed': sc = AppColors.successGreen; break;
      case 'en_route':  sc = AppColors.primaryBlue; break;
      case 'delayed':   sc = AppColors.warningOrange; break;
      default:          sc = Colors.grey;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground.withValues(alpha: 0.5) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(width: 4, height: 40, decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(2))),
        AppSpacing.gapW12,
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(trip['route'] ?? '', style: AppTypography.label),
          AppSpacing.gapH4,
          Text('Bus: ${trip['bus_number']} • ${trip['departure_time']} • ${trip['driver_name']}', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          AppSpacing.gapH4,
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: total > 0 ? booked / total : 0, backgroundColor: Colors.grey.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation<Color>(sc), minHeight: 4))),
            AppSpacing.gapW8,
            Text('$booked/$total', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          ]),
        ])),
        AppSpacing.gapW12,
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: sc, fontSize: 9, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _staffSummaryCard(bool isDark) {
    final drivers = _staff.where((s) => s['role'] == 'driver').length;
    final conductors = _staff.where((s) => s['role'] == 'conductor').length;
    final onDuty = _staff.where((s) => s['status'] == 'on_duty').length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: AppSpacing.radiusMedium, border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Staff Overview', style: AppTypography.subtitle),
          TextButton(onPressed: () => setState(() => _selectedSection = 'staff'), child: const Text('View All')),
        ]),
        AppSpacing.gapH16,
        _staffRow('Drivers', drivers, AppColors.primaryBlue, Icons.drive_eta_rounded),
        AppSpacing.gapH8,
        _staffRow('Conductors', conductors, AppColors.secondaryTeal, Icons.badge_rounded),
        AppSpacing.gapH8,
        _staffRow('On Duty Now', onDuty, AppColors.successGreen, Icons.check_circle_outline_rounded),
      ]),
    );
  }

  Widget _staffRow(String label, int count, Color color, IconData icon) => Row(children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
    AppSpacing.gapW12,
    Expanded(child: Text(label, style: AppTypography.bodyMedium)),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
  ]);

  Widget _branchSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: AppSpacing.radiusMedium, border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Branch Network', style: AppTypography.subtitle),
          TextButton(onPressed: () => setState(() => _selectedSection = 'branches'), child: const Text('View All')),
        ]),
        AppSpacing.gapH12,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _branches.take(3).map((b) {
            final active = b['status'] == 'active';
            return Container(
              width: 180, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? AppColors.successGreen.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.location_city_rounded, size: 13, color: active ? AppColors.successGreen : Colors.grey),
                  AppSpacing.gapW4,
                  Expanded(child: Text(b['city'] ?? '', style: AppTypography.label.copyWith(color: active ? AppColors.successGreen : Colors.grey))),
                ]),
                AppSpacing.gapH4,
                Text(b['name'] ?? '', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 2),
                AppSpacing.gapH4,
                Text('${b['buses_count'] ?? 0} buses', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
              ]),
            );
          }).toList()),
        ),
      ]),
    );
  }

  // ── BRANCHES ──

  Widget _buildBranchesSection(bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('My Branches', 'Manage branch offices across all regions', Icons.location_city_rounded, AppColors.primaryBlue),
      AppSpacing.gapH24,
      ..._branches.map((b) => _branchCard(b, isDark)),
    ],
  );

  Widget _branchCard(Map<String, dynamic> b, bool isDark) {
    final active = b['status'] == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(color: active ? AppColors.successGreen.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.radiusMedium,
        child: Column(children: [
          Container(height: 4, decoration: BoxDecoration(gradient: active ? const LinearGradient(colors: [AppColors.successGreen, AppColors.secondaryTeal]) : LinearGradient(colors: [Colors.grey.withValues(alpha: 0.4), Colors.grey.withValues(alpha: 0.2)]))),
          Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: active ? AppColors.successGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.location_city_rounded, color: active ? AppColors.successGreen : Colors.grey, size: 26)),
              AppSpacing.gapW16,
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(b['name'] ?? '', style: AppTypography.subtitle)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: active ? AppColors.successGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text((b['status'] ?? '').toString().toUpperCase(), style: TextStyle(color: active ? AppColors.successGreen : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
                ]),
                AppSpacing.gapH4,
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: Colors.grey), AppSpacing.gapW4,
                  Text(b['city'] ?? '', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
                  AppSpacing.gapW12,
                  Text('Code: ${b['code'] ?? ''}', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
                ]),
              ])),
            ]),
            AppSpacing.gapH16,
            const Divider(height: 1),
            AppSpacing.gapH12,
            Row(children: [
              _branchInfo(Icons.person_rounded, 'Manager', b['manager_name'] ?? 'N/A'),
              _branchInfo(Icons.phone_rounded, 'Contact', b['contact_phone'] ?? 'N/A'),
              _branchInfo(Icons.directions_bus_rounded, 'Buses', '${b['buses_count'] ?? 0}'),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _branchInfo(IconData icon, String label, String value) => Expanded(
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.primaryBlue), AppSpacing.gapW4,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: Colors.grey, fontSize: 10)),
        Text(value, style: AppTypography.label),
      ]),
    ]),
  );

  // ── STAFF ──

  Widget _buildStaffSection(bool isDark) {
    final filtered = _staff.where((s) {
      final roleOk = _staffFilter == 'all' || s['role'] == _staffFilter;
      final searchOk = _staffSearch.isEmpty || (s['full_name'] as String? ?? '').toLowerCase().contains(_staffSearch.toLowerCase()) || (s['branch'] as String? ?? '').toLowerCase().contains(_staffSearch.toLowerCase());
      return roleOk && searchOk;
    }).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Staff Directory', 'Drivers and conductors under your company', Icons.badge_rounded, AppColors.secondaryTeal),
      AppSpacing.gapH20,
      Wrap(spacing: 8, runSpacing: 8, children: [
        ...['all', 'driver', 'conductor'].map((f) => ChoiceChip(
          label: Text(f == 'all' ? 'All Staff' : '${f[0].toUpperCase()}${f.substring(1)}s'),
          selected: _staffFilter == f,
          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: _staffFilter == f ? AppColors.primaryBlue : Colors.grey, fontWeight: _staffFilter == f ? FontWeight.bold : FontWeight.normal),
          onSelected: (_) => setState(() => _staffFilter = f),
        )),
        SizedBox(width: 260, child: TextField(
          decoration: InputDecoration(
            hintText: 'Search staff...', prefixIcon: const Icon(Icons.search_rounded, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          onChanged: (v) => setState(() => _staffSearch = v),
        )),
      ]),
      AppSpacing.gapH16,
      ...filtered.map((s) => _staffCard(s, isDark)),
      if (filtered.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
          AppSpacing.gapH12,
          const Text('No staff found', style: AppTypography.subtitle),
        ]))),
    ]);
  }

  Widget _staffCard(Map<String, dynamic> s, bool isDark) {
    final role = s['role'] as String? ?? 'staff';
    final status = s['status'] as String? ?? 'unknown';
    final isDriver = role == 'driver';
    Color sc; IconData si;
    switch (status) {
      case 'on_duty':   sc = AppColors.successGreen; si = Icons.check_circle_rounded; break;
      case 'available': sc = AppColors.primaryBlue;  si = Icons.radio_button_on_rounded; break;
      default:          sc = Colors.grey;             si = Icons.remove_circle_outline_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: AppSpacing.radiusMedium, border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isDriver ? [AppColors.primaryBlue.withValues(alpha: 0.8), AppColors.primaryBlue.withValues(alpha: 0.4)] : [AppColors.secondaryTeal.withValues(alpha: 0.8), AppColors.secondaryTeal.withValues(alpha: 0.4)]),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text((s['full_name'] as String? ?? 'S')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
        ),
        AppSpacing.gapW12,
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(s['full_name'] ?? '', style: AppTypography.subtitle), AppSpacing.gapW8,
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isDriver ? AppColors.primaryBlue : AppColors.secondaryTeal).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(role.toUpperCase(), style: TextStyle(color: isDriver ? AppColors.primaryBlue : AppColors.secondaryTeal, fontSize: 9, fontWeight: FontWeight.bold))),
          ]),
          AppSpacing.gapH4,
          Row(children: [
            const Icon(Icons.location_city_rounded, size: 12, color: Colors.grey), AppSpacing.gapW4,
            Text(s['branch'] ?? '', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
            AppSpacing.gapW12,
            const Icon(Icons.check_box_rounded, size: 12, color: Colors.grey), AppSpacing.gapW4,
            Text('${s['trips_completed'] ?? 0} trips', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          ]),
          AppSpacing.gapH4,
          Text(s['phone_number'] ?? '', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
        ])),
        Column(children: [
          Icon(si, color: sc, size: 22), AppSpacing.gapH4,
          Text(status.replaceAll('_', ' '), style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  // ── COUPONS ──

  Widget _buildCouponsSection(bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _sectionHeader('Promotions & Coupons', 'Manage discount campaigns for passengers', Icons.local_offer_rounded, AppColors.accentGold),
        ElevatedButton.icon(
          onPressed: _showAddCouponDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Coupon'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.white),
        ),
      ]),
      AppSpacing.gapH24,
      ..._coupons.map((c) => _couponCard(c, isDark)),
      if (_coupons.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
          Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
          AppSpacing.gapH12,
          const Text('No coupons yet', style: AppTypography.subtitle),
          AppSpacing.gapH12,
          ElevatedButton(onPressed: _showAddCouponDialog, child: const Text('Create First Coupon')),
        ]))),
    ],
  );

  Widget _couponCard(Map<String, dynamic> c, bool isDark) {
    final active = c['is_active'] as bool? ?? false;
    final used = c['used_count'] as int? ?? 0;
    final limit = c['usage_limit'] as int? ?? 100;
    final ratio = limit > 0 ? used / limit : 0.0;
    final discount = (c['discount_percent'] as num? ?? 0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(color: active ? AppColors.accentGold.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.radiusMedium,
        child: Column(children: [
          Container(height: 4, decoration: BoxDecoration(gradient: active ? AppColors.goldGradient : LinearGradient(colors: [Colors.grey.withValues(alpha: 0.3), Colors.grey.withValues(alpha: 0.1)]))),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(gradient: active ? AppColors.goldGradient : null, color: active ? null : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(c['code'] ?? '', style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              ),
              AppSpacing.gapW16,
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${discount.toStringAsFixed(0)}% Discount', style: AppTypography.subtitle.copyWith(color: AppColors.accentGold)),
                Text('Valid: ${c['valid_from']} to ${c['valid_to']}', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
              ])),
              if (active)
                TextButton.icon(
                  onPressed: () => _deactivateCoupon(c['id']),
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 16),
                  label: const Text('Deactivate'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                )
              else
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Text('INACTIVE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
            AppSpacing.gapH12,
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Usage: $used / $limit', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
                  Text('${(ratio * 100).toStringAsFixed(0)}%', style: AppTypography.bodySmall.copyWith(color: AppColors.accentGold)),
                ]),
                AppSpacing.gapH4,
                ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: ratio, backgroundColor: Colors.grey.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation<Color>(ratio > 0.9 ? AppColors.errorRed : AppColors.accentGold), minHeight: 6)),
              ])),
            ]),
          ])),
        ]),
      ),
    );
  }

  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.local_offer_rounded, color: AppColors.accentGold, size: 20)),
          AppSpacing.gapW12,
          const Text('New Coupon', style: AppTypography.subtitle),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(label: 'Coupon Code', hintText: 'e.g. SOOMAAL20', controller: _couponCodeController, prefixIcon: Icons.local_offer_rounded),
            AppSpacing.gapH12,
            AppTextField(label: 'Discount %', hintText: 'e.g. 15', controller: _couponDiscountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefixIcon: Icons.percent_rounded),
            AppSpacing.gapH12,
            Row(children: [
              Expanded(child: AppTextField(label: 'Valid From', hintText: '2026-07-15', controller: _couponFromController, prefixIcon: Icons.calendar_today_rounded)),
              AppSpacing.gapW8,
              Expanded(child: AppTextField(label: 'Valid To', hintText: '2026-08-15', controller: _couponToController, prefixIcon: Icons.event_rounded)),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addCoupon, style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.white), child: const Text('Create Coupon')),
        ],
      ),
    );
  }

  // ── TRIPS ──

  Widget _buildTripsSection(bool isDark) {
    final totalRev = _trips.fold<double>(0, (s, t) => s + ((t['revenue'] as num?)?.toDouble() ?? 0.0));
    final completed = _trips.where((t) => t['status'] == 'completed').length;
    final avgPass = _trips.isEmpty ? 0 : (_trips.fold<int>(0, (s, t) => s + (t['booked_seats'] as int? ?? 0)) / _trips.length).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader("Trip Reports", "Today's route performance and revenue", Icons.route_rounded, AppColors.secondaryTeal),
      AppSpacing.gapH20,
      Row(children: [
        Expanded(child: GlassContainer(child: Column(children: [
          Text('\$${totalRev.toStringAsFixed(2)}', style: AppTypography.h3.copyWith(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
          AppSpacing.gapH4,
          Text('Total Revenue Today', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
        ]))),
        AppSpacing.gapW12,
        Expanded(child: GlassContainer(child: Column(children: [
          Text('$completed/${_trips.length}', style: AppTypography.h3.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          AppSpacing.gapH4,
          Text('Trips Completed', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
        ]))),
        AppSpacing.gapW12,
        Expanded(child: GlassContainer(child: Column(children: [
          Text('$avgPass', style: AppTypography.h3.copyWith(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
          AppSpacing.gapH4,
          Text('Avg Passengers/Trip', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
        ]))),
      ]),
      AppSpacing.gapH24,
      ..._trips.map((t) => _tripDetailCard(t, isDark)),
    ]);
  }

  Widget _tripDetailCard(Map<String, dynamic> trip, bool isDark) {
    final status = trip['status'] as String? ?? 'scheduled';
    final booked = trip['booked_seats'] as int? ?? 0;
    final total = trip['total_seats'] as int? ?? 40;
    final revenue = (trip['revenue'] as num?)?.toDouble() ?? 0.0;
    Color sc; IconData si;
    switch (status) {
      case 'completed': sc = AppColors.successGreen; si = Icons.check_circle_rounded; break;
      case 'en_route':  sc = AppColors.primaryBlue;  si = Icons.directions_bus_rounded; break;
      case 'delayed':   sc = AppColors.warningOrange; si = Icons.warning_rounded; break;
      default:          sc = Colors.grey;             si = Icons.schedule_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: AppSpacing.radiusMedium, border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(si, color: sc, size: 22)),
          AppSpacing.gapW12,
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip['route'] ?? '', style: AppTypography.subtitle),
            AppSpacing.gapH4,
            Text('Dep: ${trip['departure_time']} Bus: ${trip['bus_number']} Driver: ${trip['driver_name']}', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${revenue.toStringAsFixed(2)}', style: AppTypography.subtitle.copyWith(color: AppColors.successGreen)),
            Text('revenue', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          ]),
        ]),
        AppSpacing.gapH12,
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Occupancy: $booked/$total', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
              Text('${total > 0 ? (booked / total * 100).toStringAsFixed(0) : 0}%', style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            AppSpacing.gapH4,
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: total > 0 ? booked / total : 0, backgroundColor: Colors.grey.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation<Color>(sc), minHeight: 6)),
          ])),
          AppSpacing.gapW16,
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
      ]),
    );
  }

  // ── HELPERS ──

  Widget _sectionHeader(String title, String subtitle, IconData icon, Color color) => Row(children: [
    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
    AppSpacing.gapW12,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTypography.h3),
      Text(subtitle, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
    ]),
  ]);
}


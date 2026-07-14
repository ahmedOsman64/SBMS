import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/text_fields.dart';
import '../../data/admin_repository.dart';

class SuperAdminPortalScreen extends ConsumerStatefulWidget {
  const SuperAdminPortalScreen({super.key});

  @override
  ConsumerState<SuperAdminPortalScreen> createState() =>
      _SuperAdminPortalScreenState();
}

class _SuperAdminPortalScreenState
    extends ConsumerState<SuperAdminPortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  Map<String, dynamic> _platformStats = {};
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _companies = [];

  // Form controllers for "Add Admin"
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPhoneCtrl = TextEditingController();
  final _adminCompanyCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _adminCompanyCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(adminRepositoryProvider);
    final stats = await repo.getPlatformStats();
    final admins = await repo.getAdmins();
    final companies = await repo.getCompanies();
    setState(() {
      _platformStats = stats;
      _admins = admins;
      _companies = companies;
      _isLoading = false;
    });
  }

  Future<void> _createAdmin() async {
    if (_adminNameCtrl.text.isEmpty ||
        _adminEmailCtrl.text.isEmpty ||
        _adminPasswordCtrl.text.isEmpty) {
      _showSnack('Buuxi dhammaan goobaha muhiimka ah', isError: true);
      return;
    }
    final repo = ref.read(adminRepositoryProvider);
    try {
      await repo.createAdmin({
        'full_name': _adminNameCtrl.text.trim(),
        'email': _adminEmailCtrl.text.trim(),
        'phone_number': _adminPhoneCtrl.text.trim(),
        'company_name': _adminCompanyCtrl.text.trim(),
        'password': _adminPasswordCtrl.text.trim(),
        'role': 'admin',
      });
      _adminNameCtrl.clear();
      _adminEmailCtrl.clear();
      _adminPhoneCtrl.clear();
      _adminCompanyCtrl.clear();
      _adminPasswordCtrl.clear();
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('Admin si guul ah ayaa loo abuuray ✓');
      await _loadData();
    } catch (e) {
      _showSnack('Khalad: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteAdmin(String adminId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tirtir Admin'),
        content: Text('Ma hubtaa inaad tirtireyso "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maya'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Haa, Tirtir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteAdmin(adminId);
      _showSnack('Admin waa la tirtiray');
      await _loadData();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMedium),
      ),
    );
  }

  void _showAddAdminSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAdminSheet(
        nameCtrl: _adminNameCtrl,
        emailCtrl: _adminEmailCtrl,
        phoneCtrl: _adminPhoneCtrl,
        companyCtrl: _adminCompanyCtrl,
        passwordCtrl: _adminPasswordCtrl,
        onSubmit: _createAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B0F19), Color(0xFF1E1B4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: AppSpacing.pAll24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: AppSpacing.radiusSmall,
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            AppSpacing.gapW12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Super Admin Portal',
                                    style: AppTypography.h3.copyWith(
                                        color: Colors.white),
                                  ),
                                  Text(
                                    user?.fullName ?? 'System Owner',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded,
                                  color: Colors.white70),
                              onPressed: () async {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .signOut();
                                if (context.mounted) context.go('/login');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryBlue,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
                Tab(icon: Icon(Icons.manage_accounts_rounded), text: 'Admins'),
                Tab(icon: Icon(Icons.business_rounded), text: 'Companies'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _DashboardTab(stats: _platformStats),
                  _AdminsTab(
                    admins: _admins,
                    onAddAdmin: _showAddAdminSheet,
                    onDeleteAdmin: _deleteAdmin,
                  ),
                  _CompaniesTab(companies: _companies),
                ],
              ),
      ),
    );
  }
}

// ─── DASHBOARD TAB ───────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _DashboardTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: AppSpacing.pAll16,
        children: [
          AppSpacing.gapH8,
          const Text('Platform Overview', style: AppTypography.h3),
          AppSpacing.gapH16,
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              _StatCard(
                label: 'Companies',
                value: '${stats['total_companies'] ?? 0}',
                icon: Icons.business_rounded,
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              _StatCard(
                label: 'Admins',
                value: '${stats['total_admins'] ?? 0}',
                icon: Icons.manage_accounts_rounded,
                color: AppColors.accentGold,
                isDark: isDark,
              ),
              _StatCard(
                label: 'Drivers',
                value: '${stats['total_drivers'] ?? 0}',
                icon: Icons.drive_eta_rounded,
                color: AppColors.successGreen,
                isDark: isDark,
              ),
              _StatCard(
                label: 'Conductors',
                value: '${stats['total_conductors'] ?? 0}',
                icon: Icons.badge_rounded,
                color: AppColors.secondaryTeal,
                isDark: isDark,
              ),
              _StatCard(
                label: 'Passengers',
                value: '${stats['total_passengers'] ?? 0}',
                icon: Icons.people_alt_rounded,
                color: AppColors.primaryBlue,
                isDark: isDark,
              ),
              _StatCard(
                label: 'Today\'s Trips',
                value: '${stats['active_trips_today'] ?? 0}',
                icon: Icons.directions_bus_filled_rounded,
                color: AppColors.warningOrange,
                isDark: isDark,
              ),
            ],
          ),
          AppSpacing.gapH16,
          _RevenueCard(
            revenue: (stats['total_revenue_month'] as num?)?.toDouble() ?? 0,
            bookings: stats['total_bookings_month'] ?? 0,
            isDark: isDark,
          ),
          AppSpacing.gapH24,
          // Role legend
          Container(
            padding: AppSpacing.pAll16,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppSpacing.radiusMedium,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded,
                        color: AppColors.primaryBlue, size: 18),
                    AppSpacing.gapW8,
                    Text('Hierarchy Access Levels', style: AppTypography.subtitle),
                  ],
                ),
                AppSpacing.gapH12,
                _RoleLegendRow(
                    role: 'SuperAdmin',
                    desc: 'Nidaamka wuu leeyahay — Admin abuuraa',
                    color: Color(0xFF6366F1)),
                _RoleLegendRow(
                    role: 'Admin',
                    desc: 'Ganacsi maamulaa — Driver & Conductor abuuraa',
                    color: AppColors.accentGold),
                _RoleLegendRow(
                    role: 'Driver / Conductor',
                    desc: 'Admin ayaa abuuraa — signup ma garanayaan',
                    color: AppColors.successGreen),
                _RoleLegendRow(
                    role: 'Passenger',
                    desc: 'Nafsadooda ayaa signup garanaya',
                    color: AppColors.primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.pAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTypography.h2.copyWith(color: color, fontSize: 26)),
              Text(label, style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double revenue;
  final int bookings;
  final bool isDark;

  const _RevenueCard(
      {required this.revenue, required this.bookings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.pAll20,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00ADEF), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.radiusLarge,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Revenue',
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white70)),
                Text('\$${revenue.toStringAsFixed(0)}',
                    style: AppTypography.h1
                        .copyWith(color: Colors.white, fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.confirmation_number_rounded,
                  color: Colors.white70, size: 20),
              Text('$bookings', style: AppTypography.h3.copyWith(color: Colors.white)),
              Text('Bookings', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleLegendRow extends StatelessWidget {
  final String role;
  final String desc;
  final Color color;
  const _RoleLegendRow(
      {required this.role, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.gapW12,
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$role  ',
                    style: AppTypography.label
                        .copyWith(color: color, fontSize: 12),
                  ),
                  TextSpan(
                    text: desc,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADMINS TAB ───────────────────────────────────────────────────────────────
class _AdminsTab extends StatelessWidget {
  final List<Map<String, dynamic>> admins;
  final VoidCallback onAddAdmin;
  final Function(String, String) onDeleteAdmin;

  const _AdminsTab({
    required this.admins,
    required this.onAddAdmin,
    required this.onDeleteAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                  child: Text('System Admins (${admins.length})',
                      style: AppTypography.h3)),
              ElevatedButton.icon(
                onPressed: onAddAdmin,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.radiusMedium),
                ),
              ),
            ],
          ),
        ),
        // Security note
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningOrange.withValues(alpha: 0.08),
              borderRadius: AppSpacing.radiusSmall,
              border: Border.all(
                  color: AppColors.warningOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppColors.warningOrange, size: 16),
                AppSpacing.gapW8,
                Expanded(
                  child: Text(
                    'Admin accounts waxaa abuuraa SuperAdmin kaliya. Signup ma jirto.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.warningOrange),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: admins.isEmpty
              ? const Center(child: Text('Admin ma jiro weli'))
              : ListView.separated(
                  padding: AppSpacing.pAll16,
                  itemCount: admins.length,
                  separatorBuilder: (_, __) => AppSpacing.gapH12,
                  itemBuilder: (ctx, i) {
                    final admin = admins[i];
                    return _AdminCard(
                      admin: admin,
                      isDark: isDark,
                      onDelete: () => onDeleteAdmin(
                          admin['id'] as String,
                          admin['full_name'] as String? ?? 'Admin'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Map<String, dynamic> admin;
  final bool isDark;
  final VoidCallback onDelete;

  const _AdminCard(
      {required this.admin, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.accentGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.manage_accounts_rounded,
                color: AppColors.accentGold, size: 22),
          ),
          AppSpacing.gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin['full_name'] as String? ?? '—',
                    style: AppTypography.subtitle),
                Text(admin['email'] as String? ?? '—',
                    style: AppTypography.bodySmall),
                if (admin['company_name'] != null)
                  Text(
                    admin['company_name'] as String,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primaryBlue),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              borderRadius: AppSpacing.radiusSmall,
            ),
            child: Text(
              (admin['status'] as String? ?? 'active').toUpperCase(),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.successGreen,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          AppSpacing.gapW8,
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.errorRed),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── COMPANIES TAB ────────────────────────────────────────────────────────────
class _CompaniesTab extends StatelessWidget {
  final List<Map<String, dynamic>> companies;
  const _CompaniesTab({required this.companies});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: AppSpacing.pAll16,
      children: [
        Row(
          children: [
            Expanded(
                child: Text('Registered Companies (${companies.length})',
                    style: AppTypography.h3)),
          ],
        ),
        AppSpacing.gapH16,
        ...companies.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: AppSpacing.pAll16,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppSpacing.radiusMedium,
                  border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.radiusSmall,
                      ),
                      child: const Icon(Icons.business_rounded,
                          color: AppColors.primaryBlue, size: 22),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'] as String? ?? '—',
                              style: AppTypography.subtitle),
                          Text(c['contact_email'] as String? ?? '—',
                              style: AppTypography.bodySmall),
                          Text(c['contact_phone'] as String? ?? '—',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (c['status'] == 'active'
                                ? AppColors.successGreen
                                : AppColors.errorRed)
                            .withValues(alpha: 0.12),
                        borderRadius: AppSpacing.radiusSmall,
                      ),
                      child: Text(
                        (c['status'] as String? ?? 'active').toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: c['status'] == 'active'
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─── ADD ADMIN BOTTOM SHEET ───────────────────────────────────────────────────
class _AddAdminSheet extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController companyCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onSubmit;

  const _AddAdminSheet({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.companyCtrl,
    required this.passwordCtrl,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.radiusXLarge,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.radiusSmall,
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.accentGold, size: 20),
                  ),
                  AppSpacing.gapW12,
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Admin', style: AppTypography.h3),
                        Text('Admin waxaa abuuraa SuperAdmin kaliya',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              AppSpacing.gapH20,
              AppTextField(
                label: 'Full Name',
                hintText: 'Magaca buuxa',
                controller: nameCtrl,
                prefixIcon: Icons.person_outline,
              ),
              AppSpacing.gapH16,
              AppTextField(
                label: 'Email',
                hintText: 'admin@company.so',
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              AppSpacing.gapH16,
              AppTextField(
                label: 'Phone Number',
                hintText: '+252 61 xxxxxxx',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              AppSpacing.gapH16,
              AppTextField(
                label: 'Company Name',
                hintText: 'Shirkadda uu maamulayo',
                controller: companyCtrl,
                prefixIcon: Icons.business_outlined,
              ),
              AppSpacing.gapH16,
              AppTextField(
                label: 'Temporary Password',
                hintText: 'Password ku meel gaadh',
                controller: passwordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outlined,
              ),
              AppSpacing.gapH24,
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Create Admin Account',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
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
  }
}

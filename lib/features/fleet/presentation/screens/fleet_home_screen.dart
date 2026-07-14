import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/glass_container.dart';
import '../../../../core/shared/widgets/text_fields.dart';
import '../../data/fleet_repository.dart';

class FleetHomeScreen extends ConsumerStatefulWidget {
  const FleetHomeScreen({super.key});

  @override
  ConsumerState<FleetHomeScreen> createState() => _FleetHomeScreenState();
}

class _FleetHomeScreenState extends ConsumerState<FleetHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Fleet state variables
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _maintenance = [];
  List<Map<String, dynamic>> _fuelLogs = [];
  List<Map<String, dynamic>> _staffList = [];

  // Form states for assignments
  String _selectedTripId = 'd9b8a7c6-2222-3333-4444-555566667777';
  String _selectedBusNumber = 'MOG-GRW-08';
  String _selectedDriverId = 'driver-u1';
  String _selectedConductorId = 'cond-u1';

  // Schedule Maintenance states
  final _maintFormKey = GlobalKey<FormState>();
  final _maintBusController = TextEditingController(text: 'MOG-GRW-08');
  final _maintDescController = TextEditingController();
  final _maintCostController = TextEditingController(text: '200.00');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _maintBusController.dispose();
    _maintDescController.dispose();
    _maintCostController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(fleetRepositoryProvider);
    final buses = await repo.getBuses();
    final maint = await repo.getMaintenanceRecords();
    final fuels = await repo.getFuelReports();
    final staff = await repo.getAvailableStaff();

    setState(() {
      _buses = buses;
      _maintenance = maint;
      _fuelLogs = fuels;
      _staffList = staff;
    });
    setState(() => _isLoading = false);
  }

  // Allocate Bus / Driver to route
  Future<void> _assignStaffAndBus() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(fleetRepositoryProvider).assignTripStaffAndBus(
        tripId: _selectedTripId,
        busNumber: _selectedBusNumber,
        driverId: _selectedDriverId,
        conductorId: _selectedConductorId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff and Bus successfully assigned to route!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment failed: $e'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Schedule new maintenance event
  Future<void> _addMaintenance() async {
    if (_maintFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await ref.read(fleetRepositoryProvider).scheduleMaintenance(
          busNumber: _maintBusController.text.trim(),
          description: _maintDescController.text.trim(),
          cost: double.tryParse(_maintCostController.text) ?? 0.0,
          scheduledDate: DateTime.now().toIso8601String().substring(0, 10),
          status: 'pending',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance scheduled successfully!'), backgroundColor: AppColors.successGreen),
        );
        _maintDescController.clear();
        await _loadInitialData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule maintenance: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Fleet Dispatch Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Live Map Tracker', icon: Icon(Icons.map_rounded)),
            Tab(text: 'Staff Assignment', icon: Icon(Icons.assignment_ind_rounded)),
            Tab(text: 'Bus Status', icon: Icon(Icons.directions_bus_filled_rounded)),
            Tab(text: 'Service Schedule', icon: Icon(Icons.engineering_rounded)),
            Tab(text: 'Fuel Expenditure', icon: Icon(Icons.local_gas_station_rounded)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRealtimeMapTab(),
                _buildAssignmentTab(),
                _buildBusStatusTab(),
                _buildMaintenanceTab(),
                _buildFuelTab(),
              ],
            ),
    );
  }

  // REALTIME GPS TELEMETRY MAP TRACKER
  Widget _buildRealtimeMapTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(fleetRepositoryProvider).streamRealtimeGPS(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? _buses;

        return Padding(
          padding: AppSpacing.pAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Telemetry Operations', style: AppTypography.h3),
              Text('Real-time GPS coordinate streaming and passenger load tracking', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
              AppSpacing.gapH16,

              // Mock live dashboard map container
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: AppSpacing.radiusMedium,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Stack(
                    children: [
                      // Vector Grid layout representation
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.05,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15),
                            itemBuilder: (c, i) => Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Animated GPS Dot icons
                      for (var bus in list.where((b) => b['status'] == 'active'))
                        _buildMapPointerIcon(bus),

                      const Center(
                        child: Text(
                          'MAP VIEWPORT\n(Live GPS telemetry streaming active)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              AppSpacing.gapH16,

              // List of active buses with real-time updates
              const Text('Active Buses Live Status', style: AppTypography.subtitle),
              AppSpacing.gapH12,
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: list.where((b) => b['status'] == 'active').length,
                  itemBuilder: (context, idx) {
                    final activeBuses = list.where((b) => b['status'] == 'active').toList();
                    final bus = activeBuses[idx];
                    final pCount = bus['passenger_count'] as int? ?? 0;
                    final cap = bus['capacity'] as int? ?? 40;

                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          ),
                          child: const Icon(Icons.directions_bus_rounded, color: AppColors.primaryBlue),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(bus['bus_number'].toString(), style: AppTypography.subtitle),
                            Text(
                              '${bus['speed'].toString()} km/h',
                              style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coords: ${double.tryParse(bus['latitude'].toString())?.toStringAsFixed(4)}, ${double.tryParse(bus['longitude'].toString())?.toStringAsFixed(4)}'),
                            AppSpacing.gapH4,
                            Row(
                              children: [
                                const Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey),
                                AppSpacing.gapW4,
                                Text('Passengers: $pCount / $cap', style: AppTypography.bodySmall),
                                AppSpacing.gapW12,
                                const Icon(Icons.local_gas_station_rounded, size: 14, color: Colors.grey),
                                AppSpacing.gapW4,
                                Text('Fuel: ${bus['fuel_level']}%', style: AppTypography.bodySmall),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapPointerIcon(Map<String, dynamic> bus) {
    // Generate simulated absolute position offsets relative to map width based on lat/lng values
    final lat = double.tryParse(bus['latitude'].toString()) ?? 2.0469;
    final lng = double.tryParse(bus['longitude'].toString()) ?? 45.3182;

    // Map math helper to keep widgets visible inside constraints
    final double leftPos = ((lng - 44.0) * 150) % 250;
    final double topPos = ((lat - 2.0) * 120) % 180;

    return AnimatedPositioned(
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      left: 30 + leftPos,
      top: 20 + topPos,
      child: Tooltip(
        message: 'Bus: ${bus['bus_number']}\nPassengers: ${bus['passenger_count']}',
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                bus['bus_number'].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(
              Icons.location_on_rounded,
              color: AppColors.primaryBlue,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  // BUS / DRIVER ASSIGNMENTS TAB
  Widget _buildAssignmentTab() {
    final drivers = _staffList.where((s) => s['role'] == 'driver').toList();
    final conductors = _staffList.where((s) => s['role'] == 'conductor').toList();

    return Padding(
      padding: AppSpacing.pAll16,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip Assignments Console', style: AppTypography.h3),
            Text('Allocate vehicles, drivers, and conductors to scheduled routes', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
            AppSpacing.gapH24,

            Card(
              child: Padding(
                padding: AppSpacing.pAll16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Scheduled Route Trip', style: AppTypography.label),
                    AppSpacing.gapH8,
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripId,
                      items: const [
                        DropdownMenuItem(value: 'd9b8a7c6-2222-3333-4444-555566667777', child: Text('Mogadishu ➔ Garowe (Trip: MOG-GRW-08)')),
                        DropdownMenuItem(value: 'c8b7a6d5-4444-5555-6666-777788889999', child: Text('Hargeisa ➔ Burao (Trip: HAR-BUR-02)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTripId = val);
                      },
                    ),
                    AppSpacing.gapH16,

                    const Text('Assign Bus vehicle', style: AppTypography.label),
                    AppSpacing.gapH8,
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBusNumber,
                      items: _buses.map((b) {
                        return DropdownMenuItem(
                          value: b['bus_number'].toString(),
                          child: Text('${b['bus_number']} (${b['model']})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBusNumber = val);
                      },
                    ),
                    AppSpacing.gapH16,

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assign Driver', style: AppTypography.label),
                              AppSpacing.gapH8,
                              DropdownButtonFormField<String>(
                                initialValue: _selectedDriverId,
                                items: drivers.map((d) {
                                  return DropdownMenuItem(
                                    value: d['id'].toString(),
                                    child: Text(d['full_name'].toString()),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedDriverId = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assign Conductor', style: AppTypography.label),
                              AppSpacing.gapH8,
                              DropdownButtonFormField<String>(
                                initialValue: _selectedConductorId,
                                items: conductors.map((c) {
                                  return DropdownMenuItem(
                                    value: c['id'].toString(),
                                    child: Text(c['full_name'].toString()),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedConductorId = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    AppSpacing.gapH24,
                    AppButton(
                      text: 'Apply Route Allocations',
                      onPressed: _assignStaffAndBus,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // BUS CATALOG & STATUS LIST
  Widget _buildBusStatusTab() {
    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bus Fleet Catalog', style: AppTypography.h3),
          AppSpacing.gapH16,
          Expanded(
            child: ListView.builder(
              itemCount: _buses.length,
              itemBuilder: (context, index) {
                final bus = _buses[index];
                final status = bus['status'].toString();

                Color statusColor;
                IconData statusIcon;
                switch (status) {
                  case 'active':
                    statusColor = AppColors.successGreen;
                    statusIcon = Icons.check_circle_outline_rounded;
                    break;
                  case 'maintenance':
                    statusColor = AppColors.warningOrange;
                    statusIcon = Icons.build_circle_outlined;
                    break;
                  case 'out_of_service':
                  default:
                    statusColor = AppColors.errorRed;
                    statusIcon = Icons.dangerous_outlined;
                }

                return Card(
                  child: ListTile(
                    leading: Icon(Icons.directions_bus_filled_rounded, color: statusColor, size: 30),
                    title: Text(bus['bus_number']),
                    subtitle: Text('Model: ${bus['model']} | Capacity: ${bus['capacity']} seats'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.radiusSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          AppSpacing.gapW4,
                          Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // MAINTENANCE RECORDS AND SERVICE SCHEDULER
  Widget _buildMaintenanceTab() {
    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          // Create servicing schedule
          Card(
            child: Padding(
              padding: AppSpacing.pAll16,
              child: Form(
                key: _maintFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.engineering_rounded, color: AppColors.primaryBlue),
                        AppSpacing.gapW8,
                        Text('Schedule Bus Maintenance', style: AppTypography.h3),
                      ],
                    ),
                    AppSpacing.gapH16,
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Bus License Number',
                            hintText: 'e.g. MOG-GRW-08',
                            controller: _maintBusController,
                            prefixIcon: Icons.directions_bus_rounded,
                            validator: (val) => val == null || val.isEmpty ? 'License number required' : null,
                          ),
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          child: AppTextField(
                            label: 'Estimated Cost (USD)',
                            hintText: 'e.g. 150.00',
                            controller: _maintCostController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.monetization_on_rounded,
                            validator: (val) => val == null || val.isEmpty ? 'Cost estimation required' : null,
                          ),
                        )
                      ],
                    ),
                    AppSpacing.gapH16,
                    AppTextField(
                      label: 'Servicing Action Description',
                      hintText: 'e.g. Oil change, transmission diagnostic check...',
                      controller: _maintDescController,
                      prefixIcon: Icons.description_outlined,
                      validator: (val) => val == null || val.isEmpty ? 'Describe maintenance details' : null,
                    ),
                    AppSpacing.gapH20,
                    AppButton(
                      text: 'Schedule Service Task',
                      onPressed: _addMaintenance,
                    )
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.gapH20,

          // Logs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scheduled Maintenance Logs', style: AppTypography.subtitle),
                AppSpacing.gapH12,
                Expanded(
                  child: ListView.builder(
                    itemCount: _maintenance.length,
                    itemBuilder: (context, index) {
                      final m = _maintenance[index];
                      final isPending = m['status'] == 'pending';

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isPending ? Icons.hourglass_empty_rounded : Icons.task_alt_rounded,
                            color: isPending ? AppColors.warningOrange : AppColors.successGreen,
                          ),
                          title: Text('Bus: ${m['bus_number']} | Cost: \$${m['cost']}'),
                          subtitle: Text('Details: ${m['description']}\nDate: ${m['scheduled_date']}'),
                          trailing: isPending
                              ? ElevatedButton(
                                  onPressed: () async {
                                    setState(() => _isLoading = true);
                                    await ref.read(fleetRepositoryProvider).scheduleMaintenance(
                                      busNumber: m['bus_number'],
                                      description: m['description'],
                                      cost: (m['cost'] as num).toDouble(),
                                      scheduledDate: m['scheduled_date'],
                                      status: 'completed',
                                    );
                                    _loadInitialData();
                                  },
                                  child: const Text('Complete'),
                                )
                              : const Text('COMPLETED', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // FUEL EXPENDITURE TAB
  Widget _buildFuelTab() {
    final totalSpent = _fuelLogs.fold<double>(0.0, (sum, f) => sum + (double.tryParse(f['cost'].toString()) ?? 0.0));

    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expenditure header metrics
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Fuel Expenses (Monthly)', style: AppTypography.label.copyWith(color: AppColors.primaryBlue)),
                      AppSpacing.gapH4,
                      Text('\$${totalSpent.toStringAsFixed(2)}', style: AppTypography.h1.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.account_balance_rounded, color: AppColors.accentGold, size: 40),
                ],
              ),
            ),
          ),
          AppSpacing.gapH24,

          const Text('Driver Refuel Activity Logs', style: AppTypography.subtitle),
          AppSpacing.gapH12,
          Expanded(
            child: ListView.builder(
              itemCount: _fuelLogs.length,
              itemBuilder: (context, index) {
                final log = _fuelLogs[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Icon(Icons.local_gas_station_rounded, color: Colors.white),
                    ),
                    title: Text('Bus: ${log['bus_number']} | Spent: \$${log['cost']}'),
                    subtitle: Text('Driver: ${log['driver_name']} | Volume: ${log['amount_liters']} L\nOdometer: ${log['odometer_reading']} km'),
                    trailing: Text(log['date'].toString(), style: AppTypography.bodySmall),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

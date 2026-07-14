import 'dart:async';
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
import '../../../booking/data/models/trip.dart';
import '../../data/driver_repository.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  int _currentTab = 0;
  Trip? _activeTrip;
  List<Trip> _todayTrips = [];
  List<Map<String, dynamic>> _passengers = [];
  bool _isLoading = false;

  // Realtime Location Broadcast simulator
  bool _isBroadcasting = false;
  Timer? _gpsTimer;
  double _simulatedSpeed = 0.0;
  double _simulatedLat = 2.0469; // Mogadishu center
  double _simulatedLng = 45.3182;
  double _simulatedFuel = 85.0;

  // Form controllers
  final _fuelFormKey = GlobalKey<FormState>();
  final _fuelLitersController = TextEditingController(text: '80.0');
  final _fuelCostController = TextEditingController(text: '88.00');
  final _fuelOdometerController = TextEditingController(text: '154800');

  final _incidentFormKey = GlobalKey<FormState>();
  final _incidentDescController = TextEditingController();
  String _selectedSeverity = 'medium';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _fuelLitersController.dispose();
    _fuelCostController.dispose();
    _fuelOdometerController.dispose();
    _incidentDescController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      final repo = ref.read(driverRepositoryProvider);
      final trips = await repo.getTodayTrips(user.id);
      setState(() {
        _todayTrips = trips;
        if (trips.isNotEmpty) {
          _activeTrip = trips.first;
        }
      });
      if (_activeTrip != null) {
        final list = await repo.getTripPassengers(_activeTrip!.id);
        setState(() {
          _passengers = list;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  // Toggle Live coordinates simulation broadcaster (Realtime GPS)
  void _toggleLocationBroadcast(bool value) {
    setState(() {
      _isBroadcasting = value;
    });

    if (value) {
      _simulatedSpeed = 60.0;
      _gpsTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
        // Drift coordinates slightly towards Garowe
        setState(() {
          _simulatedLat += 0.0012;
          _simulatedLng += 0.0008;
          _simulatedSpeed = 58.0 + (timer.tick % 4) * 3;
          _simulatedFuel -= 0.05;
        });

        if (_activeTrip != null) {
          await ref.read(driverRepositoryProvider).updateGPSLocation(
            busNumber: _activeTrip!.busNumber,
            latitude: _simulatedLat,
            longitude: _simulatedLng,
            speed: _simulatedSpeed,
            fuelLevel: _simulatedFuel,
            passengerCount: _passengers.length,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Realtime GPS broadcast active. Transmitting location points...'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      _gpsTimer?.cancel();
      setState(() {
        _simulatedSpeed = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS broadcasting disabled.'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
    }
  }

  Future<void> _updateTripStatus(String status) async {
    if (_activeTrip == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(driverRepositoryProvider).updateTripStatus(_activeTrip!.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip status updated to: ${status.toUpperCase()}')),
      );
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: AppColors.errorRed),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitFuelReport() async {
    if (_fuelFormKey.currentState?.validate() ?? false) {
      final user = ref.read(authNotifierProvider).valueOrNull;
      if (user == null || _activeTrip == null) return;

      setState(() => _isLoading = true);
      try {
        await ref.read(driverRepositoryProvider).submitFuelReport(
          busNumber: _activeTrip!.busNumber,
          driverId: user.id,
          liters: double.tryParse(_fuelLitersController.text) ?? 0.0,
          cost: double.tryParse(_fuelCostController.text) ?? 0.0,
          odometer: double.tryParse(_fuelOdometerController.text) ?? 0.0,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel report successfully logged!'), backgroundColor: AppColors.successGreen),
        );
        _fuelLitersController.clear();
        _fuelCostController.clear();
        _fuelOdometerController.clear();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _submitIncidentReport() async {
    if (_incidentFormKey.currentState?.validate() ?? false) {
      final user = ref.read(authNotifierProvider).valueOrNull;
      if (user == null || _activeTrip == null) return;

      setState(() => _isLoading = true);
      try {
        await ref.read(driverRepositoryProvider).submitIncidentReport(
          tripId: _activeTrip!.id,
          driverId: user.id,
          severity: _selectedSeverity,
          description: _incidentDescController.text,
          latitude: _simulatedLat,
          longitude: _simulatedLng,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident report submitted to dispatch!'), backgroundColor: AppColors.successGreen),
        );
        _incidentDescController.clear();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
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
    
    final backgroundGradient = isDark
        ? const LinearGradient(
            colors: [AppColors.darkBackground, AppColors.darkSurface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [AppColors.lightBackground, Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Driver Operations'),
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
      ),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _currentTab,
                children: [
                  _buildTripsTab(),
                  _buildPassengerTab(),
                  _buildNavigationTab(),
                  _buildReportsTab(),
                  _buildHistoryTab(),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        iconSize: 26,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_rounded),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Passengers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Navigation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }

  // REUSABLE PREMIUM EMPTY STATE DESIGN
  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onRefresh,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          borderColor: isDark ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.primaryBlue.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stylized glowing icon container
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.25),
                        AppColors.primaryBlue.withValues(alpha: 0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: AppColors.primaryBlue,
                  ),
                ),
                AppSpacing.gapH24,
                Text(
                  title,
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH12,
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH24,
                SizedBox(
                  width: 200,
                  child: AppButton(
                    text: 'Refresh Schedule',
                    icon: Icons.refresh_rounded,
                    onPressed: onRefresh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TODAY'S TRIPS TAB
  Widget _buildTripsTab() {
    if (_todayTrips.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.directions_bus_rounded,
        title: 'No Assigned Trips Today',
        description: 'Your dispatch office has not assigned any active trips or routes to your shift calendar today. Select refresh to check for new schedules.',
        onRefresh: _loadInitialData,
      );
    }

    return Padding(
      padding: AppSpacing.pAll16,
      child: ListView.builder(
        itemCount: _todayTrips.length,
        itemBuilder: (context, index) {
          final trip = _todayTrips[index];
          final isCurrentActive = _activeTrip?.id == trip.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMedium),
            elevation: isCurrentActive ? 4 : 1,
            child: Container(
              decoration: isCurrentActive
                  ? BoxDecoration(
                      border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                      borderRadius: AppSpacing.radiusMedium,
                    )
                  : null,
              padding: AppSpacing.pAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bus: ${trip.busNumber}',
                        style: AppTypography.subtitle.copyWith(color: AppColors.primaryBlue),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.radiusSmall,
                        ),
                        child: Text(
                          isCurrentActive ? 'ACTIVE TRIP' : 'ASSIGNED',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH12,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DEPARTURE', style: AppTypography.label.copyWith(color: Colors.grey)),
                          Text(trip.departureCity, style: AppTypography.h3),
                          Text(
                            '${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('DESTINATION', style: AppTypography.label.copyWith(color: Colors.grey)),
                          Text(trip.arrivalCity, style: AppTypography.h3),
                          Text(
                            '${trip.arrivalTime.hour.toString().padLeft(2, '0')}:${trip.arrivalTime.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.gapH16,
                  const Divider(),
                  AppSpacing.gapH8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Seats Allocated: ${trip.totalSeats - trip.availableSeats}/${trip.totalSeats}'),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _activeTrip = trip;
                                _currentTab = 2; // Jump to Navigation map
                              });
                            },
                            child: const Text('Navigate'),
                          ),
                          AppSpacing.gapW8,
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.successGreen, size: 38),
                                tooltip: 'Start (Biloow)',
                                onPressed: () => _updateTripStatus('en_route'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.pause_circle_filled_rounded, color: AppColors.warningOrange, size: 38),
                                tooltip: 'Delay (Baaqo)',
                                onPressed: () => _updateTripStatus('delayed'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 38),
                                tooltip: 'Complete (Dhamee)',
                                onPressed: () => _updateTripStatus('completed'),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // PASSENGER LIST TAB
  Widget _buildPassengerTab() {
    if (_activeTrip == null) {
      return const Center(child: Text('Please select an active trip.'));
    }

    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passengers for Trip ${ _activeTrip?.busNumber ?? "" }',
            style: AppTypography.h3,
          ),
          AppSpacing.gapH4,
          Text(
            'Route: ${_activeTrip?.departureCity} ➔ ${_activeTrip?.arrivalCity}',
            style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
          ),
          AppSpacing.gapH16,
          Expanded(
            child: ListView.builder(
              itemCount: _passengers.length,
              itemBuilder: (context, index) {
                final pass = _passengers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: pass['checkedIn']
                          ? AppColors.successGreen.withValues(alpha: 0.1)
                          : AppColors.warningOrange.withValues(alpha: 0.1),
                      child: Icon(
                        pass['checkedIn'] ? Icons.check_circle_rounded : Icons.pending_rounded,
                        color: pass['checkedIn'] ? AppColors.successGreen : AppColors.warningOrange,
                      ),
                    ),
                    title: Text(pass['name']),
                    subtitle: Text('Phone: ${pass['phone']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.radiusSmall,
                      ),
                      child: Text(
                        'Seats: ${(pass['seats'] as List).join(', ')}',
                        style: AppTypography.label,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // NAVIGATION VIEW & GPS TRACKING TIMER SIMULATION
  Widget _buildNavigationTab() {
    if (_activeTrip == null) {
      return const Center(child: Text('Select a trip to begin navigation.'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          // Simulated Map Container with futuristic glassmorphism overview
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: AppSpacing.radiusLarge,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                  )
                ],
              ),
              child: Stack(
                children: [
                  // Beautiful Custom Grid Mock Vector Map background
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
                        itemBuilder: (c, i) => Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Animated Map path design
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_rounded, size: 80, color: AppColors.primaryBlue),
                        AppSpacing.gapH16,
                        Text(
                          'SOMALI TRANS-CORRIDOR LIVE MAP',
                          style: AppTypography.subtitle.copyWith(letterSpacing: 1),
                        ),
                        AppSpacing.gapH8,
                        Text(
                          'Route: ${_activeTrip!.departureCity} ➔ ${_activeTrip!.arrivalCity}',
                          style: AppTypography.bodyMedium,
                        ),
                        AppSpacing.gapH24,
                        // Progress bar indicator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48.0),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: _isBroadcasting ? 0.45 : 0.0,
                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              ),
                              AppSpacing.gapH8,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_activeTrip!.departureCity, style: AppTypography.bodySmall),
                                  Text(_activeTrip!.arrivalCity, style: AppTypography.bodySmall),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current Coordinates display card
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: GlassContainer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('LATITUDE', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
                                Text(_simulatedLat.toStringAsFixed(5), style: AppTypography.subtitle.copyWith(fontFamily: 'monospace')),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('LONGITUDE', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
                                Text(_simulatedLng.toStringAsFixed(5), style: AppTypography.subtitle.copyWith(fontFamily: 'monospace')),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('SPEED', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
                                Text('${_simulatedSpeed.toStringAsFixed(1)} km/h', style: AppTypography.subtitle.copyWith(color: AppColors.accentGold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          AppSpacing.gapH16,
          // Real-time GPS Tracker Controls card
          Container(
            padding: AppSpacing.pAll16,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: AppSpacing.radiusMedium,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isBroadcasting ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                      color: _isBroadcasting ? Colors.green : Colors.red,
                      size: 26,
                    ),
                    AppSpacing.gapW12,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GPS Telemetry Broadcast', style: AppTypography.subtitle),
                        Text(
                          _isBroadcasting ? 'Broadcasting live coordinates' : 'Telemetry disabled',
                          style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isBroadcasting,
                  onChanged: _toggleLocationBroadcast,
                  activeThumbColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FUEL REPORT & INCIDENT REPORT SUBMISSIONS
  Widget _buildReportsTab() {
    if (_activeTrip == null) {
      return const Center(child: Text('Select an active trip to submit reports.'));
    }

    return Padding(
      padding: AppSpacing.pAll16,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Fuel Report Card Form
            Card(
              child: Padding(
                padding: AppSpacing.pAll16,
                child: Form(
                  key: _fuelFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_gas_station_rounded, color: AppColors.accentGold),
                          AppSpacing.gapW8,
                          Text('Log Refuel Report', style: AppTypography.h3),
                        ],
                      ),
                      AppSpacing.gapH16,
                      const Text('Preset Liters (Taabo Shidaalka)', style: AppTypography.label),
                      AppSpacing.gapH8,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [50, 100, 150, 200].map((l) {
                          final isSelected = double.tryParse(_fuelLitersController.text) == l;
                          return ChoiceChip(
                            label: Text('$l Liters', style: const TextStyle(fontWeight: FontWeight.bold)),
                            selected: isSelected,
                            selectedColor: AppColors.accentGold.withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.accentGold : Colors.grey,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _fuelLitersController.text = l.toDouble().toString();
                                  _fuelCostController.text = (l * 1.10).toStringAsFixed(2);
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      AppSpacing.gapH16,
                      AppTextField(
                        label: 'Liters Refueled',
                        hintText: 'e.g. 100',
                        controller: _fuelLitersController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.opacity_rounded,
                        validator: (val) => val == null || val.isEmpty ? 'Enter fuel volume' : null,
                      ),
                      AppSpacing.gapH16,
                      AppTextField(
                        label: 'Total Cost (USD)',
                        hintText: 'e.g. 110.00',
                        controller: _fuelCostController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.monetization_on_rounded,
                        validator: (val) => val == null || val.isEmpty ? 'Enter refuel expense' : null,
                      ),
                      AppSpacing.gapH16,
                      AppTextField(
                        label: 'Odometer Reading (KM)',
                        hintText: 'e.g. 154800',
                        controller: _fuelOdometerController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.speed_rounded,
                        validator: (val) => val == null || val.isEmpty ? 'Enter current odometer' : null,
                      ),
                      AppSpacing.gapH24,
                      AppButton(
                        text: 'Submit Fuel Log',
                        onPressed: _submitFuelReport,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppSpacing.gapH20,

            // Quick Incident Grid
            Card(
              child: Padding(
                padding: AppSpacing.pAll16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: AppColors.errorRed),
                        AppSpacing.gapW8,
                        Text('Quick Incident Alert (Digniin Degdeg ah)', style: AppTypography.h3),
                      ],
                    ),
                    AppSpacing.gapH4,
                    const Text(
                      'Tap any card to instantly alert dispatch.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    AppSpacing.gapH16,
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildQuickIncidentCard(
                          icon: Icons.construction_rounded,
                          title: 'Taayir / Cilad',
                          subtitle: 'Tire / Breakdown',
                          color: AppColors.warningOrange,
                          severity: 'medium',
                          description: 'Breakdown / Taayir dillaacay ama cilad farsamo',
                        ),
                        _buildQuickIncidentCard(
                          icon: Icons.block_rounded,
                          title: 'Waddo Xiran',
                          subtitle: 'Road Blocked',
                          color: AppColors.warningOrange,
                          severity: 'high',
                          description: 'Road Blocked / Jid gooyo ama waddo xiran',
                        ),
                        _buildQuickIncidentCard(
                          icon: Icons.security_rounded,
                          title: 'Koontarool Check',
                          subtitle: 'Checkpoint',
                          color: AppColors.primaryBlue,
                          severity: 'low',
                          description: 'Security Checkpoint / Koontarool ciidan',
                        ),
                        _buildQuickIncidentCard(
                          icon: Icons.opacity_rounded,
                          title: 'Shidaal La\'aan',
                          subtitle: 'Fuel Empty',
                          color: AppColors.errorRed,
                          severity: 'high',
                          description: 'Out of fuel / Shidaal la\'aan',
                        ),
                        _buildQuickIncidentCard(
                          icon: Icons.warning_rounded,
                          title: 'Shil / Caawinaad',
                          subtitle: 'Accident / Help',
                          color: AppColors.errorRed,
                          severity: 'critical',
                          description: 'Emergency assistance / Shil ama caawinaad degdeg ah',
                        ),
                        _buildQuickIncidentCard(
                          icon: Icons.phone_in_talk_rounded,
                          title: 'Wac Maamulka',
                          subtitle: 'Call Support',
                          color: AppColors.successGreen,
                          severity: 'low',
                          description: 'Call Support',
                          isCall: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapH20,

            // Custom Incident Report Card Form (Fallback)
            Card(
              child: Padding(
                padding: AppSpacing.pAll16,
                child: Form(
                  key: _incidentFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, color: AppColors.errorRed),
                          AppSpacing.gapW8,
                          Text('Other Incident Details (Qor faahfaahin kale)', style: AppTypography.h3),
                        ],
                      ),
                      AppSpacing.gapH16,
                      const Text('Severity Level', style: AppTypography.label),
                      AppSpacing.gapH8,
                      Row(
                        children: [
                          _buildSeverityChip('low'),
                          AppSpacing.gapW8,
                          _buildSeverityChip('medium'),
                          AppSpacing.gapW8,
                          _buildSeverityChip('high'),
                          AppSpacing.gapW8,
                          _buildSeverityChip('critical'),
                        ],
                      ),
                      AppSpacing.gapH16,
                      AppTextField(
                        label: 'Description & Details',
                        hintText: 'Detail details: e.g. police check, road blockage, puncture...',
                        controller: _incidentDescController,
                        prefixIcon: Icons.description_outlined,
                        validator: (val) => val == null || val.isEmpty ? 'Incident description required' : null,
                      ),
                      AppSpacing.gapH24,
                      AppButton(
                        text: 'Raise Custom Warning',
                        onPressed: _submitIncidentReport,
                        type: ButtonType.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    final isSelected = _selectedSeverity == severity;
    Color chipColor;
    switch (severity) {
      case 'low':
        chipColor = AppColors.successGreen;
        break;
      case 'high':
        chipColor = AppColors.warningOrange;
        break;
      case 'critical':
        chipColor = AppColors.errorRed;
        break;
      case 'medium':
      default:
        chipColor = AppColors.primaryBlue;
    }

    return ChoiceChip(
      label: Text(severity.toUpperCase()),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedSeverity = severity;
          });
        }
      },
      selectedColor: chipColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );
  }

  // TRIP HISTORY TIMELINE
  Widget _buildHistoryTab() {
    return Padding(
      padding: AppSpacing.pAll16,
      child: FutureBuilder<List<Trip>>(
        future: ref.read(driverRepositoryProvider).getTripHistory(
              ref.read(authNotifierProvider).valueOrNull?.id ?? '',
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No past trip history.'));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final trip = list[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.done_all_rounded, color: Colors.white),
                  ),
                  title: Text('${trip.departureCity} ➔ ${trip.arrivalCity}'),
                  subtitle: Text('Bus: ${trip.busNumber} | Code: MOG-GRW-08'),
                  trailing: Text(
                    '${trip.departureTime.day}/${trip.departureTime.month}',
                    style: AppTypography.subtitle,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickIncidentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String severity,
    required String description,
    bool isCall = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        if (isCall) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: AppColors.successGreen),
                  SizedBox(width: 8),
                  Text('Wac Maamulka'),
                ],
              ),
              content: const Text('Ma rabtaa inaad hadda wacdo xarunta maamulka SBMS?\n(Do you want to call SBMS dispatch support now?)'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('KHAASO (Cancel)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wicitaanka waa la bilaabay... Dialing +252 61 1110000'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  },
                  child: const Text('HAA WAC (Call)'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _selectedSeverity = severity;
            _incidentDescController.text = description;
          });
          // Show confirmation
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(title),
                ],
              ),
              content: Text('Ma rabtaa inaad u dirto digniinta: "$title"?\n(Send warning alert to dispatch?)'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('KHAASO (Cancel)'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _submitIncidentReport();
                  },
                  child: const Text('DIR (Send Alert)'),
                ),
              ],
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

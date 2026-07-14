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
import '../../data/conductor_repository.dart';

class ConductorHomeScreen extends ConsumerStatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  ConsumerState<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends ConsumerState<ConductorHomeScreen> {
  int _currentTab = 0;
  bool _isLoading = false;

  // Scanned Ticket details state (QR Scanner Mockup)
  String _scanInputCode = 'TICKET-111';
  Map<String, dynamic>? _scannedTicket;
  bool _isScanningMode = false;

  // Luggage state
  final List<Map<String, dynamic>> _luggageList = [];
  final _luggageFormKey = GlobalKey<FormState>();
  final _luggageWeightController = TextEditingController(text: '15.0');
  final _luggagePiecesController = TextEditingController(text: '1');
  String _selectedLuggageBookingId = 'booking-uuid-1';

  // Attendance state
  bool _isClockedIn = false;
  String _clockInTime = '--:--';
  String _clockOutTime = '--:--';

  // Manual Check-in database mockup list
  final List<Map<String, dynamic>> _passengerCheckInList = [
    {'id': 'booking-uuid-1', 'name': 'Ahmed Ali Moallim', 'phone': '+252 61 5551234', 'seats': ['A1', 'A2'], 'checkedIn': false},
    {'id': 'booking-uuid-2', 'name': 'Halima Warsame', 'phone': '+252 61 8882233', 'seats': ['B3'], 'checkedIn': true},
    {'id': 'booking-uuid-3', 'name': 'Farah Osman', 'phone': '+252 61 9993344', 'seats': ['C1', 'C2'], 'checkedIn': false},
    {'id': 'booking-uuid-4', 'name': 'Marian Yusuf', 'phone': '+252 61 2229988', 'seats': ['D4'], 'checkedIn': false},
  ];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _luggageWeightController.dispose();
    _luggagePiecesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      final repo = ref.read(conductorRepositoryProvider);
      final attendance = await repo.getTodayAttendance(user.id);
      final luggage = await repo.getLuggageList('d9b8a7c6-2222-3333-4444-555566667777');
      setState(() {
        _luggageList.clear();
        _luggageList.addAll(luggage);
        if (attendance != null) {
          _isClockedIn = true;
          _clockInTime = (attendance['check_in'] as String).substring(11, 16);
          if (attendance['check_out'] != null) {
            _clockOutTime = (attendance['check_out'] as String).substring(11, 16);
          }
        }
      });
    }
    setState(() => _isLoading = false);
  }

  // QR Ticket validation simulation
  Future<void> _handleQRScanSubmit() async {
    if (_scanInputCode.isEmpty) return;
    setState(() => _isLoading = true);
    final details = await ref.read(conductorRepositoryProvider).validateTicket(_scanInputCode);
    setState(() {
      _scannedTicket = details;
      _isScanningMode = false;
      _isLoading = false;
    });

    if (details == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR ticket scan code!'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  // Check-In Ticket action
  Future<void> _toggleCheckIn(String bookingId, bool checkInVal) async {
    setState(() => _isLoading = true);
    await ref.read(conductorRepositoryProvider).checkInPassenger(bookingId, checkInVal);
    // Update local state list
    setState(() {
      final idx = _passengerCheckInList.indexWhere((p) => p['id'] == bookingId);
      if (idx != -1) {
        _passengerCheckInList[idx]['checkedIn'] = checkInVal;
      }
      if (_scannedTicket != null && _scannedTicket!['id'] == bookingId) {
        _scannedTicket!['checked_in'] = checkInVal;
      }
    });
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkInVal ? 'Passenger check-in complete!' : 'Check-in cancelled.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  // Luggage Submission
  Future<void> _addLuggage() async {
    if (_luggageFormKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final tag = 'LUG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final weight = double.tryParse(_luggageWeightController.text) ?? 10.0;
      final pieces = int.tryParse(_luggagePiecesController.text) ?? 1;

      try {
        await ref.read(conductorRepositoryProvider).registerLuggage(
          bookingId: _selectedLuggageBookingId,
          tripId: 'd9b8a7c6-2222-3333-4444-555566667777',
          tagNumber: tag,
          weight: weight,
          pieces: pieces,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Luggage registered: Tag $tag allocated!'), backgroundColor: AppColors.successGreen),
          );
        }
        _luggageWeightController.text = '15.0';
        _luggagePiecesController.text = '1';
        _loadInitialData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding luggage: $e')),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  // Attendance Clock-in toggle
  Future<void> _toggleAttendance(bool checkIn) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    await ref.read(conductorRepositoryProvider).recordAttendance(
      userId: user.id,
      status: 'present',
      checkIn: checkIn,
    );
    await _loadInitialData();
    setState(() => _isLoading = false);
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
        title: const Text('Conductor Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
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
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _currentTab,
                children: [
                  _buildCheckInTab(),
                  _buildLuggageTab(),
                  _buildSummaryTab(),
                  _buildAttendanceTab(),
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
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Check-In',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_rounded),
            label: 'Luggage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_rounded),
            label: 'Shift',
          ),
        ],
      ),
    );
  }

  // CHECK IN AND QR SCANNER MOCKUP TAB
  Widget _buildCheckInTab() {
    final filteredPassengers = _passengerCheckInList.where((p) {
      final nameMatch = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatch = p['phone'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || phoneMatch;
    }).toList();

    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Scanner mockup toggler
          if (!_isScanningMode)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => setState(() => _isScanningMode = true),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Open QR Scanner Mockup'),
                  ),
                ),
              ],
            )
          else
            _buildScannerMockup(),

          AppSpacing.gapH20,

          // Scanned ticket info card
          if (_scannedTicket != null && !_isScanningMode) ...[
            _buildScannedTicketCard(),
            AppSpacing.gapH24,
          ],

          // Search Field
          const Text('Manual Passengers Search', style: AppTypography.subtitle),
          AppSpacing.gapH8,
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by passenger name or phone number...',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          AppSpacing.gapH16,

          // Passenger Boarding Checklist
          Expanded(
            child: ListView.builder(
              itemCount: filteredPassengers.length,
              itemBuilder: (context, index) {
                final pass = filteredPassengers[index];
                final isChecked = pass['checkedIn'] as bool;
                final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  child: ClipRRect(
                    borderRadius: AppSpacing.radiusMedium,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isChecked ? AppColors.successGreen : Colors.orange,
                            width: 6,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          pass['name'],
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, size: 13, color: Colors.grey),
                                  AppSpacing.gapW4,
                                  Text(pass['phone'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              AppSpacing.gapH4,
                              Row(
                                children: [
                                  const Icon(Icons.chair_rounded, size: 13, color: AppColors.primaryBlue),
                                  AppSpacing.gapW4,
                                  Text(
                                    'Seats: ${(pass['seats'] as List).join(', ')}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: InkWell(
                          onTap: () => _toggleCheckIn(pass['id'], !isChecked),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isChecked 
                                  ? AppColors.successGreen 
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChecked ? AppColors.successGreen : Colors.orange,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: isChecked ? Colors.white : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isChecked ? 'ON BOARD' : 'BOARD',
                                  style: TextStyle(
                                    color: isChecked ? Colors.white : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildScannerMockup() {
    return Container(
      padding: AppSpacing.pAll16,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(color: AppColors.primaryBlue, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE QR SCANNER VIEWFINDER',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => setState(() => _isScanningMode = false),
              )
            ],
          ),
          AppSpacing.gapH12,
          // Scanner Box
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBlue, width: 3),
              borderRadius: AppSpacing.radiusMedium,
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.white24),
                // Scanning red laser horizontal line mockup
                Positioned(
                  top: 90,
                  left: 10,
                  right: 10,
                  child: Divider(color: Colors.red, thickness: 3),
                )
              ],
            ),
          ),
          AppSpacing.gapH20,
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Simulate QR Code String Input',
                  hintText: 'TICKET-111 or TICKET-222',
                  prefixIcon: Icons.keyboard_rounded,
                  onChanged: (val) {
                    _scanInputCode = val;
                  },
                ),
              ),
              AppSpacing.gapW12,
              Container(
                margin: const EdgeInsets.only(top: 20),
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
                  onPressed: _handleQRScanSubmit,
                  child: const Text('Scan'),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildScannedTicketCard() {
    final ticket = _scannedTicket!;
    final isCheckedIn = ticket['checked_in'] as bool;

    return GlassContainer(
      child: Padding(
        padding: AppSpacing.pAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SCANNED PASSENGER TICKET', style: AppTypography.label.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCheckedIn ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.radiusSmall,
                  ),
                  child: Text(
                    isCheckedIn ? 'VERIFIED' : 'NOT CHECKED-IN',
                    style: TextStyle(color: isCheckedIn ? AppColors.successGreen : AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                )
              ],
            ),
            AppSpacing.gapH12,
            Text(ticket['passenger_name'], style: AppTypography.h3),
            AppSpacing.gapH4,
            Text('Contact: ${ticket['phone_number']}'),
            Text('Allocated Seats: ${(ticket['seats'] as List).join(", ")}'),
            Text('Scheduled Bus: ${ticket['bus_number']}'),
            AppSpacing.gapH16,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _scannedTicket = null),
                  child: const Text('Clear'),
                ),
                AppSpacing.gapW12,
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedIn ? AppColors.warningOrange : AppColors.successGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _toggleCheckIn(ticket['id'], !isCheckedIn),
                  child: Text(isCheckedIn ? 'Revoke Check-In' : 'Confirm Boarding Check-In'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // LUGGAGE REGISTER TAB
  Widget _buildLuggageTab() {
    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        children: [
          // Registration Form Card
          Card(
            child: Padding(
              padding: AppSpacing.pAll16,
              child: Form(
                key: _luggageFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business_center_rounded, color: AppColors.primaryBlue),
                        AppSpacing.gapW8,
                        Text('Add Passenger Luggage Tag', style: AppTypography.h3),
                      ],
                    ),
                    AppSpacing.gapH16,
                    const Text('Select Passenger / Seat', style: AppTypography.label),
                    AppSpacing.gapH8,
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLuggageBookingId,
                      items: _passengerCheckInList.map((p) {
                        return DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text('${p['name']} (Seats: ${(p['seats'] as List).join(", ")})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLuggageBookingId = val;
                          });
                        }
                      },
                    ),
                    AppSpacing.gapH16,
                    const Text('Preset Weight (Taabo Miisaanka)', style: AppTypography.label),
                    AppSpacing.gapH8,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [10, 15, 20, 25, 30].map((w) {
                        final isSelected = double.tryParse(_luggageWeightController.text) == w;
                        return ChoiceChip(
                          label: Text('$w KG', style: const TextStyle(fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: AppColors.accentGold.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.accentGold : Colors.grey,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _luggageWeightController.text = w.toDouble().toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    AppSpacing.gapH16,
                    const Text('Preset Pieces (Miriha Shandadaha)', style: AppTypography.label),
                    AppSpacing.gapH8,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [1, 2, 3, 4].map((p) {
                        final isSelected = int.tryParse(_luggagePiecesController.text) == p;
                        return ChoiceChip(
                          label: Text('$p Bag${p > 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryBlue : Colors.grey,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _luggagePiecesController.text = p.toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    AppSpacing.gapH16,
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Weight (KG)',
                            hintText: 'e.g. 15.0',
                            controller: _luggageWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.scale_rounded,
                            validator: (val) => val == null || val.isEmpty ? 'Weight required' : null,
                          ),
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          child: AppTextField(
                            label: 'Pieces Count',
                            hintText: 'e.g. 1',
                            controller: _luggagePiecesController,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.inventory_2_outlined,
                            validator: (val) => val == null || val.isEmpty ? 'Pieces count required' : null,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH20,
                    AppButton(
                      text: 'Print & Register Luggage Tag',
                      onPressed: _addLuggage,
                    )
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.gapH20,

          // Luggage Registry List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Trip Luggage Manifest', style: AppTypography.subtitle),
                AppSpacing.gapH12,
                Expanded(
                  child: _luggageList.isEmpty
                      ? const Center(child: Text('No registered luggage tags on this bus yet.'))
                      : ListView.builder(
                          itemCount: _luggageList.length,
                          itemBuilder: (context, index) {
                            final lug = _luggageList[index];
                            final passenger = _passengerCheckInList.firstWhere(
                              (p) => p['id'] == lug['booking_id'], 
                              orElse: () => {'name': 'Somali Commuter'},
                            );

                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.tag_rounded, color: AppColors.accentGold),
                                title: Text('Tag: ${lug['tag_number']}'),
                                subtitle: Text('Passenger: ${passenger['name']} | Weight: ${lug['weight_kg']} KG (${lug['pieces']} pcs)'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen.withValues(alpha: 0.1),
                                    borderRadius: AppSpacing.radiusSmall,
                                  ),
                                  child: Text(
                                    lug['status'].toString().toUpperCase(),
                                    style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
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

  // TRIP SUMMARY BOARD
  Widget _buildSummaryTab() {
    final checkedInCount = _passengerCheckInList.where((p) => p['checkedIn'] == true).length;
    final totalLuggageWeight = _luggageList.fold<double>(0.0, (sum, element) => sum + (double.tryParse(element['weight_kg'].toString()) ?? 0.0));
    final totalLuggagePieces = _luggageList.fold<int>(0, (sum, element) => sum + (int.tryParse(element['pieces'].toString()) ?? 0));

    return Padding(
      padding: AppSpacing.pAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Dispatch Trip Summary', style: AppTypography.h3),
          Text('Bus ID: MOG-GRW-08 | Route: Mogadishu ➔ Garowe', style: AppTypography.bodyMedium.copyWith(color: Colors.grey)),
          AppSpacing.gapH24,

          // Grid metrics summary cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildSummaryMetricCard(
                title: 'Checked-In Passenger',
                value: '$checkedInCount / ${_passengerCheckInList.length}',
                icon: Icons.people_alt_rounded,
                color: AppColors.primaryBlue,
              ),
              _buildSummaryMetricCard(
                title: 'Remaining Boarding',
                value: '${_passengerCheckInList.length - checkedInCount}',
                icon: Icons.pending_actions_rounded,
                color: AppColors.warningOrange,
              ),
              _buildSummaryMetricCard(
                title: 'Luggage Onboard',
                value: '$totalLuggagePieces Bags',
                icon: Icons.work_history_rounded,
                color: AppColors.accentGold,
              ),
              _buildSummaryMetricCard(
                title: 'Total Cargo Weight',
                value: '${totalLuggageWeight.toStringAsFixed(1)} KG',
                icon: Icons.scale_rounded,
                color: AppColors.secondaryTeal,
              ),
            ],
          ),
          AppSpacing.gapH24,

          Card(
            color: AppColors.primaryBlue.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMedium, side: const BorderSide(color: AppColors.primaryBlue, width: 0.5)),
            child: Padding(
              padding: AppSpacing.pAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Boarding Status Checklist', style: AppTypography.subtitle),
                  AppSpacing.gapH8,
                  LinearProgressIndicator(
                    value: _passengerCheckInList.isEmpty ? 0 : (checkedInCount / _passengerCheckInList.length),
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    color: AppColors.successGreen,
                  ),
                  AppSpacing.gapH8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${((_passengerCheckInList.isEmpty ? 0 : checkedInCount / _passengerCheckInList.length) * 100).toInt()}% passengers boarded'),
                      Text('$checkedInCount Checked In'),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: AppSpacing.pAll12,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.gapH4,
              Text(title, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  // STAFF ATTENDANCE CLOCK IN/OUT TAB
  Widget _buildAttendanceTab() {
    return Center(
      child: Padding(
        padding: AppSpacing.pAll24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.pAll24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isClockedIn ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.warningOrange.withValues(alpha: 0.1),
              ),
              child: Icon(
                _isClockedIn ? Icons.verified_user_rounded : Icons.lock_clock_rounded,
                size: 80,
                color: _isClockedIn ? AppColors.successGreen : AppColors.warningOrange,
              ),
            ),
            AppSpacing.gapH24,
            Text(
              _isClockedIn ? 'Clocked In (Active Duty)' : 'Not Clocked In (Off Duty)',
              style: AppTypography.h2,
            ),
            AppSpacing.gapH8,
            Text(
              'Location: Mogadishu Bus Hub Depot',
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
            ),
            AppSpacing.gapH32,

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('SHIFT CLOCK-IN', style: AppTypography.label.copyWith(color: Colors.grey)),
                    AppSpacing.gapH4,
                    Text(_clockInTime, style: AppTypography.h3),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                Column(
                  children: [
                    Text('SHIFT CLOCK-OUT', style: AppTypography.label.copyWith(color: Colors.grey)),
                    AppSpacing.gapH4,
                    Text(_clockOutTime, style: AppTypography.h3),
                  ],
                )
              ],
            ),

            AppSpacing.gapH48,
            GestureDetector(
              onTap: () => _toggleAttendance(!_isClockedIn),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isClockedIn ? AppColors.errorRed : AppColors.successGreen,
                  boxShadow: [
                    BoxShadow(
                      color: (_isClockedIn ? AppColors.errorRed : AppColors.successGreen).withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 6,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isClockedIn ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isClockedIn ? 'KA BAX\n(Clock Out)' : 'BILAAW\n(Clock In)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

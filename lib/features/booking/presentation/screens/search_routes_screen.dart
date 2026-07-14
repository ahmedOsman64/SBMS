import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/glass_container.dart';
import '../../../../core/shared/widgets/text_fields.dart';
import '../../../../core/shared/widgets/passenger_nav_bar.dart';

class SearchRoutesScreen extends StatefulWidget {
  const SearchRoutesScreen({super.key});

  @override
  State<SearchRoutesScreen> createState() => _SearchRoutesScreenState();
}

class _SearchRoutesScreenState extends State<SearchRoutesScreen> {
  final _depController = TextEditingController(text: 'Mogadishu');
  final _arrController = TextEditingController(text: 'Garowe');
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _depController.dispose();
    _arrController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Search Routes'),
      ),
      body: Container(
        decoration: isDark ? null : const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightBackground, Color(0xFFE0F2FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: AppSpacing.pAll16,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.gapH24,
              Text(
                'Where are you travelling today?',
                style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
              ),
              AppSpacing.gapH8,
              const Text('Book your bus seats safely with real-time tracking.'),
              AppSpacing.gapH32,

              // Glassmorphic Search Form Box
              GlassContainer(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'From (Departure City)',
                      hintText: 'e.g. Mogadishu',
                      controller: _depController,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    AppSpacing.gapH16,
                    
                    // Interchanging button visual
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: () {
                            final tmp = _depController.text;
                            _depController.text = _arrController.text;
                            _arrController.text = tmp;
                          },
                          icon: const Icon(Icons.swap_vert_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH8,

                    AppTextField(
                      label: 'To (Arrival City)',
                      hintText: 'e.g. Garowe',
                      controller: _arrController,
                      prefixIcon: Icons.location_on_rounded,
                    ),
                    AppSpacing.gapH20,

                    // Date Select Trigger Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Travel Date',
                          style: AppTypography.label,
                        ),
                        AppSpacing.gapH8,
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: AppSpacing.radiusMedium,
                          child: Container(
                            padding: AppSpacing.pAll16,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                              borderRadius: AppSpacing.radiusMedium,
                              color: isDark ? AppColors.darkSurface : AppColors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                                AppSpacing.gapW16,
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: AppTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH32,

                    AppButton(
                      text: 'Find Scheduled Buses',
                      icon: Icons.search_rounded,
                      onPressed: () {
                        context.push(
                          '/booking-routes-details?departure=${_depController.text.trim()}&arrival=${_arrController.text.trim()}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PassengerNavBar(currentIndex: 1),
    );
  }
}

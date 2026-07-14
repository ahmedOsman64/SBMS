import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/wallet_service.dart';
import '../../../../core/shared/utils/validators.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/dialogs.dart';
import '../../../../core/shared/widgets/text_fields.dart';
import '../controllers/booking_controller.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final state = ref.read(bookingFlowControllerProvider);
    
    if (state.paymentMethod != 'wallet') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    // Call verify push notification
    if (state.paymentMethod != 'wallet') {
      // Simulate Push Mobile Pin input dialog
      final pinVerified = await _showSimulatedMobileMoneyDialog();
      if (!pinVerified) return;
    }

    // Trigger repository booking and seat occupancy
    await ref.read(bookingFlowControllerProvider.notifier).confirmBooking();
    
    final finalState = ref.read(bookingFlowControllerProvider);
    if (finalState.completedBooking != null && mounted) {
      context.go('/booking-confirmation');
    } else if (finalState.error != null && mounted) {
      AppDialogs.showError(
        context: context,
        title: 'Payment Failed',
        message: finalState.error!.message,
      );
    }
  }

  Future<bool> _showSimulatedMobileMoneyDialog() async {
    final pinController = TextEditingController();
    final otpKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          title: const Text('Confirm Mobile Payment'),
          content: Form(
            key: otpKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('A USSD push message was sent to your phone. Enter your 4-digit PIN to authorize payment.'),
                AppSpacing.gapH16,
                AppTextField(
                  label: 'PIN Code',
                  hintText: 'xxxx',
                  controller: pinController,
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  validator: (val) => FormValidators.validateOTP(context, val, length: 4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (otpKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingFlowControllerProvider);
    final walletBalance = ref.watch(walletServiceProvider);
    final trip = state.selectedTrip;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (trip == null) {
      return const Scaffold(body: Center(child: Text('No trip active.')));
    }

    final totalAmount = trip.price * state.selectedSeats.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Choose Payment')),
      body: SingleChildScrollView(
        padding: AppSpacing.pAll16,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket details overview
              Card(
                child: Padding(
                  padding: AppSpacing.pAll16,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${trip.departureCity} to ${trip.arrivalCity}'),
                        ],
                      ),
                      AppSpacing.gapH8,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Selected Seats', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(state.selectedSeats.join(', ')),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Price', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '\$${totalAmount.toStringAsFixed(2)}',
                            style: AppTypography.subtitle.copyWith(color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapH24,
              
              const Text('Payment Methods', style: AppTypography.subtitle),
              AppSpacing.gapH12,
              
              // 1. Wallet Balance Selector
              Material(
                color: state.paymentMethod == 'wallet'
                    ? AppColors.primaryBlue.withValues(alpha: 0.08)
                    : (isDark ? AppColors.darkSurface : AppColors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.radiusMedium,
                  side: BorderSide(
                    color: state.paymentMethod == 'wallet'
                        ? AppColors.primaryBlue
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: state.paymentMethod == 'wallet' ? 1.8 : 1.0,
                  ),
                ),
                child: InkWell(
                  onTap: () => ref.read(bookingFlowControllerProvider.notifier).selectPaymentMethod('wallet'),
                  borderRadius: AppSpacing.radiusMedium,
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryBlue),
                    title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Balance: \$${walletBalance.toStringAsFixed(2)}'),
                    trailing: state.paymentMethod == 'wallet'
                        ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                        : null,
                  ),
                ),
              ),
              AppSpacing.gapH16,
              
              // 2. Somali Mobile Payments (EVC Plus, Zaad, Sahal)
              MobileMoneyButton(
                providerName: 'EVC Plus',
                subtitle: 'Hormuud Telecom (Somalia)',
                isSelected: state.paymentMethod == 'evc_plus',
                onTap: () => ref.read(bookingFlowControllerProvider.notifier).selectPaymentMethod('evc_plus'),
              ),
              AppSpacing.gapH12,
              MobileMoneyButton(
                providerName: 'Zaad',
                subtitle: 'Telesom (Somaliland)',
                isSelected: state.paymentMethod == 'zaad',
                onTap: () => ref.read(bookingFlowControllerProvider.notifier).selectPaymentMethod('zaad'),
              ),
              AppSpacing.gapH12,
              MobileMoneyButton(
                providerName: 'Sahal',
                subtitle: 'Golis Telecom (Puntland)',
                isSelected: state.paymentMethod == 'sahal',
                onTap: () => ref.read(bookingFlowControllerProvider.notifier).selectPaymentMethod('sahal'),
              ),
              
              if (state.paymentMethod != 'wallet') ...[
                AppSpacing.gapH24,
                AppTextField(
                  label: 'Payment Phone Number',
                  hintText: 'e.g. 615123456',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  validator: (val) => FormValidators.validateSomaliPhone(context, val),
                ),
              ],
              
              AppSpacing.gapH32,
              AppButton(
                text: 'Pay \$${totalAmount.toStringAsFixed(2)}',
                isLoading: state.isLoading,
                onPressed: _processPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

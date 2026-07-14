import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/wallet_service.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/dialogs.dart';
import '../../../../core/shared/widgets/text_fields.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _showDepositDialog() async {
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          title: const Text('Top up Wallet'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter amount in USD (\$) to top up using Somali Mobile Money (EVC Plus, Sahal, Zaad).'),
                AppSpacing.gapH16,
                AppTextField(
                  label: 'Amount (\$)',
                  hintText: 'e.g. 20',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Required';
                    final parsed = double.tryParse(val);
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                    return null;
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(_amountController.text.trim());
                  await ref.read(walletServiceProvider.notifier).deposit(amount);
                  _amountController.clear();
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppDialogs.showSuccess(
                      context: context,
                      title: 'Top Up Successful',
                      message: '\$$amount has been credited to your wallet balance.',
                    );
                  }
                }
              },
              child: const Text('Top Up'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(walletServiceProvider);
    final walletService = ref.watch(walletServiceProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('My Wallet')),
      body: SingleChildScrollView(
        padding: AppSpacing.pAll16,
        child: Column(
          children: [
            // Balance Card (Premium Blue Gradient Box)
            Container(
              width: double.infinity,
              padding: AppSpacing.pAll24,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppSpacing.radiusLarge,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  AppSpacing.gapH8,
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: AppTypography.h1.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.gapH24,
                  AppButton(
                    text: 'Deposit Money',
                    type: ButtonType.secondary,
                    onPressed: _showDepositDialog,
                  ),
                ],
              ),
            ),
            AppSpacing.gapH24,
            
            const Align(
              alignment: Alignment.centerLeft,
              key: ValueKey('transaction_history_header'),
              child: Text('Transaction History', style: AppTypography.subtitle),
            ),
            AppSpacing.gapH12,

            // Transaction log list
            walletService.transactions.isEmpty
                ? const Card(
                    child: Padding(
                      padding: AppSpacing.pAll24,
                      child: Center(child: Text('No transactions recorded yet.')),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: walletService.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = walletService.transactions[index];
                      final isDeposit = tx.type == 'deposit';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDeposit ? AppColors.successGreen.withValues(alpha: 0.1) : AppColors.errorRed.withValues(alpha: 0.1),
                            child: Icon(
                              isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isDeposit ? AppColors.successGreen : AppColors.errorRed,
                            ),
                          ),
                          title: Text(isDeposit ? 'Deposit Credit' : 'Ticket Purchase'),
                          subtitle: Text(tx.date.toString().substring(0, 16)),
                          trailing: Text(
                            '${isDeposit ? "+" : "-"}\$${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDeposit ? AppColors.successGreen : AppColors.errorRed,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

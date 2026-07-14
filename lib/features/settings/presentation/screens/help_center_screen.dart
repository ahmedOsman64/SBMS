import 'package:flutter/material.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: AppSpacing.pAll16,
        children: [
          const Text('Frequently Asked Questions', style: AppTypography.subtitle),
          AppSpacing.gapH12,
          _faqItem(
            'How do I pay for my tickets?',
            'You can pay using either your in-app wallet balance or directly with Somali Mobile Money (EVC Plus, Sahal, Zaad) during seat checkout.',
          ),
          _faqItem(
            'Do I need internet at the bus station?',
            'No! Once booked, your ticket QR code is saved locally on your device. You can open "My Tickets" and present it to the conductor completely offline.',
          ),
          _faqItem(
            'How do I cancel my booking?',
            'You can cancel bookings at least 2 hours before departure from your Profile -> Travel History section. Refunds will be credited to your wallet.',
          ),
          _faqItem(
            'What happens if the bus is delayed?',
            'You will receive real-time push notification updates regarding any bus schedule shifts. You can also view active bus status in the app.',
          ),
          AppSpacing.gapH24,
          
          const Text('Support Channels', style: AppTypography.subtitle),
          AppSpacing.gapH12,
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_rounded, color: AppColors.primaryBlue),
                  title: const Text('Call Helpline'),
                  subtitle: const Text('Local toll-free helpline: 444'),
                  onTap: () {
                    // helpline dial simulator
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue),
                  title: const Text('Live Mock Chat Support'),
                  subtitle: const Text('Chat with automated agent support'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Helpline live chat is simulated.')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}

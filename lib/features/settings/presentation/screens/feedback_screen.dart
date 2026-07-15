import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/dialogs.dart';
import '../../../../core/shared/widgets/text_fields.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  String _selectedCategory = 'app_experience';
  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'app_experience', 'label': 'App Experience'},
    {'value': 'bus_quality', 'label': 'Bus Quality & Seating'},
    {'value': 'conductor_driver', 'label': 'Driver or Conductor'},
    {'value': 'delay', 'label': 'Schedules & Delays'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = ref.read(supabaseServiceProvider).client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        // Send to Supabase
        await supabase.from('feedback').insert({
          'user_id': userId,
          'category': _selectedCategory,
          'rating': _selectedRating,
          'comment': comment,
        });
      } else {
        throw Exception('User session not found. Please log in again.');
      }

      if (mounted) {
        await AppDialogs.showSuccess(
          context: context,
          title: 'Feedback Submitted',
          message: 'Thank you for your feedback! We constantly improve Somali Smart Bus services.',
          onPressed: () => context.pop(),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(
          context: context,
          title: 'Error',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Send Feedback')),
      body: SingleChildScrollView(
        padding: AppSpacing.pAll24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate Your Journey Experience', style: AppTypography.subtitle),
            AppSpacing.gapH12,
            
            // 5 Star rating buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final ratingValue = index + 1;
                final isSelected = ratingValue <= _selectedRating;
                
                return IconButton(
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40.0,
                    color: AppColors.accentGold,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = ratingValue;
                    });
                  },
                );
              }),
            ),
            AppSpacing.gapH24,
            
            const Text('Category', style: AppTypography.label),
            AppSpacing.gapH8,
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat['value'],
                  child: Text(cat['label']!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            AppSpacing.gapH24,
            
            AppTextField(
              label: 'Comments & Suggestions',
              hintText: 'Share your experience with us...',
              controller: _commentController,
              keyboardType: TextInputType.multiline,
            ),
            AppSpacing.gapH32,
            
            AppButton(
              text: 'Submit Feedback',
              isLoading: _isLoading,
              onPressed: _submitFeedback,
            ),
          ],
        ),
      ),
    );
  }
}

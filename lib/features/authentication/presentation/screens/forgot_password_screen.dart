import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/localization/localization_provider.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/utils/validators.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/dialogs.dart';
import '../../../../core/shared/widgets/text_fields.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        await ref.read(authServiceProvider).resetPassword(email);
        
        if (mounted) {
          await AppDialogs.showSuccess(
            context: context,
            title: 'Recovery Email Sent',
            message: 'Please check your email inbox for password recovery instructions.',
            onPressed: () => context.go('/login'),
          );
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showError(
            context: context,
            title: 'Error Encountered',
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pAll24,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapH24,
                Text(
                  context.tr('forgot_password_title'),
                  style: AppTypography.h2,
                ),
                AppSpacing.gapH8,
                Text(
                  context.tr('forgot_password_subtitle'),
                  style: AppTypography.bodyMedium,
                ),
                AppSpacing.gapH32,
                AppTextField(
                  label: context.tr('email'),
                  hintText: context.tr('email_hint'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (val) => FormValidators.validateEmail(context, val),
                ),
                AppSpacing.gapH32,
                AppButton(
                  text: context.tr('send_otp'),
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

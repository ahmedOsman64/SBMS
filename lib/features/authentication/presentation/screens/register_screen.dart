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
import '../../../../core/shared/widgets/error_widgets.dart';
import '../../../../core/shared/widgets/text_fields.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final fullName = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();

      // Only passengers can self-register
      await ref.read(authNotifierProvider.notifier).signUp(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber,
          );

      final authState = ref.read(authNotifierProvider);
      if (authState.valueOrNull != null) {
        if (mounted) {
          context.push('/otp', extra: email);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.tr('register')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pAll24,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('register_title'), style: AppTypography.h2),
                AppSpacing.gapH8,
                Text(
                  context.tr('register_subtitle'),
                  style: AppTypography.bodyMedium,
                ),
                AppSpacing.gapH16,

                // Passenger-only badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.radiusMedium,
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin_rounded,
                          color: AppColors.primaryBlue, size: 20),
                      AppSpacing.gapW12,
                      Expanded(
                        child: Text(
                          context.tr('register_passenger_only'),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH24,

                if (authState.hasError) ...[
                  InlineErrorCard(message: authState.error.toString()),
                  AppSpacing.gapH24,
                ],

                AppTextField(
                  label: context.tr('full_name'),
                  hintText: context.tr('full_name_hint'),
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (val) =>
                      FormValidators.validateRequired(context, val),
                ),
                AppSpacing.gapH20,
                AppTextField(
                  label: context.tr('email'),
                  hintText: context.tr('email_hint'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (val) =>
                      FormValidators.validateEmail(context, val),
                ),
                AppSpacing.gapH20,
                AppTextField(
                  label: context.tr('phone_number'),
                  hintText: context.tr('phone_number_hint'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (val) =>
                      FormValidators.validateSomaliPhone(context, val),
                ),
                AppSpacing.gapH20,
                AppTextField(
                  label: context.tr('password'),
                  hintText: context.tr('password_hint'),
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outlined,
                  validator: (val) =>
                      FormValidators.validatePassword(context, val),
                ),
                AppSpacing.gapH20,
                AppTextField(
                  label: context.tr('confirm_password'),
                  hintText: context.tr('confirm_password_hint'),
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_clock_outlined,
                  validator: (val) =>
                      FormValidators.validateConfirmPassword(
                    context,
                    val,
                    _passwordController.text,
                  ),
                ),
                AppSpacing.gapH32,
                AppButton(
                  text: context.tr('register'),
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                AppSpacing.gapH24,
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      context.tr('already_have_account'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

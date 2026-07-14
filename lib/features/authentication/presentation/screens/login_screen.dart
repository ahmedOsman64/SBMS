import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/localization/localization_provider.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/utils/validators.dart';
import '../../../../core/shared/widgets/bottom_sheets.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/error_widgets.dart';
import '../../../../core/shared/widgets/text_fields.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Sign in via AuthNotifier
      await ref.read(authNotifierProvider.notifier).signIn(email, password);

      final authState = ref.read(authNotifierProvider);
      final user = authState.valueOrNull;
      if (user != null) {
        if (mounted) {
          // Each role has its own dashboard
          context.go(user.role.dashboardRoute);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () => AppBottomSheets.showLanguageSelector(context),
          ),
        ],
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
                  context.tr('login_title'),
                  style: AppTypography.h1,
                ),
                AppSpacing.gapH8,
                Text(
                  context.tr('login_subtitle'),
                  style: AppTypography.bodyLarge,
                ),
                AppSpacing.gapH32,
                
                // Show errors if signin fails
                if (authState.hasError) ...[
                  InlineErrorCard(message: authState.error.toString()),
                  AppSpacing.gapH24,
                ],

                AppTextField(
                  label: context.tr('email'),
                  hintText: context.tr('email_hint'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (val) => FormValidators.validateEmail(context, val),
                ),
                AppSpacing.gapH24,
                AppTextField(
                  label: context.tr('password'),
                  hintText: context.tr('password_hint'),
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outlined,
                  validator: (val) => FormValidators.validatePassword(context, val),
                ),
                AppSpacing.gapH12,
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      context.tr('forgot_password'),
                      style: AppTypography.label.copyWith(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
                AppSpacing.gapH24,
                AppButton(
                  text: context.tr('login'),
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                AppSpacing.gapH32,
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(
                      context.tr('dont_have_account'),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryBlue),
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

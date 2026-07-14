import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/localization/localization_provider.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/dialogs.dart';
import '../../../../core/shared/widgets/text_fields.dart';

class OTPScreen extends ConsumerStatefulWidget {
  final String email;

  const OTPScreen({super.key, required this.email});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final int _otpLength = 6;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verify() async {
    final code = _otpCode;
    if (code.length != _otpLength) {
      AppDialogs.showError(
        context: context,
        title: 'Invalid Code',
        message: 'Please enter the complete 6-digit verification code.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(authServiceProvider).verifyOTP(
            email: widget.email,
            token: code,
          );

      if (success && mounted) {
        await AppDialogs.showSuccess(
          context: context,
          title: 'Account Verified',
          message: 'Your registration verification is complete. Welcome to SBMS!',
          onPressed: () => context.go('/home'),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(
          context: context,
          title: 'Verification Failed',
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pAll24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.gapH24,
              Text(
                context.tr('otp_verification'),
                style: AppTypography.h2,
              ),
              AppSpacing.gapH8,
              Text(
                '${context.tr('otp_subtitle')}\n${widget.email}',
                style: AppTypography.bodyMedium,
              ),
              AppSpacing.gapH48,
              
              // Multi-digit OTP components
              OTPFields(
                controllers: _controllers,
                focusNodes: _focusNodes,
                length: _otpLength,
              ),
              
              AppSpacing.gapH48,
              AppButton(
                text: context.tr('verify'),
                isLoading: _isLoading,
                onPressed: _verify,
              ),
              AppSpacing.gapH24,
              Center(
                child: TextButton(
                  onPressed: () {
                    // Resend OTP code mock
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('A new verification code has been sent.')),
                    );
                  },
                  child: Text(
                    context.tr('resend_otp'),
                    style: AppTypography.button.copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

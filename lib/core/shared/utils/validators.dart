import 'package:flutter/material.dart';
import '../localization/localization_provider.dart';

class FormValidators {
  FormValidators._();

  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('field_required');
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return context.tr('invalid_email');
    }
    return null;
  }

  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('field_required');
    }
    if (value.length < 6) {
      return context.tr('password_too_short');
    }
    return null;
  }

  static String? validateConfirmPassword(BuildContext context, String? value, String password) {
    if (value == null || value.isEmpty) {
      return context.tr('field_required');
    }
    if (value != password) {
      return context.tr('passwords_dont_match');
    }
    return null;
  }

  static String? validateSomaliPhone(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('field_required');
    }
    // Remove white spaces or hyphens
    final cleaned = value.replaceAll(RegExp(r'\s+|-'), '');
    
    // Somali numbers can start with +252, 252, 061, 61, 090, 90, 062, 62, 063, 63, etc.
    // Lengths: 
    // Local: 9 digits (e.g., 615123456 or 685123456 or 907123456)
    // Local with 0: 10 digits (e.g., 0615123456)
    // International: 12 digits (252615123456) or 13 digits (+252615123456)
    final phoneRegExp = RegExp(r'^(\+?252|0)?[679]\d{8}$');
    
    if (!phoneRegExp.hasMatch(cleaned)) {
      return context.tr('invalid_phone');
    }
    return null;
  }

  static String? validateRequired(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('field_required');
    }
    return null;
  }

  static String? validateOTP(BuildContext context, String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('field_required');
    }
    if (value.trim().length != length || int.tryParse(value) == null) {
      return 'Enter a valid $length digit verification code';
    }
    return null;
  }
}

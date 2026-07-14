import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing Units
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Horizontal Gaps (SizedBox)
  static const SizedBox gapW4 = SizedBox(width: xxs);
  static const SizedBox gapW8 = SizedBox(width: xs);
  static const SizedBox gapW12 = SizedBox(width: sm);
  static const SizedBox gapW16 = SizedBox(width: md);
  static const SizedBox gapW20 = SizedBox(width: 20.0);
  static const SizedBox gapW24 = SizedBox(width: lg);
  static const SizedBox gapW32 = SizedBox(width: xl);

  // Vertical Gaps (SizedBox)
  static const SizedBox gapH4 = SizedBox(height: xxs);
  static const SizedBox gapH8 = SizedBox(height: xs);
  static const SizedBox gapH12 = SizedBox(height: sm);
  static const SizedBox gapH16 = SizedBox(height: md);
  static const SizedBox gapH20 = SizedBox(height: 20.0);
  static const SizedBox gapH24 = SizedBox(height: lg);
  static const SizedBox gapH32 = SizedBox(height: xl);
  static const SizedBox gapH48 = SizedBox(height: xxl);

  // Border Radii
  static const double rSmall = 6.0;
  static const double rMedium = 12.0;
  static const double rLarge = 18.0;
  static const double rXLarge = 24.0;
  static const double rCircular = 999.0;

  static BorderRadius radiusSmall = BorderRadius.circular(rSmall);
  static BorderRadius radiusMedium = BorderRadius.circular(rMedium);
  static BorderRadius radiusLarge = BorderRadius.circular(rLarge);
  static BorderRadius radiusXLarge = BorderRadius.circular(rXLarge);
  static BorderRadius radiusCircular = BorderRadius.circular(rCircular);

  // Padding presets
  static const EdgeInsets pAll4 = EdgeInsets.all(xxs);
  static const EdgeInsets pAll8 = EdgeInsets.all(xs);
  static const EdgeInsets pAll12 = EdgeInsets.all(sm);
  static const EdgeInsets pAll16 = EdgeInsets.all(md);
  static const EdgeInsets pAll20 = EdgeInsets.all(20.0);
  static const EdgeInsets pAll24 = EdgeInsets.all(lg);

  static const EdgeInsets pHorizontal8 = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets pHorizontal16 = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pHorizontal24 = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets pVertical8 = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets pVertical16 = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets pVertical24 = EdgeInsets.symmetric(vertical: lg);
}

import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const brandHeading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);

  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyBold = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400);
  static const buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}

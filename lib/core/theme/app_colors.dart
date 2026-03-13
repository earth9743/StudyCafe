import 'package:flutter/material.dart';

/// Sophisticated Navy 디자인 시스템 색상 팔레트
class AppColors {
  AppColors._();

  // Primary Accent (Navy)
  static const Color primary = Color(0xFF19376D);
  static const Color primaryLight = Color(0xFF2E4F8E);
  static const Color primaryDark = Color(0xFF0F2340);

  // Secondary Neutral (Gray)
  static const Color secondary = Color(0xFFEDEDED);
  static const Color secondaryDark = Color(0xFFBDBDBD);

  // Base
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color card = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textHint = Color(0xFFA0AEC0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status - 혼잡도
  static const Color crowdLow = Color(0xFF38A169);      // 여유 (녹색)
  static const Color crowdModerate = Color(0xFFDD6B20);  // 보통 (주황)
  static const Color crowdHigh = Color(0xFFE53E3E);      // 혼잡 (빨강)
  static const Color crowdUnknown = Color(0xFFA0AEC0);   // 모름 (회색)

  // Status - 콘센트
  static const Color outletAvailable = Color(0xFF38A169);
  static const Color outletLimited = Color(0xFFDD6B20);
  static const Color outletUnavailable = Color(0xFFE53E3E);

  // Status - 소음
  static const Color noiseQuiet = Color(0xFF38A169);
  static const Color noiseModerate = Color(0xFFDD6B20);
  static const Color noiseLoud = Color(0xFFE53E3E);

  // Functional
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF38A169);
  static const Color warning = Color(0xFFDD6B20);
  static const Color info = Color(0xFF3182CE);

  // Divider & Border
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);

  // Social Login
  static const Color kakaoYellow = Color(0xFFFEE500);
  static const Color kakaoBlack = Color(0xFF191919);
  static const Color googleWhite = Color(0xFFFFFFFF);
}

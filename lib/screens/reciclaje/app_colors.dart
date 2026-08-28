import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---- Marca UPSA: verde (primario) + dorado (secundario) ----
  static const Color primary = Color(0xFF006B4F);
  static const Color primaryDark = Color(0xFF004D3A);
  static const Color primaryLight = Color(0xFFE6F3EF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Dorado institucional. Antes se repetía como Color(0xFFD6A100) suelto
  /// en varias pantallas (fixture, tabla, marcador con penales); ahora es
  /// el color secundario formal del esquema.
  static const Color secondary = Color(0xFFD6A100);
  static const Color secondaryDark = Color(0xFF9C7600);
  static const Color secondaryLight = Color(0xFFFCF1D6);
  static const Color onSecondary = Color(0xFF3A2C00);

  /// Acento terciario (azul informativo) para variar la jerarquía sin
  /// competir con el verde/dorado institucional.
  static const Color tertiary = Color(0xFF2563EB);
  static const Color tertiaryLight = Color(0xFFEAF1FF);

  static const Color background = Color(0xFFF6F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF9FAFB);
  static const Color surfaceContainer = Color(0xFFF1F4F2);
  static const Color surfaceContainerHigh = Color(0xFFE9EEEC);

  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFEAF7EE);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF7E6);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFDECEC);
  static const Color onDanger = Color(0xFFFFFFFF);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEAF1FF);

  static const Color dark = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);
}

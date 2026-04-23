import 'package:flutter/material.dart';

/// PagentZ Atlas v3 — refined design system.
///
/// Aesthetic: **Linear / Vercel-inspired premium admin console**.
///   • Deep, sophisticated sidebar (zinc-950 with subtle warm tint)
///   • Pure white content surface for high contrast
///   • Single indigo accent (Apple-style #5E5CE6)
///   • Subtle borders, generous whitespace
class AtlasColors {
  AtlasColors._();

  // ─── Sidebar (always dark, regardless of theme) ───
  static const sidebarBg = Color(0xFF09090B);          // zinc-950
  static const sidebarBgElevated = Color(0xFF18181B);  // zinc-900
  static const sidebarHover = Color(0xFF27272A);       // zinc-800
  static const sidebarText = Color(0xFFFAFAFA);        // zinc-50
  static const sidebarTextMuted = Color(0xFFA1A1AA);   // zinc-400
  static const sidebarTextSubtle = Color(0xFF71717A);  // zinc-500
  static const sidebarBorder = Color(0xFF27272A);      // zinc-800
  static const sidebarBorderSubtle = Color(0xFF1F1F23);

  // ─── Page surface ───
  static const pageBg = Color(0xFFFAFAFA);             // zinc-50
  static const cardBg = Colors.white;
  static const cardBgRaised = Colors.white;
  static const cardBorder = Color(0xFFE4E4E7);         // zinc-200
  static const cardBorderSubtle = Color(0xFFF4F4F5);   // zinc-100
  static const divider = Color(0xFFE4E4E7);

  // ─── Text ───
  static const textPrimary = Color(0xFF09090B);        // zinc-950
  static const textSecondary = Color(0xFF52525B);      // zinc-600
  static const textMuted = Color(0xFF71717A);          // zinc-500
  static const textSubtle = Color(0xFFA1A1AA);         // zinc-400
  static const textInverse = Color(0xFFFAFAFA);

  // ─── Accent — Apple/iOS indigo ───
  static const accent = Color(0xFF5E5CE6);
  static const accentHover = Color(0xFF4F46E5);
  static const accentActive = Color(0xFF4338CA);
  static const accentSoft = Color(0xFFEEF0FF);         // indigo-50 tint
  static const accentMuted = Color(0xFFC7CCFF);

  // ─── Semantic colors ───
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFEFF6FF);

  // ─── Tables ───
  static const tableHeaderBg = Color(0xFFFAFAFA);
  static const tableRowHover = Color(0xFFF9F9FA);
  static const tableBorder = Color(0xFFE4E4E7);
  static const tableStripe = Color(0xFFFAFAFA);

  // ─── Shadows (subtle, layered like Linear) ───
  static const shadowSm = Color(0x0A000000);
  static const shadowMd = Color(0x14000000);
  static const shadowLg = Color(0x1F000000);

  // ─── Plan/role/status pill palettes ───
  static const pillNeutral = Color(0xFFF4F4F5);
  static const pillNeutralText = Color(0xFF52525B);
}

/// Standard elevations as ready-to-use BoxShadow lists.
class AtlasElevation {
  AtlasElevation._();

  static const sm = [
    BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const md = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x06000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const lg = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const xl = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
}

/// Standard radii.
class AtlasRadius {
  AtlasRadius._();
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 10.0;
  static const xl = 12.0;
  static const xxl = 16.0;
  static const round = 999.0;
}

/// Standard spacing — 4px scale.
class AtlasSpace {
  AtlasSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;
}

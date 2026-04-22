import 'package:flutter/material.dart';

/// Atlas color palette — intentionally different from the customer-facing
/// PagentZ app to keep the two apps visually distinct.
///
/// PagentZ uses indigo/purple. Atlas uses **dark slate sidebar + emerald accents**
/// to feel like a serious admin / ops console.
class AtlasColors {
  AtlasColors._();

  // ─── Sidebar / Top nav (always dark, even in light mode) ───
  static const sidebarBg = Color(0xFF0F172A);        // slate-900
  static const sidebarBgHover = Color(0xFF1E293B);   // slate-800
  static const sidebarText = Color(0xFFE2E8F0);      // slate-200
  static const sidebarTextMuted = Color(0xFF94A3B8); // slate-400
  static const sidebarBorder = Color(0xFF1E293B);    // slate-800

  // ─── Page surface ───
  static const pageBg = Color(0xFFF8FAFC);           // slate-50
  static const cardBg = Colors.white;
  static const cardBorder = Color(0xFFE2E8F0);       // slate-200

  // ─── Text ───
  static const textPrimary = Color(0xFF0F172A);      // slate-900
  static const textSecondary = Color(0xFF475569);    // slate-600
  static const textMuted = Color(0xFF94A3B8);        // slate-400

  // ─── Accent (emerald — ops/health green) ───
  static const accent = Color(0xFF059669);           // emerald-600
  static const accentHover = Color(0xFF047857);      // emerald-700
  static const accentSoft = Color(0xFFD1FAE5);       // emerald-100

  // ─── Status colors ───
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);

  // ─── Status pill backgrounds ───
  static const successSoft = Color(0xFFD1FAE5);
  static const warningSoft = Color(0xFFFEF3C7);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const infoSoft = Color(0xFFE0F2FE);

  // ─── Table ───
  static const tableHeaderBg = Color(0xFFF1F5F9);    // slate-100
  static const tableRowHover = Color(0xFFF8FAFC);    // slate-50
  static const tableBorder = Color(0xFFE2E8F0);
}

import 'package:flutter/material.dart';
import 'atlas_colors.dart';

/// Atlas typography scale — Inter-inspired, Apple-style hierarchy.
class AtlasText {
  AtlasText._();

  // Tight letter-spacing for headings, normal for body
  static const _heading = -0.2;
  static const _body = 0.0;

  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.2,
    color: AtlasColors.textPrimary,
  );

  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: _heading,
    height: 1.25,
    color: AtlasColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: _heading,
    height: 1.3,
    color: AtlasColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: _heading,
    height: 1.35,
    color: AtlasColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AtlasColors.textMuted,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: _body,
    height: 1.5,
    color: AtlasColors.textPrimary,
  );

  static const bodyMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: _body,
    height: 1.5,
    color: AtlasColors.textSecondary,
  );

  static const small = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: _body,
    height: 1.45,
    color: AtlasColors.textSecondary,
  );

  static const smallMuted = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AtlasColors.textMuted,
  );

  static const tiny = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: AtlasColors.textMuted,
  );

  static const button = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    color: AtlasColors.textPrimary,
  );

  static const buttonStrong = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.0,
    color: AtlasColors.textInverse,
  );

  // Monospace for IDs, codes, key-value displays
  static const mono = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
    color: AtlasColors.textPrimary,
    fontFamily: 'monospace',
  );

  // Sidebar text styles
  static const sidebarBrand = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AtlasColors.sidebarText,
  );

  static const sidebarItem = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
    color: AtlasColors.sidebarText,
  );

  static const sidebarItemActive = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    color: AtlasColors.sidebarText,
  );

  static const sidebarSection = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AtlasColors.sidebarTextSubtle,
  );
}

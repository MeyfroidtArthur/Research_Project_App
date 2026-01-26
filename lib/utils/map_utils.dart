import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math';

class MapUtils {
  static IconConfig getIconConfig(String? iconType) {
    if (iconType == null) {
      return IconConfig(PhosphorIcons.mapPin(), Color(0xFF6B7280));
    }

    switch (iconType.toLowerCase()) {
      case 'parking':
        return IconConfig(PhosphorIcons.car(), Color(0xFF3B82F6)); // Blue
      case 'food':
        return IconConfig(
            PhosphorIcons.hamburger(), Color(0xFFF97316)); // Orange
      case 'drinks':
        return IconConfig(PhosphorIcons.coffee(), Color(0xFFF97316)); // Orange
      case 'info':
        return IconConfig(PhosphorIcons.info(), Color(0xFF06B6D4)); // Cyan
      case 'exit':
        return IconConfig(PhosphorIcons.signOut(), Color(0xFF10B981)); // Green
      case 'emergency_exit':
        return IconConfig(
            PhosphorIcons.fireExtinguisher(), Color(0xFF10B981)); // Green
      case 'hospital':
        return IconConfig(PhosphorIcons.ambulance(), Color(0xFFEC4899)); // Pink
      case 'red_cross':
        return IconConfig(PhosphorIcons.firstAid(), Color(0xFFDC2626)); // Red
      case 'music':
        return IconConfig(
            PhosphorIcons.musicNote(), Color(0xFF8B5CF6)); // Purple
      case 'flag':
        return IconConfig(PhosphorIcons.flag(), Color(0xFF14B8A6)); // Teal
      case 'toilet':
        return IconConfig(
            PhosphorIcons.toilet(), Color(0xFF0EA5E9)); // Sky Blue
      default:
        return IconConfig(PhosphorIcons.mapPin(), Color(0xFF6B7280)); // Gray
    }
  }

  static Widget getMarkerIcon(String? iconType, {double size = 24.0}) {
    final config = getIconConfig(iconType);
    return Container(
      decoration: BoxDecoration(
        color: config.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      padding: EdgeInsets.all(4),
      child: Icon(
        config.icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  static double calculateBearing(
      double startLat, double startLng, double endLat, double endLng) {
    double startLatRad = startLat * (pi / 180.0);
    double startLngRad = startLng * (pi / 180.0);
    double endLatRad = endLat * (pi / 180.0);
    double endLngRad = endLng * (pi / 180.0);

    double dLng = endLngRad - startLngRad;

    double y = sin(dLng) * cos(endLatRad);
    double x = cos(startLatRad) * sin(endLatRad) -
        sin(startLatRad) * cos(endLatRad) * cos(dLng);

    return atan2(y, x);
  }
}

class IconConfig {
  final IconData icon;
  final Color color;

  IconConfig(this.icon, this.color);
}

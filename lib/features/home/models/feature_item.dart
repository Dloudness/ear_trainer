import 'package:flutter/material.dart';

class FeatureItem {
  const FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

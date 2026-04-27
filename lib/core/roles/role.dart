import 'package:flutter/material.dart';

enum UserRole {
  fan('Fan', Icons.sports_soccer, Color(0xFF0D7377)),
  fantasyManager('Fantasy Manager', Icons.bar_chart, Color(0xFF14FFEC)),
  admin('Admin', Icons.admin_panel_settings, Color(0xFFFF6B6B));

  final String label;
  final IconData icon;
  final Color color;

  const UserRole(this.label, this.icon, this.color);
}

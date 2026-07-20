import 'package:flutter/material.dart';

class SidebarMenuItem {
  final String title;
  final Widget targetScreen; 
  final List<int> allowedRoles; 
  final int badgeCount; 

  SidebarMenuItem({
    required this.title,
    required this.targetScreen,
    required this.allowedRoles,
    this.badgeCount = 0,
  });
}
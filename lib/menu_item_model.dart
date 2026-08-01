class SidebarMenuItem {
  final String title;
  final String targetScreen;
  final List<int> allowedRoles; 
  final int badgeCount; 

  SidebarMenuItem({
    required this.title,
    required this.targetScreen,
    required this.allowedRoles,
    this.badgeCount = 0,
  });
}
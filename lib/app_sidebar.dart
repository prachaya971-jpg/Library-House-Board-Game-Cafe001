import 'package:cafa_boardgame/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'menu_item_model.dart';
import 'package:cafa_boardgame/order/advice.dart';

class AppSidebar extends StatefulWidget {
  final int currentRoleId;
  final String currentRouteName;

  const AppSidebar({
    Key? key,
    required this.currentRoleId,
    required this.currentRouteName,
  }) : super(key: key);

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  int _orderCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchOrderCount();
  }

  Future<void> _fetchOrderCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final uri = Uri.parse('${AppConfig.apiBaseUri}/reports/order-count');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (!json['isError']) {
          if (mounted) {
            setState(() {
              var rawCount = json['data']['total_orders'];
              if (rawCount is int) {
                _orderCount = rawCount;
              } else if (rawCount is String) {
                _orderCount = int.tryParse(rawCount) ?? 0;
              } else {
                _orderCount = 0;
              }
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching order count in sidebar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<SidebarMenuItem> allMenus = [
      SidebarMenuItem(
        title: "หน้าเเรก",
        targetScreen: '/home',
        allowedRoles: [1, 2],
      ),
      SidebarMenuItem(
        title: "ขอคำปรึกษา",
        targetScreen: '/advice',
        allowedRoles: [1, 2],
        badgeCount: _orderCount,
      ),
      SidebarMenuItem(
        title: "ออร์เดอร์",
        targetScreen: '/order',
        allowedRoles: [1, 2],
      ),
      SidebarMenuItem(
        title: "จัดการการเพิ่มข้อมูลระบบ",
        targetScreen: '/create',
        allowedRoles: [1], 
      ),
      SidebarMenuItem(
        title: "รายงานข้อมูลระบบ",
        targetScreen: '/reports',
        allowedRoles: [1, 2], 
      ),
    ];

    // กรองเอาเฉพาะเมนูที่ Role ปัจจุบันมีสิทธิ์เข้าถึง
    final visibleMenus = allMenus
        .where((menu) => menu.allowedRoles.contains(widget.currentRoleId))
        .toList();

    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            alignment: Alignment.center,
            child: const Text(
              "Liberty boardgame",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // รายการเมนู
          Expanded(
            child: ListView.builder(
              itemCount: visibleMenus.length,
              itemBuilder: (context, index) {
                final item = visibleMenus[index];
                
                final bool isActive =
                    widget.currentRouteName.trim() == item.title.trim() ||
                    widget.currentRouteName.trim() == item.targetScreen.trim();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      
                      if (!item.allowedRoles.contains(widget.currentRoleId)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('คุณไม่มีสิทธิ์เข้าถึงเมนูนี้'),
                          ),
                        );
                        return;
                      }

                      if (!isActive) {
                        Navigator.pushReplacementNamed(
                          context, 
                          item.targetScreen,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFD49A32)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                color: isActive ? Colors.white : Colors.black87,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          // แสดง Badge สีแดงถ้ามีจำนวนออร์เดอร์มากกว่า 0
                          if (item.badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${item.badgeCount}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ปุ่มออกจากระบบ
          Padding(
            padding: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token');
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/login', 
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  "ออกจากระบบ",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
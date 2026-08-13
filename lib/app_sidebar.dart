import 'package:cafa_boardgame/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'menu_item_model.dart';
import 'package:cafa_boardgame/order/advice.dart';
import 'package:cafa_boardgame/utils/appapi.dart';


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
  int _adviceCount = 0;
  @override
  void initState() {
    super.initState();
    _fetchOrderCount();
    _fetchAdviceCount();
  }

  Future<void> _fetchOrderCount() async {
    try {
    final response = await AppAPI.get('/reports/order-count');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (!json['isError'] && json['data'] != null) {
        if (mounted) {
          setState(() {
            _orderCount = int.tryParse(
                  json['data']['total_orders']?.toString() ?? '0',
                ) ??
                0;
          });
        }
      }
    }
  } catch (e) {
    print("Error fetching order count in sidebar: $e");
  }
  }

Future<void> _fetchAdviceCount() async {
  try {
    final response = await AppAPI.get('/reports/advice-count');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (!json['isError'] && json['data'] != null) {
        if (mounted) {
          setState(() {
            _adviceCount = int.tryParse(
                  json['data']['total_advice']?.toString() ?? '0',
                ) ??
                0;
          });
        }
      }
    }
  } catch (e) {
    print("Error fetching advice count in sidebar: $e");
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
        title: "คำปรึกษา",
        targetScreen: '/advice',
        allowedRoles: [1, 2],
        badgeCount: _adviceCount,
      ),
      SidebarMenuItem(
        title: "ออร์เดอร์",
        targetScreen: '/order',
        allowedRoles: [1, 2],
        badgeCount: _orderCount,
      ),
      SidebarMenuItem(
        title: "เพิ่มข้อมูลประเภทอาหาร",
        targetScreen: '/create',
        allowedRoles: [1], 
      ),
      SidebarMenuItem(
        title: "รายงานข้อมูลอาหาร",
        targetScreen: '/reports',
        allowedRoles: [1, 2], 
      ),
      // เพิ่มข้อมูลประเภทบอร์ดเกม
      SidebarMenuItem(
        title: "เพิ่มข้อมูลบอร์ดเกม",
        targetScreen: '/create_boardgame',
        allowedRoles: [1, 2],
      ),
      // รายงานข้อมูลประเภทบอร์ดเกม
      SidebarMenuItem(
        title: "รายงานข้อมูลบอร์ดเกม",
        targetScreen: '/report_boardgame',
        allowedRoles: [1, 2],
      ),
      //รายงานยืมบอร์ดเกม
      SidebarMenuItem(
        title: "รายงานการยืมบอร์ดเกม",
        targetScreen: '/BgBorrowReportPage',
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
              "Library boardgame",
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
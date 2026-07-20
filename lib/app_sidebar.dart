import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_item_model.dart';
import 'employeemoule/orders.dart';

class AppSidebar extends StatelessWidget {
  final int currentRoleId; // ค่าตัวเลขสิทธิ์พนักงานที่ส่งมาจาก Backend (แกะจาก JWT)
  final String currentRouteName; // ชื่อหน้าปัจจุบันเพื่อแสดงไฮไลท์สีส้ม

  const AppSidebar({
    Key? key,
    required this.currentRoleId,
    required this.currentRouteName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    final List<SidebarMenuItem> allMenus = [
      SidebarMenuItem(
        title: "ออเดอร์",
        targetScreen: const OrderScreen(), 
        allowedRoles: [1, 2], 
      ),
      SidebarMenuItem(
        title: "รายการการส่งคำขอคำปรึกษา",
        targetScreen: const Scaffold(body: Center(child: Text("หน้าขอคำปรึกษา"))),
        allowedRoles: [1, 2],
        badgeCount: 1, 
      ),
      SidebarMenuItem(
        title: "ดูรายการการขาย",
        targetScreen: const Scaffold(body: Center(child: Text("หน้ายอดขายสำหรับผู้จัดการ"))),
        allowedRoles: [2],
      ),
      SidebarMenuItem(
        title: "อัปเดตสถานะวัตถุดิบ",
        targetScreen: const Scaffold(body: Center(child: Text("หน้าวัตถุดิบ"))),
        allowedRoles: [1, 2],
      ),
      SidebarMenuItem(
        title: "รายการการยืมและคืนบอร์ดเกม",
        targetScreen: const Scaffold(body: Center(child: Text("หน้ายืมคืนบอร์ดเกม"))),
        allowedRoles: [1, 2],
      ),
      SidebarMenuItem(
        title: "ขายบอร์ดเกม",
        targetScreen: const Scaffold(body: Center(child: Text("หน้าขายบอร์ดเกม"))),
        allowedRoles: [1, 2],
      ),
    ];

    
    final visibleMenus = allMenus.where((menu) => menu.allowedRoles.contains(currentRoleId)).toList();

    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // ส่วนหัวโลโก้ร้านบอร์ดเกม
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
          
          
          Expanded(
            child: ListView.builder(
              itemCount: visibleMenus.length,
              itemBuilder: (context, index) {
                final item = visibleMenus[index];
                final bool isActive = currentRouteName == item.title;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    onTap: () {
                      if (!isActive) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => item.targetScreen),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        
                        color: isActive ? const Color(0xFFD49A32) : Colors.transparent,
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
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (item.badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${item.badgeCount}",
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          
          Padding(
            padding: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935), // สีแดงปุ่มล็อกเอาท์
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token'); // ลบตั๋วออกจากเครื่อง
                 
                },
                child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
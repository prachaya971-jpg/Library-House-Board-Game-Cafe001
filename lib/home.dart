import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'app_sidebar.dart';
import 'package:cafa_boardgame/dashdorad/revenue_card.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int roleId = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
  }

  
  Future<void> _loadRoleFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      setState(() {
        roleId = decodedToken['emp_role_id'] ?? 1; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          
         AppSidebar(
            currentRoleId: roleId,
            currentRouteName: "หน้าเเรก",
          ),

          // พื้นที่เนื้อหาหลักด้านขวา
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row ส่วนหัว: แสดงชื่อหน้า + การ์ดสรุปรายได้
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      RevenueCard(),
                    ],
                  ),
                  const SizedBox(height: 24),

          
          
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
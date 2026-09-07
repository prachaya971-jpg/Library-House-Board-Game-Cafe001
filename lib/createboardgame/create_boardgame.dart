import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../app_sidebar.dart';
// import 'caeatevariants.dart';
// import 'createoption.dart';
// import 'createtype.dart';
import 'create_boardgametype.dart';

class Createboardgame extends StatefulWidget {
  const Createboardgame({Key? key}) : super(key: key);

  @override
  State<Createboardgame> createState() => _CreateboardgameState();
}

class _CreateboardgameState extends State<Createboardgame> {
  int roleId = 1;
  String? _selectedCreateType;

  final List<Map<String, String>> _createboardgameOptions = [
    {'label': 'เพิ่มประเภทบอร์ดเกม (type)', 'value': 'type'},
    {'label': 'เพิ่มข้อมูลบอร์ดเกม (boardgame)', 'value': 'boardgame'},
    // {'label': 'เพิ่มซีรีย์บอร์ดเกม (series)', 'value': 'series'},
  ];

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

  Widget _buildSelectedForm() {
    switch (_selectedCreateType) {
      case 'type':
        return const CreateBoardgametype();
      case 'boardgame':
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('กำลังพัฒนา'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color.fromARGB(255, 0, 0, 0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar ทางซ้าย
          AppSidebar(
            currentRoleId: roleId,
            currentRouteName: "เพิ่มข้อมูลบอร์ดเกม",
          ),

          // พื้นที่แสดงเนื้อหาฝั่งขวา
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center( 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // ส่วนกล่อง Dropdown เลือกรายการ
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เลือกข้อมูลที่ต้องการเพิ่ม',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCreateType,
                              hint: const Text('--- เลือกรายการ ---'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              items: _createboardgameOptions.map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt['value'],
                                  child: Text(opt['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCreateType = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // แสดงฟอร์มที่เลือกให้อยู่ตรงกลางด้านล่าง
                      if (_selectedCreateType != null) ...[
                        const SizedBox(height: 24),
                        _buildSelectedForm(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../app_sidebar.dart';
import 'report_boardgame_type.dart';
// import '../app_sidebar.dart';
// import 'listvariants.dart';
// import 'listoption.dart';
// import 'listtype.dart';

class reportboardgame extends StatefulWidget {
  const reportboardgame({Key? key}) : super(key: key);

  @override
  State<reportboardgame> createState() => _ReportboardgamePageState();
}

class _ReportboardgamePageState extends State<reportboardgame> {
  int roleId = 1;
  String? _selectedReportType;

  //  รายการประเภทรายงาน/รายการข้อมูลระบบ
  final List<Map<String, String>> _reportOptions = [
    {'label': 'รายการประเภทบอร์ดเกม (Type)', 'value': 'type'},
    // {'label': 'รายการท็อปปิ้ง/ตัวเลือก (Options)', 'value': 'option'},
    // {'label': 'รายการประเภท (Types)', 'value': 'type'},
    // {'label': 'รายการอาหาร (Foods)', 'value': 'food'},
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

  Widget _buildSelectedReport() {
    switch (_selectedReportType) {
      // case 'variants':
      //   return const ListVariants(); 
      // case 'option':
      //   return const ListOptions();
      case 'type':
        return const  ReportBoardgameType();
      case 'food':
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('รายงานข้อมูลระบบอาหาร'),
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
            currentRouteName: "รายงานข้อมูลบอร์ดเกม",
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
                      // ส่วนกล่อง Dropdown เลือกประเภทรายงาน
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
                              'เลือกรายงานที่ต้องการดู',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedReportType,
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
                              items: _reportOptions.map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt['value'],
                                  child: Text(opt['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedReportType = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // แสดงรายงาน/ตารางข้อมูลที่เลือกให้อยู่ตรงกลางด้านล่าง
                      if (_selectedReportType != null) ...[
                        const SizedBox(height: 24),
                        _buildSelectedReport(),
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
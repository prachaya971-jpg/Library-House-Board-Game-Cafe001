import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_sidebar.dart';
import 'emp.dart';
import 'createemp.dart';


class Employee extends StatefulWidget {
  const Employee({super.key});

  @override
  State<Employee> createState() => _EmployeeState();
  
}

class _EmployeeState extends State<Employee> {
  int roleId = 1;
  String _employeeMenu = 'editemp';
    String? _Employee;
   static const List<Map<String, String>> _reportsale = [
    {'label': 'รายการพนักงาน', 'value': 'editemp'},
    {'label': 'เพิ่มพนักงาน', 'value': 'createemp'},
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
      if (mounted) {
        setState(() {
          roleId = decodedToken['emp_role_id'] ?? 1;
          if (roleId != 1 && _employeeMenu == 'createemp') {
            _employeeMenu = 'editemp';
          }
        });
      }
    }
  }


  Widget _buildSelectedReport() {
    switch (_Employee) {
      case 'editemp':
       return const Listemp();
      case 'createemp':
        return const Createemp();
      default:
        return const Listemp();
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
            currentRouteName: "จัดการข้อมูลพนักงาน",
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
                              value: _Employee,
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
                              items: _reportsale.map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt['value'],
                                  child: Text(opt['label']!),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _Employee = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // แสดงรายงาน/ตารางข้อมูลที่เลือกให้อยู่ตรงกลางด้านล่าง
                      if (_Employee != null) ...[
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

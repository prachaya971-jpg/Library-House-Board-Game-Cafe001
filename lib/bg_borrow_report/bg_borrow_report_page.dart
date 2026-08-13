import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import '../app_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';

class BgBorrowReportPage extends StatefulWidget {
  const BgBorrowReportPage({super.key});

  @override
  State<BgBorrowReportPage> createState() => _BgBorrowReportPageState();
}

int roleId = 1;

class _BgBorrowReportPageState extends State<BgBorrowReportPage> {
  bool _isLoading = false;
  String _selectedPeriod = 'daily';

  final ScrollController _tableScrollController = ScrollController();

  // ตัวแปรเก็บรายการข้อมูลการยืม
  List<dynamic> _borrowReportList = [];

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchBorrowReport();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  String _formatDateTime(String? rawDateTime) {
    if (rawDateTime == null || rawDateTime.isEmpty) return '-';
    try {
      // แปลง String เป็น DateTime แบบ UTC แล้วแปลงเป็น Local Time
      DateTime dateTime = DateTime.parse(rawDateTime).toLocal();

      // จัด Format วัน"
      return DateFormat('dd/MM/yyyy HH:mm น.').format(dateTime);
    } catch (e) {
      return rawDateTime;
    }
  }

  // ฟังก์ชันดึงข้อมูลประวัติการยืม
  Future<void> _fetchBorrowReport() async {
    setState(() => _isLoading = true);
    try {
      final String url =
          '/reports/borrow-report?period=$_selectedPeriod';

      final response = await AppAPI.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _borrowReportList = json['data'] ?? [];
          });
        }
      } else {
        debugPrint("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching borrow report: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
//สร้างภาพทิ้งไว้ก่อน (placeholder)
  // Widget _buildPlaceholder() {
  //   return Container(
  //     width: 44,
  //     height: 44,
  //     decoration: BoxDecoration(
  //       color: Colors.brown[100],
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Icon(
  //       Icons.image_not_supported,
  //       color: Colors.brown[800],
  //       size: 22,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: Row(
        children: [
          AppSidebar(
            currentRoleId: roleId,
            currentRouteName: "รายงานการยืมบอร์ดเกม",
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'รายงานการยืม-คืนบอร์ดเกม',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _borrowstatusButton('all', 'ทั้งหมด'),
                                _borrowstatusButton('daily', 'การยืมวันนี้'),
                                _borrowstatusButton('unreturn', 'ยังไม่คืน'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ส่วนแสดงผลตารางข้อมูล
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _borrowReportList.isEmpty
                        ? const Center(child: Text('ไม่พบข้อมูลการยืม'))
                        : Scrollbar(
                            controller: _tableScrollController,
                            thumbVisibility: true,
                            thickness: 6,
                            radius: const Radius.circular(8),
                            child: SingleChildScrollView(
                              controller: _tableScrollController,
                              physics: const BouncingScrollPhysics(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  border: TableBorder(
                                    horizontalInside: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    verticalInside: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  columnWidths: const {
                                    0: FixedColumnWidth(80),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2),
                                    4: FlexColumnWidth(1.5),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    // หัวตาราง
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                      ),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Text(
                                            'รหัสยืม',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Text(
                                            'หมายเลขโต๊ะ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Text(
                                            'ชื่อบอร์ดเกม',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Text(
                                            'วัน-เวลา',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Text(
                                            'สถานะ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // แถวข้อมูลจาก API (`_borrowReportList`)
                                    ..._borrowReportList.map((item) {
                                      final String borrowId =
                                          item['borrow_id']?.toString() ?? '-';
                                      final String tableNumber =
                                          item['table_number']?.toString() ??
                                          '-';
                                      final String bgpName =
                                          item['bgp_name'] ?? '-';
                                      final String dateTime = _formatDateTime(
                                        item['date_time']?.toString(),
                                      );
                                      final String statusName =
                                          item['borrow_status_name'] ?? '-';

                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(borrowId),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(tableNumber),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              bgpName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(dateTime),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusName == 'คืนแล้ว'
                                                    ? Colors.green.shade50
                                                    : Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                statusName,
                                                style: TextStyle(
                                                  color: statusName == 'คืนแล้ว'
                                                      ? Colors.green.shade700
                                                      : Colors.orange.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _borrowstatusButton(String periodKey, String label) {
    final isSelected = _selectedPeriod == periodKey;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedPeriod = periodKey;
          });
          _fetchBorrowReport();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.brown[800] : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
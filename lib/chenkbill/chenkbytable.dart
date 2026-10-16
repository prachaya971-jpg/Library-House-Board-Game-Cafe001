import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../app_sidebar.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/socket_service.dart';
import 'package:cafa_boardgame/chenkbill/chenkbill.dart';
import 'package:cafa_boardgame/chenkbill/saleboardgame.dart';

class Chenkbytable extends StatefulWidget {
  const Chenkbytable({Key? key}) : super(key: key);

  @override
  State<Chenkbytable> createState() => _ChenkbytableState();
}

class _ChenkbytableState extends State<Chenkbytable> {
  int roleId = 1;
  List<dynamic> _lableList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchtable();
  }

  Future<void> _fetchtable() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/checkbill/table');
      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);

        if (json is Map<String, dynamic>) {
          if (json['isError'] == false &&
              json['data'] != null &&
              json['data'] is List) {
            setState(() {
              _lableList = json['data'] as List<dynamic>;
            });
          } else {
            setState(() {
              _lableList = [];
            });
          }
        } else if (json is List) {
          setState(() {
            _lableList = json;
          });
        } else {
          setState(() {
            _lableList = [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
        if (mounted) setState(() => _lableList = []);
      }
    } catch (e) {
      print("Error fetching lables: $e");
      if (mounted) setState(() => _lableList = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRoleFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          roleId = decodedToken['emp_role_id'] ?? 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
         
          Row(
            children: [
              AppSidebar(currentRoleId: roleId, currentRouteName: "ชำระเงิน"),
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9), 
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "รายการโต๊ะที่รอชำระเงิน",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 31, 41, 55),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "จำนวนทั้งหมด ${_lableList.length} รายการ",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: _fetchtable,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.grey,
                              ),
                              tooltip: 'รีเฟรชข้อมูล',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _lableList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: 64,
                                        color: Colors.green[300],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "ไม่มีรายการคำปรึกษาค้างอยู่",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 380,
                                        mainAxisExtent: 180,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: _lableList.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        _lableList[index]
                                            as Map<String, dynamic>? ??
                                        {};

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        final int table_number =
                                            int.tryParse(
                                              item['table_number']
                                                      ?.toString() ??
                                                  '0',
                                            ) ??
                                            0;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                Chenkbill(id: table_number),
                                          ),
                                        );
                                      },
                                      child: _buildtableCard(item),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          
          Positioned(
            bottom: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SaleBoardGamePage(),
                  ),
                );
              },
              icon: const Icon(Icons.credit_score_rounded, color: Colors.white),
              label: const Text(
                'ขายบอร์ดเกม',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 20,
                ),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildtableCard(Map<String, dynamic> item) {
    final int table_number =
        int.tryParse(item['table_number']?.toString() ?? '0') ?? 0;
    final String table_status_id = item['table_status_id']?.toString() ?? '-';
    final String table_status_name =
        item['table_status_name']?.toString() ?? 'โต๊ะว่าง';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_restaurant,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'โต๊ะ $table_number',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Row(
              children: [
                Icon(
                  table_status_id == 'R'
                      ? Icons.meeting_room_outlined
                      : table_status_id == 'Y'
                      ? Icons.event_seat_outlined
                      : Icons.receipt_long_outlined,
                  color: table_status_id == 'R'
                      ? Colors.red
                      : table_status_id == 'Y'
                      ? Colors.green
                      : const Color(0xFFD97706),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    table_status_name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: table_status_id == 'R'
                          ? Colors.red
                          : table_status_id == 'Y'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

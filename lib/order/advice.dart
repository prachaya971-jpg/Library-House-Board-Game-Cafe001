import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../app_sidebar.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int roleId = 1;
  List<dynamic> _adviceList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchAdvices();
  }

  Future<void> _fetchAdvices() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/advice/advice-list');
      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);

        if (json is Map<String, dynamic>) {
          if (json['isError'] == false && json['data'] != null && json['data'] is List) {
            setState(() {
              _adviceList = json['data'] as List<dynamic>;
            });
          } else {
            setState(() {
              _adviceList = [];
            });
          }
        } else if (json is List) {
          setState(() {
            _adviceList = json;
          });
        } else {
          setState(() {
            _adviceList = [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
        if (mounted) setState(() => _adviceList = []);
      }
    } catch (e) {
      print("Error fetching advices: $e");
      if (mounted) setState(() => _adviceList = []);
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

  
  Future<void> _markAsAdvised(int adviceId, String tableNumber) async {
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("ยืนยันการให้คำปรึกษา"),
        content: Text('ต้องการเปลี่ยนสถานะของโต๊ะ "$tableNumber" เป็นให้คำปรึกษาแล้วใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF51A742),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ให้คำปรึกษาแล้ว', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await AppAPI.post('/advice/update-advice', {
          'adviceId': adviceId,
          'advice_id': adviceId,
        });

        final jsonRes = jsonDecode(response.body);

        if (response.statusCode == 200 && !jsonRes['isError']) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('จัดการรายการของโต๊ะ $tableNumber เรียบร้อยแล้ว')),
          );
          _fetchAdvices();
        } else {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถอัปเดตได้'}',
              ),
            ),
          );
        }
      } catch (e) {
        print("Error updating advice status: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "คำปรึกษา"),

          Expanded(
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
                            "รายการคำปรึกษา / เรียกพนักงาน",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 31, 41, 55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "จำนวนทั้งหมด ${_adviceList.length} รายการ",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _fetchAdvices,
                        icon: const Icon(Icons.refresh, color: Colors.grey),
                        tooltip: 'รีเฟรชข้อมูล',
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _adviceList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.assignment_turned_in_outlined,
                                        size: 64, color: Colors.green[300]),
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
                                itemCount: _adviceList.length,
                                itemBuilder: (context, index) {
                                  final item = _adviceList[index] as Map<String, dynamic>? ?? {};
                                  return _buildAdviceCard(item);
                                },
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

  Widget _buildAdviceCard(Map<String, dynamic> item) {
    final int adviceId = int.tryParse(item['advice_id']?.toString() ?? '0') ?? 0;
    final String tableNum = item['tablenumber']?.toString() ?? '-';
    final String statusName = item['status_advice_name']?.toString() ?? 'ต้องการคำปรึกษา';

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_restaurant,
                        size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      'โต๊ะ $tableNum',
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
                const Icon(Icons.support_agent, color: Color(0xFFD97706), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _markAsAdvised(adviceId, tableNum),
                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                label: const Text(
                  'ให้คำปรึกษา',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF51A742),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
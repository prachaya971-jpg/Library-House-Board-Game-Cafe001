import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../app_sidebar.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/socket_service.dart';

class Tablereq extends StatefulWidget {
  const Tablereq({Key? key}) : super(key: key);
  
  @override
  State<Tablereq> createState() => _TablereqState();
}

class _TablereqState extends State<Tablereq> {
  int roleId = 1;
  List<dynamic> _tablereqList = [];
  bool _isLoading = true;
  late final void Function(dynamic) _tablereqHandler;

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchtablereq();   
       
    _tablereqHandler = (data) {
      print("[Tablereq Screen] Real-time Triggered");
      if (mounted) _fetchtablereq();
    };

    _bindSocketListener();
  }

void _bindSocketListener() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.off('new_table_request', _tablereqHandler);
      socket.on('new_table_request', _tablereqHandler);
      if (!socket.connected) socket.connect();
    }
  }

  Future<void> _fetchtablereq() async {
  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    final response = await AppAPI.get('/table/table-req-list');
    if (!mounted) return;

    if (response.statusCode == 200) {
      final dynamic json = jsonDecode(response.body);

      if (json is Map<String, dynamic>) {
        if (json['isError'] == false && json['data'] != null && json['data'] is List) {
          setState(() {
            _tablereqList = json['data'] as List<dynamic>;
          });
        } else {
          setState(() {
            _tablereqList = [];
          });
        }
      } else if (json is List) {
        setState(() {
          _tablereqList = json;
        });
      } else {
        setState(() {
          _tablereqList = [];
        });
      }
    } else {
      print("Server Error: ${response.statusCode} - ${response.body}");
      if (mounted) setState(() => _tablereqList = []);
    }
  } catch (e) {
    print("Error fetching requests: $e");
    if (mounted) setState(() => _tablereqList = []);
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

  
  Future<void> _markAsAdvised(int tableNumber,int table_request_id) async {
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("ยืนยันการเปิดโต๊ะ"),
        content: Text('ต้องการเปิดโต๊ะ "$tableNumber"ใช่หรือไม่?'),
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
            child: const Text('เปิดโต๊ะแล้ว', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await AppAPI.post('/table/update_table_rep', {
          'tableNumber': tableNumber,
          'table_request_id':table_request_id,
        });

        final jsonRes = jsonDecode(response.body);

        if (response.statusCode == 200 && !jsonRes['isError']) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('จัดการรายการของโต๊ะ $tableNumber เรียบร้อยแล้ว')),
          );
          _fetchtablereq();
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

  Future<void> _markAscancle(int tableNumber,int table_request_id) async {
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("ยืนยันการไม่อนุมัติเปิดโต๊ะ"),
        content: Text('ต้องการไม่อนุมัติเปิดโต๊ะ "$tableNumber"ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 249, 6, 6),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ไม่อนุมัติ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await AppAPI.post('/table/cancel_table_rep', {
          'tableNumber': tableNumber,
          'table_request_id':table_request_id,
        });

        final jsonRes = jsonDecode(response.body);

        if (response.statusCode == 200 && !jsonRes['isError']) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('จัดการรายการของโต๊ะ $tableNumber เรียบร้อยแล้ว')),
          );
          _fetchtablereq();
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
  void dispose() {
    SocketService().socket?.off('new_table_request', _tablereqHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "รายการเปิดโต๊ะ"),

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
                            "รายการคำขอเปิดโต๊ะ",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 31, 41, 55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "จำนวนทั้งหมด ${_tablereqList.length} รายการ",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _fetchtablereq,
                        icon: const Icon(Icons.refresh, color: Colors.grey),
                        tooltip: 'รีเฟรชข้อมูล',
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _tablereqList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.assignment_turned_in_outlined,
                                        size: 64, color: Colors.green[300]),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "ไม่มีรายการคำขอเปิดโต๊ะ",
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
                                itemCount: _tablereqList.length,
                                itemBuilder: (context, index) {
                                  final item = _tablereqList[index] as Map<String, dynamic>? ?? {};
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
    final int tableNum = int.tryParse(item['table_number']?.toString() ?? '0') ?? 0;
     final int table_request_id = int.tryParse(item['table_request_id']?.toString() ?? '0') ?? 0;

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
                      'โต๊ะ $tableNum มีลูกค้าเข้า',
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
                    'รอการเปิดโต๊ะ',
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
                onPressed: () => _markAsAdvised(tableNum,table_request_id),
                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                label: const Text(
                  'เปิดโต๊ะ',
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
              const SizedBox(width: 12),
               ElevatedButton.icon(
                onPressed: () => _markAscancle(tableNum,table_request_id),
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                label: const Text(
                  'ไม่อนุมัติ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 214, 14, 14),
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
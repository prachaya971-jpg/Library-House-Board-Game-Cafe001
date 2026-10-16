import 'package:flutter/material.dart';
import 'package:cafa_boardgame/app_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/chenkbill/chenkbillbyorder.dart';

class Chenkbill extends StatefulWidget {
  final int id;

  const Chenkbill({super.key, required this.id});

  @override
  State<Chenkbill> createState() => _ChenkbillState();
}

class _ChenkbillState extends State<Chenkbill> {
  int roleId = 1;
  bool _isLoading = false;
  List<dynamic> _orderListbyid = [];

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchorderbyid();
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

  Future<void> _fetchorderbyid() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get(
        '/checkbill/checkbill?table_no=${widget.id}',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json != null && json['isError'] == false) {
          final List rawData = (json['data'] is List) ? json['data'] : [];
          if (mounted) {
            setState(() {
              _orderListbyid = rawData;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching foods: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "ชำระเงิน"),

          Expanded(
            child: Scaffold(
              backgroundColor: const Color.fromARGB(255, 251, 251, 251),
              appBar: AppBar(
                title: Text('เช็กบิล โต๊ะ ${widget.id}'),
                automaticallyImplyLeading: true,
              ),
              body: _orderListbyid.isEmpty
                  ? Center(
                      child: Text(
                        'ยังไม่มีข้อมูลการชำระเงินสำหรับ โต๊ะ ${widget.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _orderListbyid.length,
                            itemBuilder: (context, index) {
                              final item = _orderListbyid[index];
                              final orderId =
                                  item['order_id']?.toString() ?? '-';
                              final dateOrderRaw =
                                  item['date_order']?.toString() ?? '';
                              final orderStatusId =
                                  item['order_status_id']?.toString() ?? 'N';
                              final orderStatusName =
                                  item['order_status_name']?.toString() ??
                                  'ยังไม่จ่าย';
                             

                              // แปลงเวลาให้อ่านง่าย
                              String formattedDate = '-';
                              if (dateOrderRaw.isNotEmpty) {
                                try {
                                  final dateTime = DateTime.parse(
                                    dateOrderRaw,
                                  ).toLocal();
                                  final String datePart =
                                      '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
                                  final String timePart =
                                      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.';
                                  formattedDate = '$datePart $timePart';
                                } catch (_) {
                                  formattedDate = dateOrderRaw;
                                }
                              }

                              final bool isPaid =
                                  orderStatusId == 'Y' ||
                                  orderStatusName.contains('จ่ายแล้ว');

                              return Card(
                                elevation: 1.5,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    final int parsedId =
                                        int.tryParse(
                                          item['order_id']?.toString() ?? '0',
                                        ) ??
                                        0;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            Chenkbillbyorder(id: parsedId),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.receipt_long,
                                                  size: 20,
                                                  color: Colors.black54,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'ออเดอร์ #$orderId',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isPaid
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isPaid
                                                      ? Colors.green
                                                      : Colors.redAccent,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                orderStatusName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPaid
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const Spacer(),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 16,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Divider(height: 1),
                                        ),
                                        
                                      ],
                                    ),
                                  ),
                                ),
                              );
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
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/app_sidebar.dart';

class SaleOrderempDetailPage extends StatefulWidget {
  final int orderId;
  final int? tableNumber;

  const SaleOrderempDetailPage({
    super.key,
    required this.orderId,
    this.tableNumber,
  });

  @override
  State<SaleOrderempDetailPage> createState() => SaleOrderempDetailPageState();
}

class SaleOrderempDetailPageState extends State<SaleOrderempDetailPage> {
  bool _isLoading = true;
  List<dynamic> _details = [];
  String? _errorMessage;
  int roleId = 1;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
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
        });
      }
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AppAPI.get('/salereport/saledetail?order_id=${widget.orderId}');

      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);
        List<dynamic> rawData = [];

        if (json is Map<String, dynamic>) {
          if (json['isError'] == false) {
            rawData = json['data'] is List ? json['data'] : [];
          } else {
            _errorMessage = json['errorMessage'] ?? 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
          }
        } else if (json is List) {
          rawData = json;
        }

        setState(() {
          _details = rawData;
        });
      } else {
        setState(() {
          _errorMessage = "Server Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "เกิดข้อผิดพลาด: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _grandTotal {
    return _details.fold(0.0, (sum, item) {
      final double price = double.tryParse(item['item_total_price']?.toString() ?? '0') ?? 0.0;
      return sum + price;
    });
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      String day = dt.day.toString().padLeft(2, '0');
      String month = dt.month.toString().padLeft(2, '0');
      String year = dt.year.toString();
      String hour = dt.hour.toString().padLeft(2, '0');
      String minute = dt.minute.toString().padLeft(2, '0');
      return "$day/$month/$year $hour:$minute น.";
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = _details.isNotEmpty ? _details.first : null;
    final int displayTable = widget.tableNumber ?? firstItem?['table_number'] ?? 0;
    final String dateTimeStr = _formatDateTime(firstItem?['date_time']?.toString());
    final String empName = firstItem?['emp_name']?.toString() ?? '-';
    final String statusName = firstItem?['order_status_name']?.toString() ?? 'จ่ายแล้ว';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Row(
        children: [
         
          AppSidebar(
            currentRoleId: roleId,
            currentRouteName: "จัดการข้อมูลพนักงาน",
          ),

          
          Expanded(
            child: Scaffold(
              backgroundColor: const Color(0xFFF7FAFC),
              appBar: AppBar(
                title: Text(
                  'รายละเอียดออเดอร์ #${widget.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2D3748),
                elevation: 0.5,
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchDetail,
                                child: const Text('ลองใหม่'),
                              ),
                            ],
                          ),
                        )
                      : _details.isEmpty
                          ? const Center(child: Text('ไม่พบรายการอาหารในออเดอร์นี้'))
                          : Column(
                              children: [
                                // หัวบิล
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'โต๊ะ $displayTable',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              statusName,
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('วันที่ทำรายการ: $dateTimeStr',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                      const SizedBox(height: 4),
                                      Text('พนักงานที่รับผิดชอบ: $empName',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),

                                // รายการอาหาร
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _details.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = _details[index];
                                      final String foodName = item['food_name'] ?? '-';
                                      final String variantName = item['variant_name'] ?? '';
                                      final int quantity = item['quantity'] ?? 1;
                                      final String selectedOptions = item['selected_options'] ?? '';
                                      final String imgUrl = item['img_food_url'] ?? '';
                                      final double itemTotal =
                                          double.tryParse(item['item_total_price']?.toString() ?? '0') ?? 0.0;

                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: imgUrl.isNotEmpty
                                                  ? Image.network(
                                                      '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgUrl',
                                                      width: 65,
                                                      height: 65,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        width: 65,
                                                        height: 65,
                                                        color: Colors.grey.shade200,
                                                        child: const Icon(Icons.fastfood, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Container(
                                                      width: 65,
                                                      height: 65,
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    foodName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF2D3748),
                                                    ),
                                                  ),
                                                  if (variantName.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'รูปแบบ: $variantName',
                                                      style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700),
                                                    ),
                                                  ],
                                                  if (selectedOptions.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'ท็อปปิ้ง/ตัวเลือก: $selectedOptions',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'จำนวน: $quantity รายการ',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '฿${itemTotal.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2D3748),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // สรุปยอดรวม
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, -3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'ยอดรวมทั้งสิ้น',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '฿${_grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
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
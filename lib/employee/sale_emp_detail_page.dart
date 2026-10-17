import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/app_sidebar.dart';
import 'sale_emp.dart';

class SaleEmpDetailPage extends StatefulWidget {
  final int empId;
  final String empName;

  const SaleEmpDetailPage({
    super.key,
    required this.empId,
    required this.empName,
  });

  @override
  State<SaleEmpDetailPage> createState() => _SaleEmpDetailPageState();
}

class _SaleEmpDetailPageState extends State<SaleEmpDetailPage> {
  bool _isLoading = true;
  List<dynamic> _orderList = [];
  String? _errorMessage;
  int roleId = 1;

  @override
  void initState() {
    super.initState();
    _fetchEmpOrders();
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

  Future<void> _fetchEmpOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AppAPI.get('/salereport/saleempdetail?emp_id=${widget.empId}');

      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);
        List<dynamic> rawData = [];

        if (json is Map<String, dynamic>) {
          if (json['isError'] == false || json['isError'] == null) {
            rawData = json['data'] is List ? json['data'] : [];
          } else {
            _errorMessage = json['errorMessage'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูล';
          }
        } else if (json is List) {
          rawData = json;
        }

        setState(() {
          _orderList = rawData;
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

  double get _totalSales {
    return _orderList.fold(0.0, (sum, item) {
      final double price = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
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
                  'ประวัติการขาย: ${widget.empName}',
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
                                onPressed: _fetchEmpOrders,
                                child: const Text('ลองใหม่'),
                              ),
                            ],
                          ),
                        )
                      : _orderList.isEmpty
                          ? const Center(child: Text('ไม่พบประวัติการขายของพนักงานคนนี้'))
                          : Column(
                              children: [
                                // สรุปยอดรวมของพนักงาน
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ยอดบิลทั้งหมด', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_orderList.length} บิล',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('ยอดขายสะสม', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '฿${_totalSales.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // รายการออเดอร์
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _orderList.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = _orderList[index];
                                      final int orderId = item['order_id'] ?? 0;
                                      final int tableNum = item['table_number'] ?? 0;
                                      final int totalItems = item['total_items'] ?? 0;
                                      final String statusName = item['order_status_name']?.toString() ?? 'จ่ายแล้ว';
                                      final String dateTimeStr = _formatDateTime(item['date_time']?.toString());
                                      final double totalPrice =
                                          double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;

                                      return Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'ออเดอร์ #$orderId (โต๊ะ $tableNum)',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.shade100,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            statusName,
                                                            style: TextStyle(
                                                              color: Colors.green.shade800,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'เวลา: $dateTimeStr | จำนวน $totalItems รายการ',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '฿${totalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF2D3748),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                                                tooltip: 'ดูรายการอาหารในบิลนี้',
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => SaleOrderempDetailPage(
                                                        orderId: orderId,
                                                        tableNumber: tableNum,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
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
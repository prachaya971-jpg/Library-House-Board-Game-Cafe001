import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';

class Salereportfood extends StatefulWidget {
  const Salereportfood({super.key});

  @override
  State<Salereportfood> createState() => _SalereportfoodState();
}

class _SalereportfoodState extends State<Salereportfood> {
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = false;
  List<dynamic> _reportList = [];

  @override
  void initState() {
    super.initState();
    _fetchfoodsale();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }
  Future<void> _fetchfoodsale() async {
    setState(() => _isLoading = true);
    try {
      String queryParam = '';
      if (_selectedDate != null) {
        String year = _selectedDate!.year.toString();
        String month = _selectedDate!.month.toString().padLeft(2, '0');
        String day = _selectedDate!.day.toString().padLeft(2, '0');
        queryParam = '?date=$year-$month-$day'; // ผลลัพธ์: ?date=YYYY-MM-DD
      }

      final response = await AppAPI.get('/salereport/salereport$queryParam');

      if (response.statusCode == 200) {
        final dynamic json = jsonDecode(response.body);
        List<dynamic> rawData = [];

        // รองรับรูปแบบ JSON จาก Response
        if (json is List) {
          rawData = json;
        } else if (json is Map<String, dynamic>) {
          if (json['isError'] == false || json['isError'] == null) {
            rawData = json['data'] is List ? json['data'] : [];
          }
        }

        setState(() {
          _reportList = rawData;
        });
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching sales report: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('th', 'TH'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
      _fetchfoodsale();
    }
  }

  // 3. คำนวณยอดขายรวม
  double get _totalRevenue {
    if (_reportList.isEmpty) return 0.0;
    return _reportList.fold(0.0, (sum, item) {
      if (item == null) return sum;
      final double price =
          double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ----------------- หัวข้อ -----------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายงานการขายอาหาร',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              IconButton(
                onPressed: _fetchfoodsale,
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'รีเฟรชข้อมูล',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 16),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                hintText: 'เลือกวันที่ต้องการค้นหา',
                prefixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.black87,
                ),
                suffixIcon: _selectedDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _dateController.clear();
                          });
                          _fetchfoodsale();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          //สรุปยอดขายรวม
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'จำนวนออเดอร์ทั้งหมด'
                          : 'ออเดอร์ประจำวันที่ ${_dateController.text}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_reportList.length} รายการ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'รวมยอดขาย',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿${_totalRevenue.toStringAsFixed(2)}',
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
          const SizedBox(height: 16),

          // แสดงรายการขาย
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _reportList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('ไม่พบข้อมูลการขาย')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reportList.length,
                  itemBuilder: (context, index) {
                    final item = _reportList[index];
                    if (item == null) return const SizedBox.shrink();

                    final String dateTimeStr = _formatDateTime(
                      item['date_time']?.toString(),
                    );
                    final int tableNum = item['table_number'] ?? 0;
                    final int totalitems = item['total_items'] ?? 0;
                    final String empName =
                        item['emp_name']?.toString() ?? 'ไม่ระบุพนักงาน';
                    final String statusName =
                        item['order_status_name']?.toString() ?? 'จ่ายแล้ว';
                    final double totalPrice =
                        double.tryParse(
                          item['total_price']?.toString() ?? '0',
                        ) ??
                        0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      color: const Color(0xFFF8F9FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'ออเดอร์ประจำวันที่$dateTimeStr (โต๊ะ $tableNum)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                    'พนักงาน: $empName | จำนวน: $totalitems รายการ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
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

                            const SizedBox(width: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  print('ยังไม่ทำ');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    210,
                                    222,
                                    208,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 36,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: Color.fromARGB(255, 46, 46, 46), 
                                      width:
                                          1,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'ดูรายละเอียด',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 5, 5, 5),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

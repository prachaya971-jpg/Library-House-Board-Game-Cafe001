import 'package:flutter/material.dart';
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'ordercusdetail.dart';

class Cusorderbyid extends StatefulWidget {
  const Cusorderbyid({super.key});

  @override
  State<Cusorderbyid> createState() => _CusorderbyidState();
}

class _CusorderbyidState extends State<Cusorderbyid> {
  bool _isLoading = false;
  List<dynamic> _orderListbyid = [];
  String? drive_id = '-';
  String? table_no = '-';
  String? _savedName = '-';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadStoredData();
    await _fetchorderbyid();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('saved_nickname');
    final id = prefs.getString('client_device_id');
    String? tableNum;

    final String? token = prefs.getString('customer_table_token');
    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      tableNum = (decodedToken['table_number'] ?? decodedToken['tableno'])
          ?.toString();
    } else {
      print('ไม่พบ Token โต๊ะ หรือหมดอายุการใช้งาน');
    }

    if (mounted) {
      setState(() {
        _savedName = name;
        drive_id = id;
        table_no = tableNum;
        _isLoading = false;
      });

      print('ชื่อเดิม:$_savedName');
      print('Device ID: $drive_id');
      print('table_no: $table_no');
    }
  }

  Future<void> _fetchorderbyid() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPICUS.get(
        '/menu/orderbyid?id=$drive_id&table_number=$table_no',
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
       title: Text(
          'รายการออเดอร์ โต๊ะ ${table_no ?? "-"} คุณ: ${_savedName ?? "-"}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _orderListbyid.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีรายการอาหารที่สั่ง',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      final String foodName =
                          item['food_name'] ?? 'ไม่มีชื่อเมนู';
                      final String variantName = item['variant_name'] ?? '';
                      final double totalPrice =
                          double.tryParse(
                            item['total_price']?.toString() ?? '0',
                          ) ??
                          0.0;
                      final String serveStatusname =
                          item['serve_status_name']?.toString() ?? '';
                      final String serveStatusId =
                          item['serve_status_id']?.toString() ?? '';
                      final int qty =
                          int.tryParse(item['quantity']?.toString() ?? '1') ??
                          1;
                      final String? imgName = item?['image']?.toString();
                      final int order_detail_id =
                          int.tryParse(
                            item['order_detail_id']?.toString() ?? '',
                          ) ??
                          0;

                      return Card(
                        elevation: 2,
                        color: const Color.fromARGB(255, 245, 243, 243),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Cusorderbyiddetail(id: order_detail_id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 75,
                                      height: 75,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          208,
                                          206,
                                          206,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            (imgName != null &&
                                                imgName.isNotEmpty)
                                            ? Image.network(
                                                '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgName',
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => _buildDefaultImage(),
                                              )
                                            : _buildDefaultImage(),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 2. ชื่อเมนู และแบบของอาหาร
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            foodName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (variantName.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'แบบ: $variantName',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: serveStatusId == 'Y'
                                                  ? Colors.green.shade50
                                                  : Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: serveStatusId == 'Y'
                                                    ? Colors.green
                                                    : serveStatusId == 'R'|| serveStatusId == 'C'
                                                    ? Colors.red
                                                    : Colors.orange,
                                              ),
                                            ),
                                            child: Text(
                                              serveStatusname,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: serveStatusId == 'Y'
                                                    ? Colors.green.shade800
                                                    : serveStatusId == 'R'|| serveStatusId == 'C'
                                                    ? Colors.red.shade800
                                                    : Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'จำนวน: $qty ชิ้น',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${totalPrice.toStringAsFixed(2)} ฿',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ยอดรวมทั้งหมด:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_orderListbyid.where((item) => item['serve_status_id'] != 'R' && item['serve_status_id'] != 'C').fold<double>(0.0, (sum, item) => sum + (double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0)).toStringAsFixed(2)} ฿',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
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

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.fastfood_outlined, size: 50, color: Colors.grey),
      ),
    );
  }
}

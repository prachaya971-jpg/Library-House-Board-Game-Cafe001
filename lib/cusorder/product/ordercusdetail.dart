import 'package:flutter/material.dart';
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class Cusorderbyiddetail extends StatefulWidget {
  final int id;
  const Cusorderbyiddetail({super.key, required this.id});

  @override
  State<Cusorderbyiddetail> createState() => _CusorderbyiddetailState();
}

class _CusorderbyiddetailState extends State<Cusorderbyiddetail> {
  bool _isLoading = false;
  List<dynamic> _orderListbyid = [];
  String? drive_id = '-';
  String? table_no = '-';
  String? _savedName = '-';
  List<dynamic> _foodListoptionbyid = [];

  @override
  void initState() {
    super.initState();
    _initData();
    _fetchfoodoptionbyid();
  }

  String _getCancelButtonText(String? status) {
    switch (status) {
      case 'R':
        return 'ถูกปฏิเสธแล้ว';
      case 'A':
        return 'อยู่ระหว่างการดำเนินการ';
      case 'Y':
        return 'เสิร์ฟไปแล้ว';
      case 'C':
        return 'ยกเลิกออเดอร์เเล้ว';
      case 'N':
      default:
        return 'ยกเลิกออเดอร์';
    }
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
        '/menu/orderdetailbyid?id=${widget.id}',
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

  Future<void> _fetchfoodoptionbyid() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPICUS.get(
        '/menu/orderoptionbyid?id=${widget.id}',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json != null && json['isError'] == false) {
          final List rawData = (json['data'] is List) ? json['data'] : [];
          if (mounted) {
            setState(() {
              _foodListoptionbyid = rawData;
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

Future<void> _markcancel(
    int orderDetailId,
    String foodName,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    
  
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("ยืนยันการยกเลิกออเดอร์"),
        content: Text(
          'ต้องการยกเลิกออร์เดอร์ "$foodName" ใช่หรือไม่?',
        ),
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
            child: const Text(
              'ยกเลิกออเดอร์',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await AppAPICUS.post('/menu/cancel-cus-order', {
          'orderDetailId': orderDetailId,
        });

        final jsonRes = jsonDecode(response.body);
        _initData(); 
        if (response.statusCode == 200 && !jsonRes['isError']) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('ยกเลิกออเดอร์ $foodName เรียบร้อยแล้ว')),
          );
          
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
        print("Error canceling order: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE5A93C);

    final Map<String, dynamic>? item = _orderListbyid.isNotEmpty
        ? _orderListbyid.first as Map<String, dynamic>
        : null;

    final String foodName = item?['food_name']?.toString() ?? 'รายละเอียดอาหาร';
    final String variantName = item?['variant_name']?.toString() ?? '';
    final String foodPrice = item?['base_price']?.toString() ?? '0';
    final String? imgName = item?['image']?.toString();
    final String food_variant_id = item?['food_variant_id']?.toString() ?? '';
    final String serveStatusId = item?['serve_status_id']?.toString() ?? '';
    final String serveStatusname = item?['serve_status_name']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          variantName.isNotEmpty ? '$foodName ($variantName)' : foodName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: (imgName != null && imgName.isNotEmpty)
                          ? Image.network(
                              '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgName',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultImage(),
                            )
                          : _buildDefaultImage(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "$foodName $variantName",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '$foodPrice ฿',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
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
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: serveStatusId == 'Y'
                                  ? Colors.green
                                  : serveStatusId == 'R' || serveStatusId == 'C'
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
                                  : serveStatusId == 'R' || serveStatusId == 'C'
                                  ? Colors.red.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _foodListoptionbyid.length,
                    itemBuilder: (context, index) {
                      final opt = _foodListoptionbyid[index];
                      final String optName =
                          opt['option_name']?.toString() ?? '';
                      final String optPrice =
                          opt['option_price']?.toString() ?? '0';
                      final dynamic optId =
                          opt['options_id'] ?? opt['option_id'];
                      final String? optImg = opt['options_img']?.toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // 1. รูปภาพ Option
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.grey.shade100,
                                    child:
                                        (optImg != null &&
                                            optImg.trim().isNotEmpty)
                                        ? Image.network(
                                            '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/options/$optImg',
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.fastfood_outlined,
                                                      size: 22,
                                                      color: Colors.grey,
                                                    ),
                                          )
                                        : const Icon(
                                            Icons.fastfood_outlined,
                                            size: 22,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 2. ชื่อ Option
                                Expanded(
                                  child: Text(
                                    optName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                // 3. ราคา Option
                                Text(
                                  '+$optPrice ฿',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade200,
                    disabledForegroundColor: serveStatusId == 'R'
                        ? Colors.red
                        : Colors.grey.shade600,
                  ),
                  onPressed: serveStatusId == 'N'
                      ? () {
                          _markcancel(widget.id, foodName);
                        }
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getCancelButtonText(serveStatusId),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

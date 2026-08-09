import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../app_sidebar.dart';
import 'dart:convert';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:cafa_boardgame/utils/appapi.dart';

class OrderraelScreen extends StatefulWidget {
  const OrderraelScreen({Key? key}) : super(key: key);

  @override
  State<OrderraelScreen> createState() => _OrderraelScreenState();
}

class _OrderraelScreenState extends State<OrderraelScreen> {
  int roleId = 1;
  bool _isLoading = false;
  List<dynamic> _ordersList = [];

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/order/order-list');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _ordersList = json['data'] ?? [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching orders: $e");
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

  Future<void> _markAsServed(int orderDetailId, String foodName) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. รอรับค่าจากการกดปุ่มใน Dialog (คืนค่า true เมื่อกดเสิร์ฟสำเร็จ, false/null เมื่อกดยกเลิก)
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("ยืนยันการเสิร์ฟ"),
        content: Text(
          'ต้องการเปลี่ยนสถานะ "$foodName" เป็นเสิร์ฟแล้วใช่หรือไม่?',
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
              'เสิร์ฟสำเร็จ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // 2. ถ้าผู้ใช้กดยืนยัน (confirm == true) ค่อยทำการยิง API
    if (confirm == true) {
      try {
        final response = await AppAPI.post('/order/update-order-server', {
          'orderDetailId': orderDetailId,
        });

        final jsonRes = jsonDecode(response.body);

        if (response.statusCode == 200 && !jsonRes['isError']) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('เสิร์ฟ $foodName เรียบร้อยแล้ว')),
          );
          _fetchOrders(); // ดึงข้อมูลใหม่
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
        print("Error updating serve status: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "ออร์เดอร์"),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Header หน้าจอ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "รายการออร์เดอร์รอเสิร์ฟ",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 31, 41, 55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "จำนวนทั้งหมด ${_ordersList.length} รายการ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _fetchOrders,
                        icon: const Icon(Icons.refresh, color: Colors.grey),
                        tooltip: 'รีเฟรชข้อมูล',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  //  แสดงรายการ Orders
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _ordersList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green[300],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "ไม่มีรายการออร์เดอร์ค้างเสิร์ฟ",
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
                                  mainAxisExtent: 230,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: _ordersList.length,
                            itemBuilder: (context, index) {
                              final item = _ordersList[index];
                              return _buildOrderCard(item);
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

  //  แสดงออเดอร์แต่ละรายการ
  Widget _buildOrderCard(Map<String, dynamic> item) {
    final String? imgName = item['image']?.toString();
    final String tableNum = item['table_number']?.toString() ?? '-';
    final String foodName = item['food_name']?.toString() ?? '';
    final String? variantName = item['variant_name']?.toString();
    final String? optionName = item['option_name']?.toString();
    final int quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final double totalPrice =
        num.tryParse(item['total_price']?.toString() ?? '0')?.toDouble() ?? 0.0;

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
          //  โต๊ะ + จำนวน + รายการ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_restaurant,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'โต๊ะ $tableNum',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'x$quantity รายการ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          //  รูปภาพ + รายละเอียดเมนู
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imgName != null && imgName.isNotEmpty
                      ? Image.network(
                          '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgName',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultImage(),
                        )
                      : _buildDefaultImage(),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variantName != null && variantName.isNotEmpty)
                        Text(
                          'รูปแบบ: $variantName',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (optionName != null && optionName.isNotEmpty)
                        Text(
                          'ท็อปปิ้ง: $optionName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          //  ราคา + ปุ่มเสิร์ฟ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ราคารวม',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  Text(
                    '฿${totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _markAsServed(item['order_detail_id'], foodName),
                icon: const Icon(Icons.check, size: 16, color: Colors.white),
                label: const Text(
                  'เสิร์ฟ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF51A742),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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

  Widget _buildDefaultImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 32),
    );
  }
}

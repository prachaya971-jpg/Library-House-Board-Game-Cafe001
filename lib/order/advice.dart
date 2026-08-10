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
  List<dynamic> _tableList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchTableList();
  }

  Future<void> _fetchTableList() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/advice/advice-list');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _tableList = json['data'];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching table list: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "ว่าง":
        return const Color.fromARGB(255, 16, 185, 129);
      case "ไม่ว่าง":
        return const Color.fromARGB(255, 239, 68, 68);
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "ขอคำปรึกษา"),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "รายการโต๊ะและออร์เดอร์",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 31, 41, 55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  //  GridView
                  Expanded(
                    child: GridView.builder(
                      itemCount: _tableList.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                          ),
                      itemBuilder: ((context, index) {
                        final item = _tableList[index];
                        final String tableNum = item['table_number'].toString();
                        final String status = item['table_status_name']
                            .toString();
                        final int pendingQty = item['pending_quantity'] is int
                            ? item['pending_quantity']
                            : int.tryParse(
                                    item['pending_quantity']?.toString() ?? '0',
                                  ) ??
                                  0;
                        final Color statusColor = _getStatusColor(status);
                        return InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              //เงา
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          219,
                                          229,
                                          224,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      // icon
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: Color.fromARGB(
                                          255,
                                          16,
                                          185,
                                          129,
                                        ),
                                        size: 30,
                                      ),
                                    ),
                                    //โต๊ะ
                                    Text(
                                      "โต๊ะ $tableNum",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 31, 41, 55),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Center(
                                    child: pendingQty > 0
                                        ? Text(
                                            "$pendingQty ออร์เดอร์รอดำเนินการ",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                255,
                                                239,
                                                68,
                                                68,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            "ไม่มีออร์เดอร์รอดำเนินการ",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                255,
                                                16,
                                                185,
                                                129,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReqFood extends StatefulWidget {
  final int id;

  const ReqFood({super.key, required this.id});

  @override
  State<ReqFood> createState() => _ReqFoodState();
}

class _ReqFoodState extends State<ReqFood> {
  bool _isLoading = false;
  List<dynamic> _foodListbyid = [];
  List<dynamic> _foodListoptionbyid = [];
  dynamic _selectedOptionId;
  int _quantity = 0;
  List<Map<String, dynamic>> _selectedOptions = [];
  bool _isSubmitting = false;
  String? _savedName;
  String? _deviceId;
  

  @override
  void initState() {
    super.initState();
    _fetchfoodbyid();
    _fetchfoodoptionbyid();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('saved_nickname');
    final id = prefs.getString('client_device_id');

    if (mounted) {
      setState(() {
        _savedName = name;
        _deviceId = id;
        _isLoading = false;
      });

      print('ชื่อเดิม:$_savedName');
      print('Device ID: $_deviceId');
    }
  }

  double _calculateTotalPrice(Map<String, dynamic>? item) {
    final double basePrice =
        double.tryParse(item?['food_variant_price']?.toString() ?? '0') ?? 0.0;

    final double totalOptionPrice = (_selectedOptions.isNotEmpty)
        ? _selectedOptions.fold<double>(0.0, (sum, opt) {
            final double p =
                double.tryParse(opt['option_price']?.toString() ?? '0') ?? 0.0;
            return sum + p;
          })
        : 0.0;

    return (basePrice + totalOptionPrice) * _quantity;
  }

  Future<void> _fetchfoodbyid() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPICUS.get('/menu/menubyid?id=${widget.id}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json != null && json['isError'] == false) {
          final List rawData = (json['data'] is List) ? json['data'] : [];
          if (mounted) {
            setState(() {
              _foodListbyid = rawData;
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
        '/menu/menuoptionbyid?id=${widget.id}',
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

  void _resetOrderForm() {
    setState(() {
      _quantity = 0;
      _selectedOptions.clear();
      _selectedOptionId = null;
    });
  }

  Future<void> _submitreq() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('customer_table_token');

    String? tableStatusId;
    String? tableNumber;

    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      tableStatusId = decodedToken['table_status_id']?.toString();
      tableNumber = (decodedToken['table_number'] ?? decodedToken['tableno'])
          ?.toString();
    } else {
      print('ไม่พบ Token โต๊ะ หรือหมดอายุการใช้งาน');
    }

    if (!mounted) return;

    if (tableNumber == null || tableNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลโต๊ะ กรุณาสแกน QR Code ใหม่อีกครั้ง'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (tableStatusId != 'N') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โต๊ะนี้ยังไม่ได้รับการอนุมัติเปิดโต๊ะ กรุณารอสักครู่'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('ยืนยันการสั่งซื้อ'),
              content: const Text('คุณต้องการยืนยันการสั่งซื้อใช่หรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                  ),
                  child: const Text(
                    'ยืนยัน',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    // 🟢 เพิ่มบรรทัดนี้: ถ้าผู้ใช้กดยกเลิก ให้หยุดการทำงานทันที
    if (!confirm) return;

    if (mounted) setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic>? item = _foodListbyid.isNotEmpty
          ? _foodListbyid.first as Map<String, dynamic>
          : null;
          
      final response = await AppAPICUS.post('/menu/reqorder', {
        'table_number': tableNumber,
        'base_price': item?['food_variant_price']?.toString(),
        'quantity': _quantity,
        'food_variant_id': item?['food_variant_id'],
        'name': _savedName,
        'drive_id': _deviceId,
        'options': _selectedOptions.map((opt) {
          return {
            'options_id': opt['options_id'] ?? opt['option_id'],
          };
        }).toList(),
      });

      // ตรวจสอบ response ตามโครงสร้าง helper (ถ้า return เป็น Map หรือ http.Response)
      dynamic jsonRes = (response is http.Response) ? jsonDecode(response.body) : response;
      final int statusCode = (response is http.Response) ? response.statusCode : 200;

      if (statusCode == 200 && jsonRes['isError'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สั่งอาหารสำเร็จ')),
          );
          _resetOrderForm();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถบันทึกได้'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error creating order: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE5A93C);

    final Map<String, dynamic>? item = _foodListbyid.isNotEmpty
        ? _foodListbyid.first as Map<String, dynamic>
        : null;

    final String foodName = item?['food_name']?.toString() ?? 'รายละเอียดอาหาร';
    final String variantName = item?['variant_name']?.toString() ?? '';
    final String foodPrice = item?['food_variant_price']?.toString() ?? '0';
    final String? imgName = item?['img_food_url']?.toString();
    final String food_variant_id = item?['food_variant_id']?.toString() ?? '';

    final List<Map<String, dynamic>> optionsSummary = _selectedOptions.map((
      opt,
    ) {
      return {
        'options_id': opt['options_id'] ?? opt['option_id'],
        'option_name': opt['option_name']?.toString() ?? '',
        'option_price': opt['option_price']?.toString() ?? '0.00',
      };
    }).toList();

    final double totalPrice = _calculateTotalPrice(item);

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
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "เลือกตัวเลือกเพิ่มเติม",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._foodListoptionbyid.map((opt) {
                        final String optName =
                            opt['option_name']?.toString() ?? '';
                        final String optPrice =
                            opt['option_price']?.toString() ?? '0';
                        final dynamic optId =
                            opt['options_id'] ?? opt['option_id'];

                        final String? optImg = opt['options_img']?.toString();
                        final bool isCurrentSelected = _selectedOptions.any((
                          element,
                        ) {
                          final currentId =
                              element['options_id'] ?? element['option_id'];
                          return currentId?.toString() == optId?.toString();
                        });

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                final index = _selectedOptions.indexWhere((
                                  element,
                                ) {
                                  final currentId =
                                      element['options_id'] ??
                                      element['option_id'];
                                  return currentId?.toString() ==
                                      optId?.toString();
                                });
                                if (index >= 0) {
                                  _selectedOptions.removeAt(index);
                                } else {
                                  _selectedOptions.add(opt);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentSelected
                                    ? primaryColor.withOpacity(0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrentSelected
                                      ? primaryColor
                                      : Colors.grey.shade200,
                                  width: isCurrentSelected ? 1.5 : 1,
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
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
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

                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isCurrentSelected
                                          ? primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isCurrentSelected
                                            ? primaryColor
                                            : Colors.grey.shade400,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: isCurrentSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),

                                  // 3. ชื่อ Option
                                  Expanded(
                                    child: Text(
                                      optName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isCurrentSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),

                                  // 4. ราคา Option
                                  Text(
                                    '+$optPrice ฿',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentSelected
                                          ? primaryColor
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
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
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: () {
                      if (_quantity > 0) {
                        setState(() => _quantity--);
                      }
                    },
                  ),
                  Text(
                    "$_quantity",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () {
                      setState(() => _quantity++);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _quantity > 0
                        ? primaryColor
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _quantity > 0
                      ? () {
                          _submitreq();
                        }
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "สั่งอาหาร",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _calculateTotalPrice(item) % 1 == 0
                            ? "${_calculateTotalPrice(item).toInt()} ฿"
                            : "${_calculateTotalPrice(item).toStringAsFixed(2)} ฿",
                        style: const TextStyle(
                          fontSize: 16,
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

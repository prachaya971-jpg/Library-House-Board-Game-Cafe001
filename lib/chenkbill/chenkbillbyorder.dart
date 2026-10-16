import 'package:flutter/material.dart';
import 'package:cafa_boardgame/app_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Chenkbillbyorder extends StatefulWidget {
  final int id;

  const Chenkbillbyorder({super.key, required this.id});

  @override
  State<Chenkbillbyorder> createState() => _ChenkbillbyorderState();
}

class _ChenkbillbyorderState extends State<Chenkbillbyorder> {
  int roleId = 1;
  bool _isLoading = false;
  List<dynamic> _orderListDetail = [];
  Set<int> _selectedOrderDetailIds = {};
  late IO.Socket socket;

  final List<Map<String, dynamic>> _gameCartItems = [];
  final TextEditingController _gameBarcodeController = TextEditingController();
  final FocusNode _gameBarcodeFocusNode = FocusNode();
  bool _isSearchingGame = false;

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
    _fetchorderbyid();
    _initSocket();
  }

  @override
  void dispose() {
    _gameBarcodeController.dispose();
    _gameBarcodeFocusNode.dispose();
    socket.dispose();
    super.dispose();
  }

  void _initSocket() {
    socket = IO.io(AppConfig.socketUri, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
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
        '/checkbill/checkbillbyorder?order_id=${widget.id}',
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json != null && json['isError'] == false) {
          final List rawData = (json['data'] is List) ? json['data'] : [];
          if (mounted) {
            setState(() {
              _orderListDetail = rawData;
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

  Future<void> _searchBoardgame(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return;

    setState(() => _isSearchingGame = true);
    try {
      final response = await AppAPI.get(
        '/checkbill/boardgame?barcode_number=$cleanBarcode',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        Map<String, dynamic>? itemData;

        if (json is Map<String, dynamic>) {
          if (json.containsKey('data') && json['data'] != null) {
            final rawData = json['data'];
            if (rawData is List && rawData.isNotEmpty) {
              itemData = rawData[0] as Map<String, dynamic>;
            } else if (rawData is Map<String, dynamic>) {
              itemData = rawData;
            }
          } else if (json.containsKey('bg_id')) {
            itemData = json;
          }
        }

        if (itemData != null && itemData['bg_id'] != null) {
          final int bgId = int.tryParse(itemData['bg_id']?.toString() ?? '0') ?? 0;
          final int maxStock = int.tryParse(itemData['quantity']?.toString() ?? '0') ?? 0;

          if (maxStock <= 0) {
            _showSnackbar('สินค้าหมดสต็อกแล้ว', isError: true);
            return;
          }

          final existingIndex = _gameCartItems.indexWhere((it) => it['bg_id'] == bgId);

          setState(() {
            if (existingIndex >= 0) {
              int currentQty = _gameCartItems[existingIndex]['cart_qty'] as int;
              if (currentQty < maxStock) {
                _gameCartItems[existingIndex]['cart_qty'] = currentQty + 1;
              } else {
                _showSnackbar('จำนวนถึงขีดจำกัดในสต็อกแล้ว ($maxStock ชิ้น)', isError: true);
              }
            } else {
              _gameCartItems.add({...itemData!, 'cart_qty': 1, 'max_stock': maxStock});
            }
            _gameBarcodeController.clear();
          });
        } else {
          _showSnackbar('ไม่พบสินค้าบอร์ดเกม', isError: true);
        }
      } else {
        _showSnackbar('ไม่พบสินค้าบอร์ดเกม', isError: true);
      }
    } catch (e) {
      debugPrint("Error searching boardgame: $e");
      _showSnackbar('เกิดข้อผิดพลาดในการค้นหาบอร์ดเกม', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSearchingGame = false);
        _gameBarcodeFocusNode.requestFocus();
      }
    }
  }

  


  
  void _handleCheckoutCash() {
    final double totalAmount = _calculateSelectedTotal();
    if (totalAmount <= 0) return;

    final TextEditingController cashController = TextEditingController();
    double receivedAmount = 0.0;
    double changeAmount = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isEnough = receivedAmount >= totalAmount;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.payments_outlined, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text(
                    'ชำระเงินสด',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // กล่องแสดงยอดรวมสุทธิที่ต้องจ่าย
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black87),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยอดรวมสุทธิ:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${totalAmount.toStringAsFixed(2)} ฿',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ช่องกรอกเงินสดที่รับมา
                      const Text(
                        'จำนวนเงินที่รับมา (บาท):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: cashController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.money),
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.black87,
                              width: 1.8,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setDialogState(() {
                            receivedAmount = parsed;
                            changeAmount = receivedAmount - totalAmount;
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // แสดงเงินทอน / เงินที่ยังขาด
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'เงินทอน:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isEnough
                                ? '${changeAmount.toStringAsFixed(2)} ฿'
                                : 'ยังขาดอีก ${(totalAmount - receivedAmount).toStringAsFixed(2)} ฿',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isEnough
                                  ? Colors.green.shade700
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: !isEnough
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _submitCheckoutCash(
                            receivedAmount: receivedAmount,
                            changeAmount: changeAmount,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ยืนยันรับเงิน',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitCheckoutCash({
    required double receivedAmount,
    required double changeAmount,
  }) async {
    final double totalAmount = _calculateSelectedTotal();
    final List<int> selectedFoodIds = _selectedOrderDetailIds.toList();
    final List<Map<String, dynamic>> gamesToPrint =
        List<Map<String, dynamic>>.from(_gameCartItems);

    
    final List<Map<String, dynamic>> foodsToPrint = [];
    for (var item in _orderListDetail) {
      final int detailId =
          int.tryParse(item['order_detail_id']?.toString() ?? '0') ?? 0;
      if (_selectedOrderDetailIds.contains(detailId)) {
        foodsToPrint.add(Map<String, dynamic>.from(item));
      }
    }

    
    if (selectedFoodIds.isNotEmpty) {
      // คำนวณยอดรวมเฉพาะอาหารที่เลือกจ่าย
      double selectedFoodTotal = 0.0;
      for (var item in _orderListDetail) {
        final int detailId =
            int.tryParse(item['order_detail_id']?.toString() ?? '0') ?? 0;
        if (_selectedOrderDetailIds.contains(detailId)) {
          selectedFoodTotal +=
              double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
        }
      }

      try {
        final res = await AppAPI.post('/checkbill/checkbillall', {
          'orderid': widget.id,
          'total_price': selectedFoodTotal,
          'order_detail_ids': selectedFoodIds,
        });

        final resData = jsonDecode(res.body);
        if (res.statusCode != 200 && res.statusCode != 201 || resData['isError'] == true) {
          _showSnackbar(
            resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการเช็กบิลอาหาร',
            isError: true,
          );
          return;
        }
      } catch (e) {
        _showSnackbar('ไม่สามารถเชื่อมต่อระบบเช็กบิลอาหารได้: $e', isError: true);
        return;
      }
    }

    // 2. บันทึกขายบอร์ดเกม (ถ้ามีบอร์ดเกมในตะกร้า)
    if (gamesToPrint.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      int empId = 1;
      if (token != null && !JwtDecoder.isExpired(token)) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        empId = decodedToken['emp_id'] ?? 1;
      }

      final double gamesTotal = gamesToPrint.fold<double>(0.0, (sum, it) {
        final double price =
            double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
        final int qty = it['cart_qty'] as int? ?? 1;
        return sum + (price * qty);
      });

      final Map<String, dynamic> gameBody = {
        'emp_id': empId,
        'total_price': gamesTotal,
        'items': gamesToPrint
            .map(
              (item) => {
                'bg_id': item['bg_id'],
                'unit_price':
                    double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                'quantity': item['cart_qty'] ?? 1,
              },
            )
            .toList(),
      };

      try {
        final res = await AppAPI.post('/checkbill/saleboardgame', gameBody);
        final resData = jsonDecode(res.body);
        if ((res.statusCode != 200 && res.statusCode != 201) ||
            resData['isError'] == true) {
          _showSnackbar(
            resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึกบอร์ดเกม',
            isError: true,
          );
          return;
        }
      } catch (e) {
        _showSnackbar('ไม่สามารถบันทึกการขายบอร์ดเกมได้: $e', isError: true);
        return;
      }
    }

    _showSnackbar(
      'ชำระเงินสำเร็จ (ทอนเงิน ${changeAmount.toStringAsFixed(2)} บาท)',
    );

    // 3. สั่งพิมพ์ใบเสร็จ
    await _printCombinedReceipt(
      orderId: widget.id,
      foodItems: foodsToPrint,
      gameItems: gamesToPrint,
      grandTotal: totalAmount,
      receivedAmount: receivedAmount,
      changeAmount: changeAmount,
      paymentType: 'cash',
    );

    // 4. เคลียร์ State และโหลดข้อมูลใหม่
    if (mounted) {
      setState(() {
        _selectedOrderDetailIds.clear();
        _gameCartItems.clear();
        _gameBarcodeController.clear();
      });
      _fetchorderbyid();
    }
  }

  
  Future<void> _printCombinedReceipt({
    required int orderId,
    required List<Map<String, dynamic>> foodItems,
    required List<Map<String, dynamic>> gameItems,
    required double grandTotal,
    required double receivedAmount,
    required double changeAmount,
    required String paymentType,
  }) async {
    final doc = pw.Document();

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String userId = '-';

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      userId = (decodedToken['user_id'] ?? '-').toString();
    }

    final thaiFont = await PdfGoogleFonts.sarabunRegular();
    final thaiFontBold = await PdfGoogleFonts.sarabunBold();

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year + 543} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Center(
                  child: pw.Text(
                    'ใบเสร็จรับเงิน / RECEIPT',
                    style: pw.TextStyle(
                      font: thaiFontBold,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Board Game Cafe',
                    style: pw.TextStyle(
                      font: thaiFont,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.8, color: PdfColors.grey600),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ออเดอร์:', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                    pw.Text('#$orderId', style: pw.TextStyle(font: thaiFontBold, fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('วันที่:', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                    pw.Text(dateStr, style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('พนักงาน:', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                    pw.Text('ID: $userId', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                  ],
                ),
                pw.Divider(thickness: 0.8, color: PdfColors.grey600),

                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text('รายการ', style: pw.TextStyle(font: thaiFontBold, fontSize: 9)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('จำนวน', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: thaiFontBold, fontSize: 9)),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text('รวม', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: thaiFontBold, fontSize: 9)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),

                // พิมพ์รายการอาหาร
                ...foodItems.map((item) {
                  final String foodName = item['food_name'] ?? '-';
                  final String variant = item['variant_name'] ?? '';
                  final String displayName = variant.isNotEmpty ? '$foodName ($variant)' : foodName;
                  final int qty = item['quantity'] ?? 1;
                  final double totalRow = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text(displayName, style: pw.TextStyle(font: thaiFont, fontSize: 8.5)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text('$qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: thaiFont, fontSize: 8.5)),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(totalRow.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: thaiFont, fontSize: 8.5)),
                        ),
                      ],
                    ),
                  );
                }),

                // พิมพ์รายการบอร์ดเกม
                ...gameItems.map((item) {
                  final String name = '[เกม] ${item['bg_name'] ?? '-'}';
                  final int qty = item['cart_qty'] as int? ?? 1;
                  final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                  final double totalRow = price * qty;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text(name, style: pw.TextStyle(font: thaiFont, fontSize: 8.5)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text('$qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: thaiFont, fontSize: 8.5)),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(totalRow.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: thaiFont, fontSize: 8.5)),
                        ),
                      ],
                    ),
                  );
                }),

                pw.Divider(thickness: 0.8, color: PdfColors.grey600),

                // สรุปยอดเงิน
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ยอดรวมสุทธิ:', style: pw.TextStyle(font: thaiFontBold, fontSize: 11)),
                    pw.Text('${grandTotal.toStringAsFixed(2)} บาท', style: pw.TextStyle(font: thaiFontBold, fontSize: 11)),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ช่องทางชำระ:', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                    pw.Text('เงินสด', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('รับเงินมา:', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                    pw.Text('${receivedAmount.toStringAsFixed(2)} บาท', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('เงินทอน:', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                    pw.Text('${changeAmount.toStringAsFixed(2)} บาท', style: pw.TextStyle(font: thaiFont, fontSize: 9)),
                  ],
                ),

                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    '*** ขอบคุณที่ใช้บริการ ***',
                    style: pw.TextStyle(font: thaiFont, fontSize: 8.5, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receipt_Order_$orderId',
    );
  }

  void _updateGameQty(int index, int delta) {
    setState(() {
      final current = _gameCartItems[index]['cart_qty'] as int;
      final maxStock = _gameCartItems[index]['max_stock'] as int;
      final newQty = current + delta;

      if (newQty <= 0) {
        _gameCartItems.removeAt(index);
      } else if (newQty > maxStock) {
        _showSnackbar('ไม่สามารถเพิ่มได้เกินสต็อก ($maxStock ชิ้น)', isError: true);
      } else {
        _gameCartItems[index]['cart_qty'] = newQty;
      }
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupOrdersByDevice() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in _orderListDetail) {
      final devId = item['device_id']?.toString() ?? 'unknown';
      if (!grouped.containsKey(devId)) {
        grouped[devId] = [];
      }
      grouped[devId]!.add(item);
    }
    return grouped;
  }

  // รวมยอดราคาสินค้าตามจริง (อาหารที่เลือก + บอร์ดเกม)
  double _calculateSelectedTotal() {
    double totalFood = 0.0;
    for (var item in _orderListDetail) {
      final int detailId =
          int.tryParse(item['order_detail_id']?.toString() ?? '0') ?? 0;
      if (_selectedOrderDetailIds.contains(detailId)) {
        totalFood += double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
      }
    }

    double totalGames = _gameCartItems.fold<double>(0.0, (sum, it) {
      final double price = double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
      final int qty = it['cart_qty'] as int? ?? 1;
      return sum + (price * qty);
    });

    return ((totalFood + totalGames) * 100).round() / 100;
  }

void _handleCheckoutPromptPay() {
    final double totalAmount = _calculateSelectedTotal();
    if (totalAmount <= 0) return;

    // สั่งให้จอแสดงผลฝั่งลูกค้าเด้ง QR Code พร้อมยอดเงิน
    socket.emit('show_payment_qr', {'amount': totalAmount});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('รอการชำระเงินผ่าน PromptPay'),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'ยอดที่ลูกค้าต้องชำระ',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '฿${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'แสดง QR Code บนหน้าจอลูกค้าแล้ว',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          // กรณียกเลิก
          TextButton(
            onPressed: () {
              socket.emit('clear_payment_display');
              Navigator.pop(ctx);
            },
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          // เมื่อพนักงานตรวจสลิปว่าเงินเข้าเรียบร้อย
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitCheckoutPromptPay();
            },
            child: const Text('ยืนยันเงินเข้าแล้ว'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckoutPromptPay() async {
    final double totalAmount = _calculateSelectedTotal();
    final List<int> selectedFoodIds = _selectedOrderDetailIds.toList();
    final List<Map<String, dynamic>> gamesToPrint =
        List<Map<String, dynamic>>.from(_gameCartItems);

    final List<Map<String, dynamic>> foodsToPrint = [];
    double selectedFoodTotal = 0.0;

    for (var item in _orderListDetail) {
      final int detailId =
          int.tryParse(item['order_detail_id']?.toString() ?? '0') ?? 0;
      if (_selectedOrderDetailIds.contains(detailId)) {
        foodsToPrint.add(Map<String, dynamic>.from(item));
        selectedFoodTotal +=
            double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
      }
    }

    // 1. บันทึกเช็กบิลอาหาร
    if (selectedFoodIds.isNotEmpty) {
      try {
        final res = await AppAPI.post('/checkbill/checkbillall', {
          'orderid': widget.id,
          'total_price': selectedFoodTotal,
          'order_detail_ids': selectedFoodIds,
        });

        final resData = jsonDecode(res.body);
        if ((res.statusCode != 200 && res.statusCode != 201) ||
            resData['isError'] == true) {
          _showSnackbar(
            resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการเช็กบิลอาหาร',
            isError: true,
          );
          return;
        }
      } catch (e) {
        _showSnackbar('ไม่สามารถเชื่อมต่อระบบเช็กบิลอาหารได้: $e', isError: true);
        return;
      }
    }

    // 2. บันทึกขายบอร์ดเกม (ถ้ามี)
    if (gamesToPrint.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      int empId = 1;
      if (token != null && !JwtDecoder.isExpired(token)) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        empId = decodedToken['emp_id'] ?? 1;
      }

      final double gamesTotal = gamesToPrint.fold<double>(0.0, (sum, it) {
        final double price =
            double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
        final int qty = it['cart_qty'] as int? ?? 1;
        return sum + (price * qty);
      });

      final Map<String, dynamic> gameBody = {
        'emp_id': empId,
        'total_price': gamesTotal,
        'items': gamesToPrint
            .map(
              (item) => {
                'bg_id': item['bg_id'],
                'unit_price':
                    double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                'quantity': item['cart_qty'] ?? 1,
              },
            )
            .toList(),
      };

      try {
        final res = await AppAPI.post('/checkbill/saleboardgame', gameBody);
        final resData = jsonDecode(res.body);
        if ((res.statusCode != 200 && res.statusCode != 201) ||
            resData['isError'] == true) {
          _showSnackbar(
            resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึกบอร์ดเกม',
            isError: true,
          );
          return;
        }
      } catch (e) {
        _showSnackbar('ไม่สามารถบันทึกการขายบอร์ดเกมได้: $e', isError: true);
        return;
      }
    }

    _showSnackbar('รับชำระเงินสำเร็จ');
    socket.emit('clear_payment_display');

    // 3. สั่งพิมพ์ใบเสร็จ
    await _printCombinedReceipt(
      orderId: widget.id,
      foodItems: foodsToPrint,
      gameItems: gamesToPrint,
      grandTotal: totalAmount,
      receivedAmount: totalAmount,
      changeAmount: 0.0,
      paymentType: 'transfer',
    );

    // 4. รีเฟรชหน้าจอ
    if (mounted) {
      setState(() {
        _selectedOrderDetailIds.clear();
        _gameCartItems.clear();
        _gameBarcodeController.clear();
      });
      _fetchorderbyid();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool hasItemsToPay = _selectedOrderDetailIds.isNotEmpty || _gameCartItems.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "ชำระเงิน"),
          Expanded(
            child: Scaffold(
              backgroundColor: const Color.fromARGB(255, 250, 250, 250),
              appBar: AppBar(
                title: Text('เช็กบิล ออเดอร์ #${widget.id}'),
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        final groupedOrders = _groupOrdersByDevice();

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              color: Colors.grey.shade100,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'จำนวน (${groupedOrders.length} คน)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        final allIds = _orderListDetail
                                            .map(
                                              (it) =>
                                                  int.tryParse(
                                                    it['order_detail_id']
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0,
                                            )
                                            .toSet();

                                        if (_selectedOrderDetailIds.length ==
                                            allIds.length) {
                                          _selectedOrderDetailIds.clear();
                                        } else {
                                          _selectedOrderDetailIds = allIds;
                                        }
                                      });
                                    },
                                    child: Text(
                                      _selectedOrderDetailIds.length ==
                                              _orderListDetail.length
                                          ? 'ยกเลิกทั้งหมด'
                                          : 'เลือกจ่ายทั้งหมด',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(12),
                                children: [
                                  ...groupedOrders.entries.map((entry) {
                                    final items = entry.value;
                                    final customerName =
                                        items.first['name'] ?? 'ลูกค้า';

                                    final List<int> personItemIds = items
                                        .map(
                                          (it) =>
                                              int.tryParse(
                                                it['order_detail_id']
                                                        ?.toString() ??
                                                    '0',
                                              ) ??
                                              0,
                                        )
                                        .toList();

                                    final bool isAllOfPersonSelected =
                                        personItemIds.every(
                                          (id) => _selectedOrderDetailIds
                                              .contains(id),
                                        );
                                    final bool isSomeOfPersonSelected =
                                        personItemIds.any(
                                          (id) => _selectedOrderDetailIds
                                              .contains(id),
                                        ) &&
                                        !isAllOfPersonSelected;

                                    final personTotal = items.fold<double>(
                                      0.0,
                                      (sum, it) =>
                                          sum +
                                          (double.tryParse(
                                                it['total_price']?.toString() ??
                                                    '0',
                                              ) ??
                                              0.0),
                                    );

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      elevation: isAllOfPersonSelected ? 2 : 0.5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: isAllOfPersonSelected
                                              ? Colors.green.shade400
                                              : Colors.grey.shade300,
                                          width: isAllOfPersonSelected ? 2.0 : 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(14),
                                                ),
                                            onTap: () {
                                              setState(() {
                                                if (isAllOfPersonSelected) {
                                                  _selectedOrderDetailIds
                                                      .removeAll(personItemIds);
                                                } else {
                                                  _selectedOrderDetailIds.addAll(
                                                    personItemIds,
                                                  );
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isAllOfPersonSelected
                                                    ? Colors.green.shade50
                                                    : Colors.grey.shade50,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(12),
                                                    ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Checkbox(
                                                    value: isAllOfPersonSelected,
                                                    tristate: isSomeOfPersonSelected,
                                                    activeColor: Colors.green,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        if (val == true ||
                                                            isSomeOfPersonSelected) {
                                                          _selectedOrderDetailIds
                                                              .addAll(
                                                                personItemIds,
                                                              );
                                                        } else {
                                                          _selectedOrderDetailIds
                                                              .removeAll(
                                                                personItemIds,
                                                              );
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  const Icon(
                                                    Icons.person_outline,
                                                    size: 20,
                                                    color: Colors.black54,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'คุณ: $customerName',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isAllOfPersonSelected
                                                            ? Colors.green.shade900
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    'ยอดรวม ${personTotal.toStringAsFixed(2)} ฿',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: isAllOfPersonSelected
                                                          ? Colors.green.shade800
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Column(
                                              children: items.map((food) {
                                                final int detailId =
                                                    int.tryParse(
                                                      food['order_detail_id']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0;
                                                final foodName =
                                                    food['food_name'] ?? '-';
                                                final variant =
                                                    food['variant_name'] ?? '';
                                                final opt =
                                                    food['option_name'] ?? '';
                                                final qty = food['quantity'] ?? 1;
                                                final itemTotal =
                                                    food['total_price'] ?? '0';
                                                final imgName = food['image']
                                                    ?.toString();
                                                final bool isItemSelected =
                                                    _selectedOrderDetailIds
                                                        .contains(detailId);

                                                return InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      if (isItemSelected) {
                                                        _selectedOrderDetailIds
                                                            .remove(detailId);
                                                      } else {
                                                        _selectedOrderDetailIds
                                                          .add(detailId);
                                                      }
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Checkbox(
                                                          value: isItemSelected,
                                                          activeColor:
                                                              Colors.green,
                                                          onChanged: (val) {
                                                            setState(() {
                                                              if (val == true) {
                                                                _selectedOrderDetailIds
                                                                    .add(detailId);
                                                              } else {
                                                                _selectedOrderDetailIds
                                                                    .remove(detailId);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Container(
                                                            width: 46,
                                                            height: 46,
                                                            color: Colors
                                                                .grey.shade100,
                                                            child: (imgName != null &&
                                                                    imgName.isNotEmpty)
                                                                ? Image.network(
                                                                    '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgName',
                                                                    fit: BoxFit.cover,
                                                                    errorBuilder: (ctx, err, stack) =>
                                                                        const Icon(
                                                                          Icons.fastfood,
                                                                          size: 20,
                                                                          color: Colors.grey,
                                                                        ),
                                                                  )
                                                                : const Icon(
                                                                    Icons.fastfood,
                                                                    size: 20,
                                                                    color: Colors.grey,
                                                                  ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                '${qty}x ${variant.isNotEmpty ? "$foodName ($variant)" : foodName}',
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight.w500,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              if (opt.toString().isNotEmpty) ...[
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  '($opt)',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey.shade600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '${itemTotal} ฿',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                  const SizedBox(height: 8),

                                  Card(
                                    elevation: 0.5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: Colors.amber.shade400,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(
                                                Icons.sports_esports_outlined,
                                                color: Color(0xFFD97706),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'บอร์ดเกมที่ซื้อเพิ่ม (หน้าร้าน)',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _gameBarcodeController,
                                                  focusNode: _gameBarcodeFocusNode,
                                                  textInputAction: TextInputAction.search,
                                                  onSubmitted: _searchBoardgame,
                                                  decoration: InputDecoration(
                                                    hintText: 'ยิงบาร์โค้ด หรือพิมพ์เลขบาร์โค้ด...',
                                                    prefixIcon: const Icon(Icons.qr_code_scanner, size: 20),
                                                    suffixIcon: _gameBarcodeController.text.isNotEmpty
                                                        ? IconButton(
                                                            icon: const Icon(Icons.clear, size: 18),
                                                            onPressed: () => _gameBarcodeController.clear(),
                                                          )
                                                        : null,
                                                    isDense: true,
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: _isSearchingGame
                                                    ? null
                                                    : () => _searchBoardgame(_gameBarcodeController.text),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFD97706),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: _isSearchingGame
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Text('เพิ่ม'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          if (_gameCartItems.isEmpty)
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'ยังไม่มีบอร์ดเกมที่เลือกซื้อเพิ่ม',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            )
                                          else
                                            ListView.separated(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: _gameCartItems.length,
                                              separatorBuilder: (ctx, i) => const Divider(height: 1),
                                              itemBuilder: (ctx, index) {
                                                final item = _gameCartItems[index];
                                                final String name = item['bg_name'] ?? '-';
                                                final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                                                final int qty = item['cart_qty'] as int? ?? 1;
                                                final double totalRow = price * qty;
                                                final String? imgName = item['img_game_sale']?.toString();

                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                                  child: Row(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Container(
                                                          width: 40,
                                                          height: 40,
                                                          color: Colors.grey.shade100,
                                                          child: (imgName != null && imgName.isNotEmpty)
                                                              ? Image.network(
                                                                  '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/boardgame/$imgName',
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (c, e, s) => const Icon(
                                                                    Icons.videogame_asset,
                                                                    size: 20,
                                                                    color: Colors.grey,
                                                                  ),
                                                                )
                                                              : const Icon(
                                                                  Icons.videogame_asset,
                                                                  size: 20,
                                                                  color: Colors.grey,
                                                                ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            Text(
                                                              'ชิ้นละ ${price.toStringAsFixed(2)} ฿',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey.shade600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.remove, size: 16),
                                                            onPressed: () => _updateGameQty(index, -1),
                                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                            padding: EdgeInsets.zero,
                                                          ),
                                                          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                          IconButton(
                                                            icon: const Icon(Icons.add, size: 16),
                                                            onPressed: () => _updateGameQty(index, 1),
                                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                            padding: EdgeInsets.zero,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '${totalRow.toStringAsFixed(2)} ฿',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                                        onPressed: () {
                                                          setState(() {
                                                            _gameCartItems.removeAt(index);
                                                          });
                                                        },
                                                      ),
                                                    ],
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
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    offset: const Offset(0, -3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ยอดที่เลือกจ่าย (${_selectedOrderDetailIds.length} อาหาร + ${_gameCartItems.length} บอร์ดเกม)',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${_calculateSelectedTotal().toStringAsFixed(2)} ฿',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton.icon(
                                              onPressed: !hasItemsToPay ? null : () => _handleCheckoutCash(),
                                              icon: const Icon(Icons.payments_outlined, size: 20),
                                              label: const Text(
                                                'ชำระเงินสด',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFD97706),
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: Colors.grey.shade300,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton.icon(
                                              onPressed: !hasItemsToPay ? null : () => _handleCheckoutPromptPay(),
                                              icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                                              label: const Text(
                                                'พร้อมเพย์',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2E7D32),
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: Colors.grey.shade300,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
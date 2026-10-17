import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/app_sidebar.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SaleBoardGamePage extends StatefulWidget {
  const SaleBoardGamePage({super.key});

  @override
  State<SaleBoardGamePage> createState() => _SaleBoardGamePageState();
}

class _SaleBoardGamePageState extends State<SaleBoardGamePage> {
  int roleId = 1;

  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  bool _isSearching = false;
  final List<Map<String, dynamic>> _cartItems = [];
  late IO.Socket socket;
  int emp_id = 1;
  String user_id = '';

  @override
  void initState() {
    super.initState();
    _initSocket();
    _loadRoleFromToken();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    socket.dispose();
    super.dispose();
  }

  Future<void> _loadRoleFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          roleId = decodedToken['emp_role_id'] ?? 1;
          user_id = decodedToken['user_id'] ?? 1;
        });
      }
    }
  }

  Future<void> _searchBoardgame(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return;

    setState(() => _isSearching = true);
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
          _addToCart(itemData);
          _barcodeController.clear();
        } else {
          _showSnackbar('ไม่พบสินค้าในสต็อก', isError: true);
        }
      } else {
        _showSnackbar('ไม่พบสินค้าในสต็อก', isError: true);
      }
    } catch (e) {
      debugPrint("Error searching boardgame: $e");
      _showSnackbar('เกิดข้อผิดพลาดในการเชื่อมต่อระบบ', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
        _barcodeFocusNode.requestFocus();
      }
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    final int bgId = int.tryParse(item['bg_id']?.toString() ?? '0') ?? 0;
    final int maxStock = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;

    if (maxStock <= 0) {
      _showSnackbar('สินค้าหมดสต็อกแล้ว', isError: true);
      return;
    }

    final existingIndex = _cartItems.indexWhere((it) => it['bg_id'] == bgId);

    setState(() {
      if (existingIndex >= 0) {
        int currentQty = _cartItems[existingIndex]['cart_qty'] as int;
        if (currentQty < maxStock) {
          _cartItems[existingIndex]['cart_qty'] = currentQty + 1;
        } else {
          _showSnackbar(
            'จำนวนถึงขีดจำกัดในสต็อกแล้ว ($maxStock ชิ้น)',
            isError: true,
          );
        }
      } else {
        _cartItems.add({...item, 'cart_qty': 1, 'max_stock': maxStock});
      }
    });
  }

  void _updateCartQty(int index, int delta) {
    setState(() {
      final current = _cartItems[index]['cart_qty'] as int;
      final maxStock = _cartItems[index]['max_stock'] as int;
      final newQty = current + delta;

      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else if (newQty > maxStock) {
        _showSnackbar(
          'ไม่สามารถเพิ่มได้เกินสต็อก ($maxStock ชิ้น)',
          isError: true,
        );
      } else {
        _cartItems[index]['cart_qty'] = newQty;
      }
    });
  }

  // คำนวณยอดรวมสินค้าเพียวๆ ตามจริง
  double _calculateGrandTotal() {
    final double sum = _cartItems.fold<double>(0.0, (acc, it) {
      final double price =
          double.tryParse(it['price']?.toString() ?? '0') ?? 0.0;
      final int qty = (it['cart_qty'] ?? it['quantity']) as int? ?? 1;
      return acc + (price * qty);
    });
    return ((sum * 100).round() / 100);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _initSocket() {
    socket = IO.io(AppConfig.socketUri, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      debugPrint('Connected to Socket server');
    });

    socket.onDisconnect((_) {
      debugPrint('Disconnected from Socket server');
    });
  }

  void _handleCheckoutpromptpay() {
    if (_cartItems.isEmpty) return;

    final totalAmount = _calculateGrandTotal();

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
          TextButton(
            onPressed: () {
              socket.emit('clear_payment_display');
              Navigator.pop(ctx);
            },
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              await _submitCheckoutOrder();
              _showSnackbar('รับชำระเงินสำเร็จ');

              socket.emit('clear_payment_display');

              setState(() {
                _cartItems.clear();
              });
            },
            child: const Text('ยืนยันเงินเข้าแล้ว'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckoutOrder() async {
    if (_cartItems.isEmpty) return;

    final totalAmount = _calculateGrandTotal();
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          emp_id = decodedToken['emp_id'] ?? 1;
        });
      }
    }
    final Map<String, dynamic> bodyData = {
      'emp_id': emp_id,
      'total_price': totalAmount,
      'items': _cartItems
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
      final res = await AppAPI.post('/checkbill/saleboardgame', bodyData);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final resData = jsonDecode(res.body);

        if (resData['isError'] == false) {
          final int billId = resData['data']['sale_bg_id'] ?? 0;

          _showSnackbar('บันทึกการขายสำเร็จ เลขที่บิล #$billId');
          socket.emit('clear_payment_display');

          final itemsToPrint = List<Map<String, dynamic>>.from(_cartItems);
          final printTotal = _calculateGrandTotal();

          setState(() {
            _cartItems.clear();
          });

          await _printReceipt(
            billId: billId,
            items: itemsToPrint,
            grandTotal: printTotal,
            paymentType: 'transfer',
          );
        } else {
          _showSnackbar(
            resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึกบิล',
          );
        }
      } else {
        final errData = jsonDecode(res.body);
        _showSnackbar(
          errData['errorMessage'] ??
              'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${res.statusCode})',
        );
      }
    } catch (e) {
      _showSnackbar('ไม่สามารถเชื่อมต่อเครือข่ายได้: $e');
    }
  }

  Future<void> _printReceipt({
    required int billId,
    required List<Map<String, dynamic>> items,
    required double grandTotal,
    required String paymentType,
    double? receivedAmount,
    double? changeAmount,
  }) async {
    final doc = pw.Document();

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          roleId = decodedToken['emp_role_id'] ?? 1;
          user_id = decodedToken['user_id'] ?? 1;
        });
      }
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
                    pw.Text(
                      'เลขที่บิล:',
                      style: pw.TextStyle(font: thaiFont, fontSize: 9),
                    ),
                    pw.Text(
                      '#$billId',
                      style: pw.TextStyle(font: thaiFontBold, fontSize: 9),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'วันที่:',
                      style: pw.TextStyle(font: thaiFont, fontSize: 9),
                    ),
                    pw.Text(
                      dateStr,
                      style: pw.TextStyle(font: thaiFont, fontSize: 9),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.8, color: PdfColors.grey600),

                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'รายการ',
                        style: pw.TextStyle(font: thaiFontBold, fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'จำนวน',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: thaiFontBold, fontSize: 9),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'รวม',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: thaiFontBold, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),

                ...items.map((item) {
                  final String name = item['bg_name'] ?? '-';
                  final int qty = item['cart_qty'] as int? ?? 1;
                  final double price =
                      double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                  final double totalRow = price * qty;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text(
                            name,
                            style: pw.TextStyle(font: thaiFont, fontSize: 8.5),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '$qty',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: thaiFont, fontSize: 8.5),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            totalRow.toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: thaiFont, fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.Divider(thickness: 0.8, color: PdfColors.grey600),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ยอดรวมสุทธิ:',
                      style: pw.TextStyle(font: thaiFontBold, fontSize: 11),
                    ),
                    pw.Text(
                      '${grandTotal.toStringAsFixed(2)} บาท',
                      style: pw.TextStyle(font: thaiFontBold, fontSize: 11),
                    ),
                  ],
                ),

                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ช่องทางชำระ:',
                      style: pw.TextStyle(font: thaiFont, fontSize: 9),
                    ),
                    pw.Text(
                      paymentType == 'cash' ? 'เงินสด' : 'PromptPay / โอนเงิน',
                      style: pw.TextStyle(font: thaiFont, fontSize: 9),
                    ),
                  ],
                ),

                if (paymentType == 'cash' && receivedAmount != null) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'รับเงินมา:',
                        style: pw.TextStyle(font: thaiFont, fontSize: 9),
                      ),
                      pw.Text(
                        '${receivedAmount.toStringAsFixed(2)} บาท',
                        style: pw.TextStyle(font: thaiFont, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'เงินทอน:',
                        style: pw.TextStyle(font: thaiFont, fontSize: 9),
                      ),
                      pw.Text(
                        '${(changeAmount ?? 0.0).toStringAsFixed(2)} บาท',
                        style: pw.TextStyle(font: thaiFont, fontSize: 9),
                      ),
                    ],
                  ),
                ],

                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    '*** ขอบคุณที่ใช้บริการ ***',
                    style: pw.TextStyle(
                      font: thaiFont,
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
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
      name: 'Receipt_Bill_$billId',
    );
  }

  Future<void> _submitCheckoutOrdercash({
    required double receivedAmount,
    required double changeAmount,
  }) async {
    if (_cartItems.isEmpty) return;

    final List<Map<String, dynamic>> itemsToPrint =
        List<Map<String, dynamic>>.from(_cartItems);
    final totalAmount = _calculateGrandTotal();

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          emp_id = decodedToken['emp_id'] ?? 1;
        });
      }
    }

    final Map<String, dynamic> bodyData = {
      'emp_id': emp_id,
      'total_price': totalAmount,
      'items': itemsToPrint
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
      final res = await AppAPI.post('/checkbill/saleboardgame', bodyData);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final resData = jsonDecode(res.body);

        if (resData['isError'] == false) {
          final int billId = resData['data']['sale_bg_id'] ?? 0;

          _showSnackbar('บันทึกการขายสำเร็จ เลขที่บิล #$billId');
          socket.emit('clear_payment_display');

          setState(() {
            _cartItems.clear();
          });

          await _printReceipt(
            billId: billId,
            items: itemsToPrint,
            grandTotal: totalAmount,
            paymentType: 'cash',
            receivedAmount: receivedAmount,
            changeAmount: changeAmount,
          );
        } else {
          _showSnackbar(
            resData['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึกบิล',
          );
        }
      } else {
        final errData = jsonDecode(res.body);
        _showSnackbar(
          errData['errorMessage'] ??
              'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${res.statusCode})',
        );
      }
    } catch (e) {
      _showSnackbar('ไม่สามารถเชื่อมต่อเครือข่ายได้: $e');
    }
  }

  void _handleCheckoutCash() {
    if (_cartItems.isEmpty) return;

    final double totalAmount = _calculateGrandTotal();
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
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
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

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
                              color: Color.fromARGB(255, 3, 3, 3),
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
                  onPressed: (!isEnough || _cartItems.isEmpty)
                      ? null
                      : () async {
                          Navigator.pop(ctx);

                          await _submitCheckoutOrdercash(
                            receivedAmount: receivedAmount,
                            changeAmount: changeAmount,
                          );

                          _showSnackbar(
                            'ชำระเงินสำเร็จ (ทอนเงิน ${changeAmount.toStringAsFixed(2)} บาท)',
                          );

                          setState(() {
                            _cartItems.clear();
                          });
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

  @override
  Widget build(BuildContext context) {
    final grandTotal = _calculateGrandTotal();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "ชำระเงิน"),

          Expanded(
            child: Scaffold(
              backgroundColor: const Color(0xFFF1F5F9),
              appBar: AppBar(
                title: const Text('ระบบขายบอร์ดเกม (หน้าร้าน)'),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                elevation: 0,
              ),
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _barcodeController,
                            focusNode: _barcodeFocusNode,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) => _searchBoardgame(value),
                            decoration: InputDecoration(
                              hintText: 'ยิงบาร์โค้ด หรือพิมพ์เลขบาร์โค้ด',
                              prefixIcon: const Icon(
                                Icons.qr_code_scanner,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                              suffixIcon: _barcodeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () =>
                                          _barcodeController.clear(),
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 4, 4, 4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSearching
                              ? null
                              : () => _searchBoardgame(_barcodeController.text),
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                          label: const Text(
                            'ค้นหา / เพิ่ม',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ยังไม่มีรายการสินค้าในตะกร้า\nกรุณายิงบาร์โค้ดเพื่อเพิ่มรายการขาย',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cartItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              final String name = item['bg_name'] ?? '-';
                              final String barcode =
                                  item['bgs_barcode_number'] ?? '-';
                              final double price =
                                  double.tryParse(
                                    item['price']?.toString() ?? '0',
                                  ) ??
                                  0.0;
                              final int qty = item['cart_qty'] as int? ?? 1;
                              final int stock = item['max_stock'] as int? ?? 0;
                              final String? imgName = item['img_game_sale']
                                  ?.toString();
                              final double rowTotal = price * qty;

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade100,
                                          child:
                                              (imgName != null &&
                                                  imgName.isNotEmpty)
                                              ? Image.network(
                                                  '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/boardgame/$imgName',
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        ctx,
                                                        err,
                                                        stack,
                                                      ) => const Icon(
                                                        Icons.videogame_asset,
                                                        color: Colors.grey,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.videogame_asset,
                                                  color: Colors.grey,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'บาร์โค้ด: $barcode | สต็อกคงเหลือ: $stock',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ชิ้นละ ${price.toStringAsFixed(2)} ฿',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _updateCartQty(index, -1),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                '$qty',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _updateCartQty(index, 1),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          '${rowTotal.toStringAsFixed(2)} ฿',
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _cartItems.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'รวมทั้งหมด ${_cartItems.length} รายการ',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${grandTotal.toStringAsFixed(2)} ฿',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _cartItems.isEmpty
                                    ? null
                                    : () => _handleCheckoutCash(),
                                icon: const Icon(
                                  Icons.payments_outlined,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'เงินสด',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFFD97706,
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),

                              const SizedBox(width: 12),

                              ElevatedButton.icon(
                                onPressed: _cartItems.isEmpty
                                    ? null
                                    : () => _handleCheckoutpromptpay(),
                                icon: const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'โอนชำระเงิน',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF2E7D32,
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
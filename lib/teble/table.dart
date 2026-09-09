import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import '../app_sidebar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class Teble extends StatefulWidget {
  final int? roleId;

  const Teble({super.key, this.roleId});

  @override
  State<Teble> createState() => _TebleState();
}

class _TebleState extends State<Teble> {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _TableList = [];
  int _currentRoleId = 2;
  int roleId = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchTypes();
    _loadRoleFromToken();
  }

  Future<void> _loadRole() async {
    if (widget.roleId != null) {
      setState(() => _currentRoleId = widget.roleId!);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          _currentRoleId = decodedToken['emp_role_id'] ?? 2;
        });
      }
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

  Future<void> _fetchTypes() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/table/table');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _TableList = json['data'] ?? [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching types: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTable() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'ยืนยันการเพิ่มโต๊ะ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('คุณต้องการเพิ่มโต๊ะใหม่ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await AppAPI.post('/table/create-table', {});
      final jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        final tableNumber = jsonRes['data']?['table_number'] ?? '';

        if (mounted) {
          _fetchTypes();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เพิ่มโต๊ะ $tableNumber เรียบร้อยแล้ว'),
              backgroundColor: const Color.fromARGB(255, 2, 2, 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถสร้างโต๊ะได้'}',
              ),
              backgroundColor: const Color.fromARGB(255, 6, 6, 6),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error creating table: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
            backgroundColor: const Color.fromARGB(255, 4, 4, 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteTable() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'ยืนยันการลบโต๊ะ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          content: const Text(
            'คุณต้องการลบโต๊ะหมายเลขล่าสุด (โต๊ะที่มีหมายเลขมากที่สุด) ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ยืนยันการลบ'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await AppAPI.post('/table/delete-table', {});
      final jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        final deletedTableNumber =
            jsonRes['data']?['deleted_table_number'] ?? '';

        if (mounted) {
          _fetchTypes();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบโต๊ะ $deletedTableNumber เรียบร้อยแล้ว'),
              backgroundColor: const Color.fromARGB(255, 2, 2, 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถลบโต๊ะได้'}',
              ),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting table: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _printTableQrCode(String tableNum) async {
  final pdf = pw.Document();

  final thaiFont = await PdfGoogleFonts.sarabunRegular();
  final thaiFontBold = await PdfGoogleFonts.sarabunBold();

  final String qrData = "${AppConfig.apicusBaseUri}/menu?table=$tableNum";

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      theme: pw.ThemeData.withFont(
        base: thaiFont,
        bold: thaiFontBold,
      ),
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'LIBERTY BOARDGAME CAFE',
                  style: pw.TextStyle(
                    font: thaiFontBold,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown900,
                  ),
                ),
                pw.SizedBox(height: 8),
                // ข้อความภาษาไทยจะแสดงผลถูกต้อง
                pw.Text(
                  'โต๊ะ $tableNum',
                  style: pw.TextStyle(
                    font: thaiFontBold,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                  width: 140,
                  height: 140,
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'สแกนเพื่อสั่งอาหาร (Scan to Order)',
                  style: pw.TextStyle(
                    font: thaiFont,
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'QRCode_Table_$tableNum.pdf',
  );
}
  @override
  Widget build(BuildContext context) {
    final bool isManager = _currentRoleId == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSidebar(
            currentRoleId: roleId,
            currentRouteName: "จัดการข้อมูลโต๊ะ",
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
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
                    // หัวข้อและปุ่มจัดการ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'รายการโต๊ะ (Dining Tables)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        if (isManager) ...[
                          ElevatedButton(
                            onPressed: () {
                              _submitTable();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                81,
                                167,
                                66,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('เพิ่ม'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _deleteTable();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ลบ'),
                          ),
                          const SizedBox(width: 8),
                        ],

                        IconButton(
                          onPressed: _fetchTypes,
                          icon: const Icon(Icons.refresh, color: Colors.grey),
                          tooltip: 'รีเฟรชข้อมูล',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // รายการข้อมูลโต๊ะ
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _TableList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('ไม่พบรายการโต๊ะ')),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _TableList.length,
                            itemBuilder: (context, index) {
                              final item = _TableList[index];

                              final String tableNum =
                                  item['table_number']?.toString() ?? '-';
                              final String tablestatus =
                                  item['table_status_name']?.toString() ?? '-';
                              final String tableStatusId =
                                  item['table_status_id']?.toString() ?? '';
                              final bool isNormal = tableStatusId == 'N';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                color: const Color(0xFFF8F9FA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade100,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFFD49A32),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'โต๊ะ $tableNum',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'สถานะ: $tablestatus',
                                    style: TextStyle(
                                      color: isNormal
                                          ? Colors.red.shade600
                                          : Colors.green.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  // ย้ายปุ่มมาใส่ในช่อง trailing ตรงนี้
                                  trailing: ElevatedButton.icon(
                                    onPressed: () =>
                                        _printTableQrCode(tableNum),
                                    icon: const Icon(Icons.qr_code, size: 18),
                                    label: const Text('พิมพ์ QR Code'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2D3748),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
          ),
        ],
      ),
    );
  }
}

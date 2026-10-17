import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import '../app_sidebar.dart';

class BgBorrowsave extends StatefulWidget {
  const BgBorrowsave({super.key});

  @override
  State<BgBorrowsave> createState() => _BgBorrowsaveState();
}

int roleId = 1;

class _BgBorrowsaveState extends State<BgBorrowsave> {
  final TextEditingController _barcodeIdController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _barcodeIdController.dispose();
    _tableNumberController.dispose();
    super.dispose();
  }

  // function ส่งข้อมูลการยืมบอร์ดเกม
  Future<void> _submitBorrow() async {
    final String barcode = _barcodeIdController.text.trim();
    final String tableNum = _tableNumberController.text.trim();

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุรหัสบอร์ดเกม / สแกนบาร์โค้ด')),
      );
      return;
    }

    if (tableNum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุหมายเลขโต๊ะ')),
      );
      return;
    }

    // Dialog ยืนยันการยืม
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการบันทึกการยืม'),
          content: Text('ต้องการบันทึกการยืมบอร์ดเกม ($barcode) สำหรับโต๊ะ $tableNum ใช่หรือไม่?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 167, 66),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await AppAPI.post('/boardgame/boardgameborrow-borrow', {
        'barcode': barcode,
        'table_number': tableNum,
      });

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 && !resData['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกการยืมบอร์ดเกมสำเร็จ')),
          );
          _barcodeIdController.clear();
          _tableNumberController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${resData['errorMessage'] ?? 'ไม่สามารถบันทึกได้'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error saving borrow: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color.fromARGB(255, 8, 8, 8);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: Row(
        children: [
          AppSidebar(
            currentRoleId: roleId,
            currentRouteName: '/borrowsave',
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 24.0,
                  left: 24.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายการยืมบอร์ดเกม',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ระบุข้อมูลเพื่อบันทึกการยืมบอร์ดเกม',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ยืมบอร์ดเกม (Customer Borrow)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'รหัสบอร์ดเกม',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _barcodeIdController,
                            decoration: InputDecoration(
                              hintText: 'แสกนจาก qrcode ที่ตัวกล่อง',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'หมายเลขโต๊ะ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _tableNumberController,
                            decoration: InputDecoration(
                              hintText: 'ระบุหมายเลขโต๊ะ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              // 🟢 ผูก onPressed เข้ากับ _submitBorrow และปิดการกดตอนส่งข้อมูล
                              onPressed: _isSubmitting ? null : _submitBorrow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                    255, 81, 167, 66),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'บันทึก',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
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
        ],
      ),
    );
  }
}
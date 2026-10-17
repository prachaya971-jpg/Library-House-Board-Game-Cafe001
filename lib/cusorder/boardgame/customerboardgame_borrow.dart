import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class CustomerboardgameBorrow extends StatefulWidget {
  final String? bgborrow_id;
  const CustomerboardgameBorrow({super.key, this.bgborrow_id});

  @override
  State<CustomerboardgameBorrow> createState() =>
      _CustomerboardgameBorrowState();
}

class _CustomerboardgameBorrowState extends State<CustomerboardgameBorrow> {
  int roleId = 1;
  String? tableNo;
  bool _isLoading = false;
  List<dynamic> _borrowList = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadTableFromToken();
    if (tableNo != null && tableNo!.isNotEmpty) {
      await _fetchBorrowDataByTable();
    }
  }

  //  ดึงหมายเลขโต๊ะจาก Token
  Future<void> _loadTableFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('customer_table_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      setState(() {
        tableNo = (decodedToken['table_number'] ?? decodedToken['tableno'])
            ?.toString();
        roleId = decodedToken['table_number'] ?? 1;
      });
    }
  }

  //  ฟังก์ชันส่ง request คืนบอร์ดเกมรายชิ้น
  Future<void> _returnSingleBoardGame({
    required String borrowId,
    required String dateTime,
  }) async {
    if (tableNo == null || tableNo!.isEmpty) return;

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ยืนยันการคืนบอร์ดเกม'),
            content: const Text('คุณต้องการคืนบอร์ดเกมรายการนี้ใช่หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF51A742),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'ยืนยัน',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      final response = await AppAPICUS.post('/boardgame/return_item', {
        'borrow_id': borrowId,
        'table_number': tableNo,
        'date_time': dateTime,
      });

      if (response.statusCode == 200) {
        final jsonResult = jsonDecode(response.body);
        if (jsonResult['isError'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('คืนบอร์ดเกมสำเร็จแล้ว'),
                backgroundColor: Color(0xFF51A742),
              ),
            );
          }
          await _fetchBorrowDataByTable();
        } else {
          _showErrorSnackBar(
            jsonResult['errorMessage'] ?? 'เกิดข้อผิดพลาดในการคืน',
          );
        }
      } else {
        _showErrorSnackBar(
          'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint(" Error returning item: $e");
      _showErrorSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // คืนบอร์ดเกมทั้งหมด
  Future<void> _returnAllBoardGames() async {
    if (tableNo == null || tableNo!.isEmpty || _borrowList.isEmpty) return;

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ยืนยันการคืนบอร์ดเกมทั้งหมด'),
            content: Text(
              'คุณต้องการคืนบอร์ดเกมทั้งหมด ${_borrowList.length} รายการใช่หรือไม่?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF51A742),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'ยืนยัน',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      final response = await AppAPICUS.post('/boardgame/return_all', {
        'table_number': tableNo,
      });

      if (response.statusCode == 200) {
        final jsonResult = jsonDecode(response.body);
        if (jsonResult['isError'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('คืนบอร์ดเกมทั้งหมดสำเร็จแล้ว'),
                backgroundColor: Color(0xFF51A742),
              ),
            );
          }
          await _fetchBorrowDataByTable();
        } else {
          _showErrorSnackBar(
            jsonResult['errorMessage'] ?? 'เกิดข้อผิดพลาดในการคืนทั้งหมด',
          );
        }
      } else {
        _showErrorSnackBar(
          'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint(" Error returning all items: $e");
      _showErrorSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  //  ดึงข้อมูลรายการยืมจาก Server
  Future<void> _fetchBorrowDataByTable() async {
    if (tableNo == null || tableNo!.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await AppAPICUS.get(
        '/boardgame/cusborrowdetail?table_number=$tableNo',
      );
      debugPrint(" Status Code: ${response.statusCode}");
      debugPrint(" Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResult = jsonDecode(response.body);

        if (jsonResult['isError'] == false && jsonResult['data'] != null) {
          final List rawData = jsonResult['data'] is List
              ? jsonResult['data']
              : [];
          if (mounted) {
            setState(() {
              _borrowList = rawData;
            });
            debugPrint("โหลดข้อมูลสำเร็จ: ${_borrowList.length} รายการ");
          }
        }
      }
    } catch (e) {
      debugPrint(" Error fetching borrow data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE5A93C);
    const greenBtnColor = Color(0xFF51A742);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'รายการยืมบอร์ดเกม (โต๊ะ ${tableNo ?? "-"})',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _borrowList.isEmpty
          ? const Center(
              child: Text(
                'ไม่มีรายการยืมบอร์ดเกมในขณะนี้',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _borrowList.length,
              itemBuilder: (context, index) {
                final item = _borrowList[index];
                final String gameName =
                    item['bgp_name']?.toString() ?? 'บอร์ดเกม';
                final String? imgName = item['img_game_play']?.toString();
                final String status =
                    item['borrow_status_id']?.toString() ?? 'N';

                // ประกาศตัวแปร borrowId และ dateTime เพื่อส่งให้ Backend
                final String borrowId = item['borrow_id']?.toString() ?? '';
                final String dateTime = item['date_time']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // รูปภาพบอร์ดเกม
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 65,
                              height: 65,
                              color: Colors.grey.shade100,
                              child: (imgName != null && imgName.isNotEmpty)
                                  ? Image.network(
                                      '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/borrow/$imgName',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildDefaultImage(),
                                    )
                                  : _buildDefaultImage(),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // ชื่อบอร์ดเกม
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gameName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          //  ปุ่มคืนบอร์ดเกมนี้
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: greenBtnColor,
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
                            onPressed: status == 'N'
                                ? () => _returnSingleBoardGame(
                                    borrowId: borrowId,
                                    dateTime: dateTime,
                                  )
                                : null,
                            child: const Text(
                              'คืนบอร์ดเกมนี้',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
                    backgroundColor: greenBtnColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _borrowList.isNotEmpty
                      ? _returnAllBoardGames
                      : null,
                  child: const Text(
                    'คืนบอร์ดเกมทั้งหมด',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
        child: Icon(Icons.casino_outlined, size: 36, color: Colors.grey),
      ),
    );
  }
}

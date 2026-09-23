import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:barcode_widget/barcode_widget.dart';
// import 'package:flutter/services.dart';

class ReportBoardgameforsell extends StatefulWidget {
  final int? roleId;

  const ReportBoardgameforsell({super.key, this.roleId});

  @override
  State<ReportBoardgameforsell> createState() => _ReportBoardgameforsellState();
}

class _ReportBoardgameforsellState extends State<ReportBoardgameforsell> {
  bool _isLoading = false;
  List<dynamic> _bgsellList = [];
  int _currentRoleId = 2;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredboardgamesell = [];

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchbgsell();
  }

  void _filterboardgamesell(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredboardgamesell = List.from(_bgsellList);
      } else {
        _filteredboardgamesell = _bgsellList.where((bgsell) {
          final bgsellName = bgsell['bg_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return bgsellName.contains(searchLower);
        }).toList();
      }
    });
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

  //สร้าง barcode
  Widget buildBarcode(String barcodeNumber) {
  if (barcodeNumber.trim().isEmpty) {
    return const Text('ไม่มีบาร์โค้ด', style: TextStyle(color: Colors.grey));
  }

  // แยก บาร์โค้ด
  final List<String> barcodes = barcodeNumber
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  return Column(
    children: barcodes.map((code) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: BarcodeWidget(
          barcode: Barcode.code128(),
          data: code,
          width: 250,
          height: 80,
          drawText: true,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }).toList(),
  );
}

  // function แสดงข้อมูลของปุ่มแสดงรายละเอียด
  void _showDetailDialog(Map<String, dynamic> item) {
    final String? imgName = item['img_game_sale'] ?? item['sell_img'];
    // final int bgsellid = item['bg_id'] ?? '';
    final String imagepath = imgName != null && imgName.isNotEmpty
        ? '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/boardgame/$imgName'
        : '';

    final String barcodeData = item['barcodelist']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'รายละเอียดบอร์ดเกม',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                // const SizedBox(height: 200),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imgName != null && imgName.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imagepath,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ไม่มีรูปภาพ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                const SizedBox(height: 20),
                // ข้อความ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อบอร์ดเกม/ชื่อประเภท
                    Text(
                      item['bg_name'] ?? 'ไม่มีชื่อรายการ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // id
                    // Row(
                    //   children: [
                    //     const Text(
                    //       'เราต้องมี id มั้ย: ',
                    //       style: TextStyle(
                    //         fontWeight: FontWeight.bold,
                    //         color: Colors.grey,
                    //       ),
                    //     ),
                    //     Text(
                    //       '$bgsellid',
                    //       style: const TextStyle(color: Colors.black87),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 6),

                    // จำนวน
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'จำนวนที่มี: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['quantity'].toString(),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    // ประเภท
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ประเภท: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['catagorylist'] ?? 'แกเป็นตัวอะไรเนี่ย',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                //แสดง barcode
                const SizedBox(height: 16),
                const Text(
                  'รายการบาร์โค้ด:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: buildBarcode(barcodeData)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchbgsell() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/boardgame/report-bgsell');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _bgsellList = json['data'] ?? [];
            _filteredboardgamesell = List.from(_bgsellList);
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

  // 2. แสดง Dialog แก้ไขรายการ
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final int bgsellid = item['bgsell_id'] ?? item['bgs_id'] ?? 0;
    final TextEditingController editController = TextEditingController(
      text: item['bg_name'] ?? '',
    );

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แก้ไขชื่อประเภท'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              labelText: 'ชื่อประเภท',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49A32),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final newName = editController.text.trim();
      if (newName.isNotEmpty) {
        _updateType(bgsellid, newName);
      }
    }
  }

  // ส่ง API แก้ไขข้อมูล (ยังไม่แก้ รอทำ database ให้เสร็จก่อน)
  Future<void> _updateType(int id, String newName) async {
    try {
      final response = await AppAPI.post('/boardgame/update-type', {
        'boardgame_type_id': id,
        'bg_name': newName,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จ')));
        }
        _fetchbgsell();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถแก้ไขได้'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error updating type: $e");
    }
  }

  // 3. แสดง Dialog ยืนยันการลบ
  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final int bgsellid = item['bg_id'] ?? item['bgs_id'] ?? 0;
    final String bgsellName = item['bgsell_name'] ?? item['bg_name'] ?? '';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณต้องการลบบอร์ดเกม "$bgsellName" ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteType(bgsellid);
    }
  }

  // ส่ง API ลบข้อมูล
  Future<void> _deleteType(int id) async {
    try {
      final response = await AppAPI.post('/boardgame/delete-bgsell', {
        'bgs_id': id,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลสำเร็จ')));
        }
        _fetchbgsell();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถลบได้'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error deleting type: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isManager = _currentRoleId == 1;

    return Container(
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
          // หัวข้อ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายการบอร์ดเกมสำหรับขาย (boardgame for sell)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อประเภทบอร์ดเกม...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterboardgamesell('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      _filterboardgamesell(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _fetchbgsell,
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'รีเฟรชข้อมูล',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // รายการข้อมูล
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _bgsellList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('ไม่พบรายการบอร์ดเกม')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredboardgamesell.length,
                  itemBuilder: (context, index) {
                    final item = _filteredboardgamesell[index];
                    final String typeName = item['bg_name'] ?? '';
                    final String? imgicon = item['img_game_sale'];

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
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imgicon != null && imgicon.isNotEmpty
                              ? Image.network(
                                  '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/boardgame/$imgicon',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(index),
                                )
                              : _buildDefaultAvatar(index),
                        ),
                        title: Text(
                          typeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        trailing: isManager
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () => _showDetailDialog(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          210,
                                          222,
                                          208,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 36,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: const BorderSide(
                                            color: Color.fromARGB(
                                              255,
                                              46,
                                              46,
                                              46,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'ดูรายละเอียด',
                                        style: TextStyle(
                                          color: Color.fromARGB(255, 5, 5, 5),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => _showEditDialog(item),
                                    tooltip: 'แก้ไข',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _showDeleteDialog(item),
                                    tooltip: 'ลบ',
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(int index) {
    return CircleAvatar(
      backgroundColor: Colors.amber.shade100,
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          color: Color(0xFFD49A32),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

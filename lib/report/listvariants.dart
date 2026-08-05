import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';

class ListVariants extends StatefulWidget {
  const ListVariants({super.key});

  @override
  State<ListVariants> createState() => _ListVariantsState();
}

class _ListVariantsState extends State<ListVariants> {
  bool _isLoading = false;
  List<dynamic> _variantsList = [];

  @override
  void initState() {
    super.initState();
    _fetchVariants();
  }

  // 1. ดึงข้อมูลรายการ Variant ทั้งหมด
  Future<void> _fetchVariants() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/food/variants');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _variantsList = json['data'] ?? [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching variants: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. แสดง Dialog แก้ไขรายการ
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final int variantId = item['variant_id'] ?? 0;
    final TextEditingController editController = TextEditingController(
      text: item['variant_name'] ?? item['variants_name'] ?? '',
    );

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แก้ไขชื่อรูปแบบ (Variant)'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              labelText: 'ชื่อรูปแบบ',
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
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final newName = editController.text.trim();
      if (newName.isNotEmpty) {
        _updateVariant(variantId, newName);
      }
    }
  }

  // ส่ง API แก้ไขข้อมูล
  Future<void> _updateVariant(int id, String newName) async {
    try {
      final response = await AppAPI.post('/food/update-variant', {
        'variant_id': id,
        'variant_name': newName,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จ')),
          );
        }
        _fetchVariants(); // โหลดรายการใหม่
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage']}')),
          );
        }
      }
    } catch (e) {
      print("Error updating variant: $e");
    }
  }

  // 3. แสดง Dialog ยืนยันการลบ
  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final int variantId = item['variant_id'] ?? 0;
    final String variantName = item['variant_name'] ?? item['variants_name'] ?? '';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณต้องการลบรูปแบบ "$variantName" ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteVariant(variantId);
    }
  }

  // ส่ง API ลบข้อมูล
  Future<void> _deleteVariant(int id) async {
    try {
      final response = await AppAPI.post('/food/delete-variant', {
        'variant_id': id,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
          );
        }
        _fetchVariants(); // โหลดรายการใหม่
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage']}')),
          );
        }
      }
    } catch (e) {
      print("Error deleting variant: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'รายการรูปแบบตัวเลือก (Variants)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              IconButton(
                onPressed: _fetchVariants,
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
              : _variantsList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('ไม่พบรายการรูปแบบ')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _variantsList.length,
                      itemBuilder: (context, index) {
                        final item = _variantsList[index];
                        final String variantName = item['variant_name'] ??
                            item['variants_name'] ??
                            '';

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
                              variantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ปุ่มแก้ไข
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _showEditDialog(item),
                                  tooltip: 'แก้ไข',
                                ),
                                // ปุ่มลบ
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(item),
                                  tooltip: 'ลบ',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
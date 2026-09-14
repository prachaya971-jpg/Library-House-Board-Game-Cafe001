import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';

class ListVariants extends StatefulWidget {
  final int? roleId; 

  const ListVariants({super.key, this.roleId});

  @override
  State<ListVariants> createState() => _ListVariantsState();
}

class _ListVariantsState extends State<ListVariants> {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _variantsList = [];
  List<dynamic> _variantsFoodList = [];
  int _currentRoleId = 2; 

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchVariants();
  }

  
 void _filterVariant(String query) {
  setState(() {
    final searchLower = query.trim().toLowerCase();
    
    if (searchLower.isEmpty) {
      _variantsFoodList = List.from(_variantsList);
    } else {
      _variantsFoodList = _variantsList.where((food) {
        final variantName = (food['variant_name'] ?? '').toString().toLowerCase();
        return variantName.contains(searchLower);
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

  Future<void> _fetchVariants() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/food/variants');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _variantsList = json['data'] ?? [];
            _variantsFoodList = List.from(_variantsList); 
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

  //  แสดง Dialog แก้ไขรายการ
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
        _fetchVariants(); 
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
    //  เช็คว่าผู้ใช้งานเป็นผู้จัดการ (Role ID = 1) หรือไม่
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
                'รายการรูปแบบตัวเลือก (Variants)',
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
                      hintText: 'ค้นหาชื่อรูปเเบบ...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterVariant('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      _filterVariant(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                      itemCount: _variantsFoodList.length,
                      itemBuilder: (context, index) {
                        final item = _variantsFoodList[index];
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
                            //  แสดงปุ่ม แก้ไข/ลบ เฉพาะเมื่อผู้ใช้เป็นผู้จัดการ (isManager == true)
                            trailing: isManager
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // ปุ่มแก้ไข
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.orange),
                                        onPressed: () => _showEditDialog(item),
                                        tooltip: 'แก้ไข',
                                      ),
                                      // ปุ่มลบ
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _showDeleteDialog(item),
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
}
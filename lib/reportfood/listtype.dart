import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';

class ListType extends StatefulWidget {
  final int? roleId; 

  const ListType({super.key, this.roleId});

  @override
  State<ListType> createState() => _ListTypeState();
}

class _ListTypeState extends State<ListType> {
  bool _isLoading = false;
   final TextEditingController _searchController = TextEditingController();
  List<dynamic> _typesList = [];
  List<dynamic> _filteredFoodList = [];
  int _currentRoleId = 2; 

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchTypes();
  }

  void _filterFood(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredFoodList = List.from(_typesList);
      } else {
        _filteredFoodList = _typesList.where((food) {
          final foodName = food['food_type_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return foodName.contains(searchLower);
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



  Future<void> _fetchTypes() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/food/types');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _typesList = json['data'] ?? [];
             _filteredFoodList = List.from(_typesList); 
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
    final int typeId = item['food_type_id'] ?? item['type_id'] ?? 0;
    final TextEditingController editController = TextEditingController(
      text: item['food_type_name'] ?? item['type_name'] ?? '',
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
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final newName = editController.text.trim();
      if (newName.isNotEmpty) {
        _updateType(typeId, newName);
      }
    }
  }

  // ส่ง API แก้ไขข้อมูล
  Future<void> _updateType(int id, String newName) async {
    try {
      
      final response = await AppAPI.post('/food/update-type', {
        'food_type_id': id,
        'food_type_name': newName,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จ')),
          );
        }
        _fetchTypes(); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถแก้ไขได้'}')),
          );
        }
      }
    } catch (e) {
      print("Error updating type: $e");
    }
  }

  // 3. แสดง Dialog ยืนยันการลบ
  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final int typeId = item['food_type_id'] ?? item['type_id'] ?? 0;
    final String typeName = item['food_type_name'] ?? item['type_name'] ?? '';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณต้องการลบประเภท "$typeName" ใช่หรือไม่?'),
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
      _deleteType(typeId);
    }
  }

  // ส่ง API ลบข้อมูล
  Future<void> _deleteType(int id) async {
    try {
      final response = await AppAPI.post('/food/delete-type', {
        'food_type_id': id,
        'type_id': id,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
          );
        }
        _fetchTypes(); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถลบได้'}')),
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
                'รายการประเภทอาหาร (Food Types)',
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
                      hintText: 'ค้นหาชื่ออาหาร...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterFood('');
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
                      _filterFood(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

          // รายการข้อมูล
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _typesList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('ไม่พบรายการประเภท')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredFoodList.length,
                      itemBuilder: (context, index) {
                        final item = _filteredFoodList[index];
                
                        final String typeName = item['food_type_name'] ??
                            item['type_name'] ??
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
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.orange),
                                        onPressed: () => _showEditDialog(item),
                                        tooltip: 'แก้ไข',
                                      ),
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
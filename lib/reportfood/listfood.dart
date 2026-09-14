import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class ListFood extends StatefulWidget {
  final int? roleId;

  const ListFood({super.key, this.roleId});

  @override
  State<ListFood> createState() => _ListFoodState();
}

class _ListFoodState extends State<ListFood> {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _foodList = [];
  List<dynamic> _filteredFoodList = [];
  int _currentRoleId = 2;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchfood();
  }

  void _filterFood(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredFoodList = List.from(_foodList);
      } else {
        _filteredFoodList = _foodList.where((food) {
          final foodName = food['food_name']?.toString().toLowerCase() ?? '';
          final variantName = food['variant_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return foodName.contains(searchLower) || variantName.contains(searchLower);
        }).toList();
      }
    });
  }

  // ดึงข้อมูล Role จาก Token
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

  // ดึงรายการอาหาร
  Future<void> _fetchfood() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/food/food');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _foodList = json['data'] ?? [];
            _filteredFoodList = List.from(_foodList); 
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching foods: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          // หัวข้อ และ ช่องค้นหา
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายการอาหาร (Food)',
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
                onPressed: () {
                  _searchController.clear();
                  _fetchfood();
                },
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'รีเฟรชข้อมูล',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filteredFoodList.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('ไม่พบรายการอาหาร')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredFoodList.length, 
                      itemBuilder: (context, index) {
                        final item = _filteredFoodList[index];
                        final String foodName = item['food_name'] ?? '';
                        final String foodvariant = item['variant_name'] ?? '';

                        final double foodPrice = double.tryParse(
                              item['price']?.toString() ??
                                  item['food_variant_price']?.toString() ??
                                  '0',
                            ) ??
                            0.0;
                        final String? imgName = item['img_food_url'];

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
                              child: imgName != null && imgName.isNotEmpty
                                  ? Image.network(
                                      '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgName',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildDefaultAvatar(index),
                                    )
                                  : _buildDefaultAvatar(index),
                            ),
                            title: Text(
                              '$foodName $foodvariant'.trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '฿${foodPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            trailing: isManager
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('ฟังก์ชันแก้ไขยังไม่เปิดใช้งาน')),
                                          );
                                        },
                                        tooltip: 'แก้ไข',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('ฟังก์ชันลบยังไม่เปิดใช้งาน')),
                                          );
                                        },
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
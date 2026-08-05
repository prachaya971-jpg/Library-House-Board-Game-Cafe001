import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class Listtopproduct extends StatefulWidget {
  const Listtopproduct({super.key});

  @override
  State<Listtopproduct> createState() => _ListtopproductState();
}

class _ListtopproductState extends State<Listtopproduct> {
  bool _isLoading = false;
  String _selectedCategory = 'food'; // 'food', 'boardgame', 'borrow'
  String _selectedPeriod = 'daily'; // 'daily', 'monthly', 'yearly'

  //  Controller สำหรับช่องกรอก Limit
  final TextEditingController _limitController = TextEditingController(
    text: '5',
  );
  int _limitValue = 5;

  List<dynamic> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchTopProducts();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  String _getFolderName(String? category) {
    if (category == null || category.isEmpty) return 'food';

    final cat = category.toLowerCase().trim();
    if (cat == 'อาหาร' || cat == 'เครื่องดื่ม' || cat == 'food') return 'food';
    if (cat == 'ขายบอร์ดเกม' || cat == 'boardgame') return 'boardgame';
    if (cat == 'ยืมเล่น' || cat == 'borrow') return 'borrow';

    return cat;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Colors.brown[800],
        size: 22,
      ),
    );
  }

  //  ดึงข้อมูล API โดยส่ง period, category และ limit
  Future<void> _fetchTopProducts() async {
    setState(() => _isLoading = true);
    try {
      final String url =
          '/dashboard/topproducts?period=$_selectedPeriod&category=$_selectedCategory&limit=$_limitValue';

      final response = await AppAPI.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _topProducts = json['data'] ?? [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching top products list: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onLimitSubmitted(String value) {
    int parsed = int.tryParse(value) ?? 5;
    if (parsed <= 0) parsed = 1;
    if (parsed > 100) parsed = 100;

    setState(() {
      _limitValue = parsed;
      _limitController.text = parsed.toString();
    });
    _fetchTopProducts();
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'อันดับสินค้าขายดี / ยอดนิยม',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),

                  Row(
                    children: [
                      //  ช่องกรอกจำนวน Limit
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'แสดงTop: ',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          SizedBox(
                            width: 50,
                            height: 32,
                            child: TextField(
                              controller: _limitController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 4,
                                ),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD49A32),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onSubmitted: _onLimitSubmitted,
                            ),
                          ),
                          const Text(
                            ' รายการ',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // 📅 ปุ่มเลือกช่วงเวลา (รายวัน / รายเดือน / รายปี)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPeriodButton('daily', 'รายวัน'),
                            _buildPeriodButton('monthly', 'รายเดือน'),
                            _buildPeriodButton('yearly', 'รายปี'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              //  ปุ่มเลือกหมวดหมู่สินค้า
              Row(
                children: [
                  _buildCategoryChip('food', 'อาหาร/เครื่องดื่ม'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('boardgame', 'ขายบอร์ดเกม'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('borrow', 'ยืมเล่น'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          //  ส่วนแสดงรายการสินค้า
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _topProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('ไม่พบข้อมูลยอดขาย')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topProducts.length,
                  itemBuilder: (context, index) {
                    final item = _topProducts[index];

                    final num revenue =
                        num.tryParse(
                          item['total_revenue']?.toString() ?? '0',
                        ) ??
                        0;
                    final int quantity =
                        int.tryParse(
                          item['total_quantity']?.toString() ?? '0',
                        ) ??
                        0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: const Color(0xFFF8F9FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Builder(
                            builder: (context) {
                              final item = _topProducts[index];

                              final String? imageName = item['image'];
                              final String? rawCategory = item['category'];

                              // แปลงชื่อหมวดหมู่ภาษาไทยเป็นชื่อ Folder ภาษาอังกฤษ
                              final String folderName = _getFolderName(
                                rawCategory,
                              );

                              // กำหนด Base URL ตรงไปยัง /img/
                              const String serverUrl =
                                  'http://localhost:3000/img/';

                              if (imageName != null && imageName.isNotEmpty) {
                                final String imageUrl =
                                    imageName.startsWith('http')
                                    ? imageName
                                    : '$serverUrl$folderName/$imageName';

                                return Image.network(
                                  imageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          width: 44,
                                          height: 44,
                                          color: Colors.brown[100],
                                          child: const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    print(" image isn't loading in URL: $imageUrl");
                                    print(" ErrorMessage : $error");
                                    return _buildPlaceholder();
                                  },
                                );
                              }

                              return _buildPlaceholder();
                            },
                          ),
                        ),
                        title: Text(
                          item['product_name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          'หมวดหมู่: ${item['category'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'จำนวน: $quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (item['category'] != 'borrow')
                              Text(
                                '฿${revenue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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

  // 🔘 Widget ปุ่มสลับช่วงเวลา
  Widget _buildPeriodButton(String periodKey, String label) {
    final isSelected = _selectedPeriod == periodKey;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedPeriod = periodKey;
          });
          _fetchTopProducts();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.brown[800] : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // 🏷️ Widget ปุ่มเลือกหมวดหมู่
  Widget _buildCategoryChip(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFD49A32),
      backgroundColor: Colors.grey[100],
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = categoryKey;
          });
          _fetchTopProducts();
        }
      },
    );
  }
}

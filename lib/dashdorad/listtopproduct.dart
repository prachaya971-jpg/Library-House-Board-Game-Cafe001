import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:intl/intl.dart';

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
              : // ใน listtopproduct.dart (ส่วนของการ Build Item ใน ListView)
                // นำไปแทนที่ในส่วน ListView.builder ใน Listtopproduct
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topProducts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
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

                    // สีกำกับ Rank 1, 2, 3
                    Color rankBgColor = const Color(0xFFF1F5F9);
                    Color rankTextColor = const Color(0xFF64748B);
                    if (index == 0) {
                      rankBgColor = const Color(0xFFFEF3C7);
                      rankTextColor = const Color(0xFFB45309);
                    } else if (index == 1) {
                      rankBgColor = const Color(0xFFE2E8F0);
                      rankTextColor = const Color(0xFF475569);
                    } else if (index == 2) {
                      rankBgColor = const Color(0xFFFFEDD5);
                      rankTextColor = const Color(0xFFC2410C);
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          // ป้ายอันดับ
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: rankBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: rankTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // รูปภาพสินค้า
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Builder(
                                builder: (context) {
                                  final String? imageName = item['image'];
                                  final String folderName = _getFolderName(
                                    item['category'],
                                  );
                                  final String serverUrl =
                                      '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/';

                                  if (imageName != null &&
                                      imageName.isNotEmpty) {
                                    final String imageUrl =
                                        imageName.startsWith('http')
                                        ? imageName
                                        : '$serverUrl$folderName/$imageName';
                                    return Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          _buildPlaceholder(),
                                    );
                                  }
                                  return _buildPlaceholder();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // ชื่อสินค้า & หมวดหมู่
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'] ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item['category'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ยอดขาย / จำนวน
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$quantity ชิ้น',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              if (item['category'] != 'borrow') ...[
                                const SizedBox(height: 2),
                                Text(
                                  '฿${NumberFormat('#,##0').format(revenue)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

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

 Widget _buildCategoryChip(String categoryKey, String label) {
  final isSelected = _selectedCategory == categoryKey;
  return ChoiceChip(
    label: Text(label),
    selected: isSelected,
    selectedColor: const Color(0xFF0F172A),
    backgroundColor: const Color(0xFFF8FAFC),
    side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    showCheckmark: false,
    labelStyle: TextStyle(
      color: isSelected ? Colors.white : const Color(0xFF64748B),
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      fontSize: 13,
    ),
    onSelected: (selected) {
      if (selected) {
        setState(() => _selectedCategory = categoryKey);
        _fetchTopProducts();
      }
    },
  );
}
}

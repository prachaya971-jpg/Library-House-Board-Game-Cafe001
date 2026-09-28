import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'req_product.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _foodList = [];
  List<dynamic> _filteredFoodList = [];
  List<dynamic> _typesList = [];
  dynamic _selectedTypeId = 'all';

  @override
  void initState() {
    super.initState();
    _fetchfood();
    _fetchTypes();
  }

  Future<void> _fetchfood() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPICUS.get('/menu/menu');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json != null && json['isError'] == false) {
          final List rawData = (json['data'] is List) ? json['data'] : [];
          if (mounted) {
            setState(() {
              _foodList = rawData;
              _filteredFoodList = List.from(_foodList);
              _applyFilter();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching foods: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterFood(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredFoodList = List.from(_foodList);
      } else {
        _filteredFoodList = _foodList.where((food) {
          final foodName = food['food_name']?.toString().toLowerCase() ?? '';
          final variantName =
              food['variant_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return foodName.contains(searchLower) ||
              variantName.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _fetchTypes() async {
    try {
      final response = await AppAPICUS.get('/food/types');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _typesList = (json['data'] is List) ? json['data'] : [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching types: $e");
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredFoodList = _foodList.where((item) {
        final String foodName = (item['food_name'] ?? '')
            .toString()
            .toLowerCase();

        final itemTypeId = item['food_type_id'];

        final matchesQuery = query.isEmpty || foodName.contains(query);

        final matchesType =
            (_selectedTypeId == null ||
                _selectedTypeId.toString().toLowerCase() == 'all' ||
                _selectedTypeId.toString() == '') ||
            (itemTypeId != null &&
                itemTypeId.toString() == _selectedTypeId.toString());

        return matchesQuery && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5A93C)),
      );
    }

    if (_foodList == null || _foodList.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีรายการสินค้า',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. แถบค้นหาแนวนอน + ปุ่มรีเฟรช
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาชื่ออาหาร...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
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
                                        _filterFood('');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5A93C),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) => _filterFood(value),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _buildCategorySelector(),
                ],
              ),
            ),

            Expanded(
              child: _filteredFoodList.isEmpty
                  ? const Center(
                      child: Text(
                        'ไม่พบรายการอาหารที่ค้นหา',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        90,
                      ), 
                      itemCount: _filteredFoodList.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio:
                                0.76, // สัดส่วนกำลังดี ไม่ล้นขอบจอ
                          ),
                      itemBuilder: (context, index) {
                        final item = _filteredFoodList[index];
                        final String foodName =
                            item['food_name']?.toString() ?? '';
                        final String variantName =
                            item['variant_name']?.toString() ?? '';
                        final String foodPrice =
                            item['food_variant_price']?.toString() ?? '0';
                        final String? imgName = item['img_food_url']
                            ?.toString();
                          final int foodVariantId = int.tryParse(item['food_variant_id']?.toString() ?? '') ?? 0;

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 1,
                          shadowColor: Colors.black.withOpacity(0.05),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReqFood(
                                    id:
                                        foodVariantId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // กล่องแสดงรูปภาพ ยืดเต็มตามความกว้างการ์ด
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            (imgName != null &&
                                                imgName.isNotEmpty)
                                            ? Image.network(
                                                '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgName',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => _buildDefaultImage(),
                                              )
                                            : _buildDefaultImage(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$foodName $variantName',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),

                                  // ราคา
                                  Text(
                                    '$foodPrice บาท',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(
                                        0xFFE5A93C,
                                      ), // ใช้สีส้ม/มัสตาร์ดขับให้ราคาเด่น
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // 3. ปุ่มตะกร้าสินค้าลอยมุมขวาล่าง
        Positioned(
          right: 16,
          bottom: 24,
          child: GestureDetector(
            onTap: () {
              debugPrint("กดเปิดตะกร้าสินค้า");
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFE5A93C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_basket_rounded,
                color: Colors.black87,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final List<dynamic> categories = [
      {
        'type_id': 'all',
        'type_name': 'ทั้งหมด', 
      },
      ..._typesList,
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final typeId =
              (cat['type_id'] ?? cat['food_type_id'])?.toString() ?? '';
          final typeName =
              (cat['type_name'] ?? cat['food_type_name'])?.toString() ?? '';
          final isSelected = _selectedTypeId.toString() == typeId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTypeId = typeId;
              });
              _applyFilter();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE5A93C)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  typeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 32),
    );
  }
}

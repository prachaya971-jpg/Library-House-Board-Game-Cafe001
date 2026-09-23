import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  bool _isLoading = false;
  List<dynamic> _foodList = [];

  @override
  void initState() {
    super.initState();
    _fetchfood();
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
        GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: _foodList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.70,
          ),
          itemBuilder: (context, index) {
            final item = _foodList[index];
            final String? foodName = item['food_name']?.toString();
            final String? variant_name = item['variant_name']?.toString();
            final String? food_variant_price = item['food_variant_price']
                ?.toString();
            final String? imgName = item['img_food_url']?.toString();
            return GestureDetector(
              onTap: () {
                debugPrint("กดเลือก: ${item['food_name']}");
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade100,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (imgName != null && imgName.isNotEmpty)
                                ? Image.network(
                                    '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/$imgName',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildDefaultImage(),
                                  )
                                : _buildDefaultImage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        '$foodName  $variant_name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Text(
                        '$food_variant_price บาท',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        Positioned(
          right: 16,
          bottom: 20,
          child: GestureDetector(
            onTap: () {
              debugPrint("กดเปิดตะกร้าสินค้า");
            },
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFFE5A93C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_basket_rounded,
                color: Colors.black87,
                size: 32,
              ),
            ),
          ),
        ),
      ],
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

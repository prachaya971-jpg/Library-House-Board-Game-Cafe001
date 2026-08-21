import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final TextEditingController _foodNameController = TextEditingController();

  List<dynamic> _typesList = [];
  List<dynamic> _optionsList = [];
  List<Map<String, dynamic>> _variantsList = [];

  String? _selectedTypeId;
  int? _activeVariantIndex; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTypes();
    _fetchOptions();
    _fetchVariants();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    for (var variant in _variantsList) {
      (variant['price_controller'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchTypes() async {
  try {
    final response = await AppAPI.get('/food/types');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['isError'] == false && json['data'] != null) {
        setState(() {
          _typesList = List.from(json['data']);
        });
      }
    }
  } catch (e) {
    print("Error fetching types: $e");
  }
}

Future<void> _fetchOptions() async {
  try {
    final response = await AppAPI.get('/food/options');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['isError'] == false && json['data'] != null) {
        setState(() {
          _optionsList = List.from(json['data']);
        });
      }
    }
  } catch (e) {
    print("Error fetching options: $e");
  }
}

Future<void> _fetchVariants() async {
  try {
    final response = await AppAPI.get('/food/variants');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['isError'] == false && json['data'] != null) {
        final List rawData = json['data'];
        setState(() {
          _variantsList = rawData.map<Map<String, dynamic>>((v) {
            return {
              'variant_id': v['variant_id'],
              'variant_name': v['variant_name'],
              'is_selected': false,
              'price_controller': TextEditingController(),
              'image_file': null,
              'option_ids': <int>[],
            };
          }).toList();
        });
      }
    }
  } catch (e) {
    print("Error fetching variants: $e");
  }
}

void _resetForm() {
    _foodNameController.clear();
    setState(() {
      _selectedTypeId = null;
      _activeVariantIndex = null;
      for (var variant in _variantsList) {
        variant['is_selected'] = false;
        (variant['price_controller'] as TextEditingController).clear();
        variant['image_file'] = null;
        (variant['option_ids'] as List<int>).clear();
      }
    });
  }

  Future<void> _submitFood() async {
    final selectedVariants = _variantsList
        .where((v) => v['is_selected'] == true)
        .toList();

    if (_foodNameController.text.trim().isEmpty ||
        _selectedTypeId == null ||  
        selectedVariants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลและเลือกรูปแบบอาหารอย่างน้อย 1 รายการ'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. สร้าง Multipart Request โดยใช้ AppConfig.apiBaseUri เดิม
      final uri = Uri.parse("${AppConfig.apiBaseUri}/food/create-food");
      final request = http.MultipartRequest('POST', uri);

      // 2. ดึง Token จาก SharedPreferences มาใส่ใน Header
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // 3. เตรียมข้อมูลตัวหนังสือ (Fields)
      final variantsPayload = selectedVariants.map((v) {
        return {
          'variant_id': v['variant_id'],
          'price': double.tryParse(
                (v['price_controller'] as TextEditingController).text,
              ) ?? 0.0,
          'option_ids': v['option_ids'],
        };
      }).toList();

      request.fields['food_name'] = _foodNameController.text.trim();
      request.fields['food_type_id'] = _selectedTypeId!;
      request.fields['variants'] = jsonEncode(variantsPayload);

      // 4. แนบไฟล์รูปภาพ
      final variantWithImage = selectedVariants.firstWhere(
        (v) => v['image_file'] != null,
        orElse: () => {},
      );

      if (variantWithImage.isNotEmpty && variantWithImage['image_file'] != null) {
        final XFile imageFile = variantWithImage['image_file'];
        final bytes = await imageFile.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'img_food_url', 
            bytes,
            filename: imageFile.name,
          ),
        );
      }

      // 5. ส่ง Request และรับ Response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);

     if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลอาหารและอัปโหลดรูปสำเร็จ'),
          ),
        );
        _resetForm(); 
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึก'),
          ),
        );
      }
    } catch (e) {
      print("Submit Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

 @override
  Widget build(BuildContext context) {
    const Color primary = Color.fromARGB(255, 8, 8, 8);

    if (_isLoading && _typesList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'เพิ่มข้อมูลอาหาร',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
            ),
            const SizedBox(height: 16),

            // 1. ชื่ออาหาร
            const Text('ชื่ออาหาร', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 6),
            TextField(
              controller: _foodNameController,
              decoration: InputDecoration(
                hintText: 'ระบุชื่ออาหาร',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // 2. ประเภทอาหาร
            const Text('ประเภทอาหาร', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedTypeId,
              hint: const Text('เลือกประเภทอาหาร'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: (_typesList ?? []).map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  value: item['food_type_id']?.toString() ?? '',
                  child: Text(item['food_type_name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedTypeId = newValue);
              },
            ),
            const SizedBox(height: 20),

            // 3. รายการรูปแบบอาหาร พร้อมกล่องท็อปปิ้งแยกประจำตัว
            const Text(
              'กำหนดรูปแบบและท็อปปิ้งประจำรูปแบบ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variantsList.length,
              itemBuilder: (context, vIndex) {
                final variant = _variantsList[vIndex];
                final bool isSelected = variant['is_selected'] ?? false;
                final List<int> selectedOptionIds = variant['option_ids'] as List<int>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แถวหัวข้อ: Checkbox รูปแบบ + ช่องราคา + ปุ่มรูปภาพ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              activeColor: Colors.blue,
                              onChanged: (bool? val) {
                                setState(() {
                                  variant['is_selected'] = val ?? false;
                                });
                              },
                            ),
                            Text(
                              variant['variant_name']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue.shade900 : Colors.black87,
                              ),
                            ),
                            const Spacer(),

                            // ช่องกรอกราคา (เปิดให้กรอกเมื่อติ๊กเลือก)
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: variant['price_controller'],
                                enabled: isSelected,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'ราคา (บาท)',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ปุ่มรูปภาพ
                            ElevatedButton.icon(
                              onPressed: !isSelected
                                  ? null
                                  : () async {
                                      final picker = ImagePicker();
                                      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
                                      if (picked != null) {
                                        setState(() {
                                          variant['image_file'] = picked;
                                        });
                                      }
                                    },
                              icon: Icon(
                                variant['image_file'] != null ? Icons.check_circle : Icons.image,
                                size: 16,
                                color: variant['image_file'] != null ? Colors.green : Colors.black87,
                              ),
                              label: Text(
                                variant['image_file'] != null ? 'เลือกแล้ว' : 'รูปภาพ',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ส่วนแสดงท็อปปิ้งเฉพาะของรูปแบบนี้ (กางออกมาเมื่อติ๊กเลือกรูปแบบ)
                      if (isSelected) ...[
                        const Divider(height: 1, thickness: 1),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เลือกท็อปปิ้งที่สามารถใส่กับ "${variant['variant_name']}" ได้:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // แสดงท็อปปิ้งเป็นปุ่มแท็ก (FilterChip) หรือ Checkbox แบบ Wrap
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 6.0,
                                children: (_optionsList ?? []).map((opt) {
                                  final int optionId = opt['options_id'];
                                  final bool hasOpt = selectedOptionIds.contains(optionId);

                                  return FilterChip(
                                    label: Text('${opt['option_name']} (+${opt['option_price']}บ.)'),
                                    selected: hasOpt,
                                    selectedColor: Colors.blue.shade100,
                                    checkmarkColor: Colors.blue.shade800,
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      color: hasOpt ? Colors.blue.shade900 : Colors.black87,
                                      fontWeight: hasOpt ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (bool selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedOptionIds.add(optionId);
                                        } else {
                                          selectedOptionIds.remove(optionId);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ปุ่มบันทึก
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('บันทึก', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

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
  List<dynamic> _optionsList = [];
  List<dynamic> _typesList = [];
    List<dynamic> _foodStatusList = [];
  int _currentRoleId = 2;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchfood();
    _fetchOptions();
    _fetchTypes();
    _fetchstatus();
  }

  Color getStatusColor(String statusId) {
    switch (statusId.toUpperCase()) {
      case 'N':
        return Colors.red.shade600; 
      case 'Y':
        return Colors.green.shade600; 
      case 'A':
        return Colors.amber.shade700; 
      default:
        return Colors.grey.shade600;
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
               final foodtype =
              food['food_type_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return foodName.contains(searchLower) ||
              variantName.contains(searchLower)||
              foodtype.contains(searchLower);
        }).toList();
      }
    });
  }

Future<void> _fetchstatus() async {
    try {
      final response = await AppAPI.get('/food/food-status');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['isError'] == false && json['data'] != null) {
          setState(() {
            _foodStatusList = List.from(json['data']);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching food status: $e");
    }
  }
  
  Future<void> _fetchTypes() async {
  try {
    final response = await AppAPI.get('/food/types');
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

  Future<void> _fetchOptions() async {
    try {
      final response = await AppAPI.get('/food/options');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json != null && json['isError'] == false) {
          final List rawOptions = (json['data'] is List) ? json['data'] : [];
          setState(() {
            _optionsList = rawOptions;
          });
        }
      }
    } catch (e) {
      print("Error fetching options: $e");
    }
  }

  // ดึงรายการอาหาร
  Future<void> _fetchfood() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/food/food');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json != null && json['isError'] == false) {
          final List rawData = (json['data'] is List) ? json['data'] : [];
          setState(() {
            _foodList = rawData;
            _filteredFoodList = List.from(_foodList);
          });
        }
      }
    } catch (e) {
      print("Error fetching foods: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final int foodId = item['food_id'] ?? 0;
    final int foodVariantId = item['food_variant_id'] ?? 0;
    final String foodName = item['food_name'] ?? item['name'] ?? 'รายการนี้';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณต้องการลบ "$foodName" ใช่หรือไม่?'),
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
      _deletefood(foodId, foodVariantId);
    }
  }

  // ส่ง API ลบข้อมูล
  Future<void> _deletefood(int id, int vid) async {
    try {
      final response = await AppAPI.post('/food/delete-food', {
        'food_id': id,
        'food_variant_id': vid,
      });

      final jsonRes = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && jsonRes['isError'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบข้อมูลสำเร็จ'),
            backgroundColor: Colors.black,
          ),
        );
        _fetchfood();
      } else {
        String rawError = jsonRes['errorMessage']?.toString() ?? '';
        String displayError = 'เกิดข้อผิดพลาด: $rawError';

        if (rawError.contains('1451') ||
            rawError.contains('foreign key constraint fails') ||
            rawError.contains('ER_ROW_IS_REFERENCED')) {
          displayError = 'ไม่สามารถลบได้ เนื่องจากมีการดำเนินการรายการนี้แล้ว';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayError),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting food: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  // ส่ง API ลบข้อมูล
 Future<void> _showEditFoodDialog(Map<String, dynamic> item) async {
    final foodNameController = TextEditingController(
      text: item['food_name'] ?? '',
    );
    final priceController = TextEditingController(
      text: (item['food_variant_price'] ?? '').toString(),
    );

    String? selectedTypeId = item['food_type_id']?.toString();

    // แปลง option_id (เช่น "1, 2") เป็น List<int>
    final String rawOptionIds = item['option_id']?.toString() ?? '';
    List<int> selectedOptionIds =
        rawOptionIds.contains('-') || rawOptionIds.isEmpty
            ? []
            : rawOptionIds
                .split(',')
                .map((id) => int.tryParse(id.trim()))
                .whereType<int>()
                .toList();

    XFile? newImageFile;
    bool isSubmittingDialog = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'แก้ไข: ${item['food_name']} (${item['variant_name']})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. ชื่ออาหาร
                      const Text(
                        'ชื่ออาหาร *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: foodNameController,
                        decoration: InputDecoration(
                          hintText: 'ระบุชื่ออาหาร',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Dropdown ประเภทอาหาร
                      const Text(
                        'ประเภทอาหาร *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: (_typesList.any((t) => t['food_type_id']?.toString() == selectedTypeId))
                            ? selectedTypeId
                            : null,
                        hint: const Text('เลือกประเภทอาหาร'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _typesList.map<DropdownMenuItem<String>>((type) {
                          return DropdownMenuItem<String>(
                            value: type['food_type_id']?.toString() ?? '',
                            child: Text(type['food_type_name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: isSubmittingDialog
                            ? null
                            : (val) {
                                setDialogState(() => selectedTypeId = val);
                              },
                      ),
                      const SizedBox(height: 14),

                      // 3. ราคาเฉพาะ Variant
                      const Text(
                        'ราคา (บาท) *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: 'ระบุราคา',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. รูปภาพอาหาร
                      const Text(
                        'รูปภาพอาหาร',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item['img_food_url'] != null &&
                                    item['img_food_url'].toString().isNotEmpty
                                ? Image.network(
                                    '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/food/${item['img_food_url']}',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) =>
                                        const Icon(Icons.fastfood, size: 40),
                                  )
                                : const Icon(Icons.fastfood, size: 40),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSubmittingDialog
                                ? null
                                : () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (picked != null) {
                                      setDialogState(() => newImageFile = picked);
                                    }
                                  },
                            icon: Icon(
                              newImageFile != null
                                  ? Icons.check_circle
                                  : Icons.upload,
                              size: 16,
                              color: newImageFile != null
                                  ? Colors.green
                                  : Colors.black87,
                            ),
                            label: Text(
                              newImageFile != null
                                  ? 'เลือกรูปใหม่แล้ว'
                                  : 'เปลี่ยนรูปภาพ',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. รายการท็อปปิ้ง
                      const Text(
                        'ท็อปปิ้งที่เลือกได้',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: _optionsList.map((opt) {
                          final int optId = opt['options_id'];
                          final bool isSelected = selectedOptionIds.contains(optId);

                          return FilterChip(
                            label: Text(
                              '${opt['option_name']} (+${opt['option_price']}บ.)',
                            ),
                            selected: isSelected,
                            selectedColor: Colors.blue.shade100,
                            checkmarkColor: Colors.blue.shade800,
                            onSelected: isSubmittingDialog
                                ? null
                                : (bool selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedOptionIds.add(optId);
                                      } else {
                                        selectedOptionIds.remove(optId);
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmittingDialog
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSubmittingDialog
                      ? null
                      : () async {
                          final String foodName = foodNameController.text.trim();
                          final String priceStr = priceController.text.trim();

                          if (foodName.isEmpty || priceStr.isEmpty || selectedTypeId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('กรุณากรอกข้อมูลและเลือกประเภทอาหารให้ครบถ้วน'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmittingDialog = true);

                          bool isSuccess = false;
                          try {
                            isSuccess = await _submitUpdateVariant(
                              foodId: item['food_id'],
                              foodVariantId: item['food_variant_id'],
                              foodName: foodName,
                              foodTypeId: selectedTypeId!,
                              price: double.tryParse(priceStr) ?? 0.0,
                              optionIds: selectedOptionIds,
                              imageFile: newImageFile,
                            );
                          } catch (e) {
                            debugPrint('Error updating food: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmittingDialog = false);
                            }
                          }

                          if (isSuccess && dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        },
                  child: isSubmittingDialog
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'บันทึกการแก้ไข',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

  }
  
  
   Future<bool> _submitUpdateVariant({
    required int foodId,
    required int foodVariantId,
    required String foodName,
    required String foodTypeId,
    required double price,
    required List<int> optionIds,
    XFile? imageFile,
  }) async {
    try {
      final uri = Uri.parse("${AppConfig.apiBaseUri}/food/update-foodvariant");
      final request = http.MultipartRequest('POST', uri);

      // แนบ Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // กำหนด Fields
      request.fields['food_id'] = foodId.toString();
      request.fields['food_variant_id'] = foodVariantId.toString();
      request.fields['food_name'] = foodName;
      request.fields['food_type_id'] = foodTypeId;
      request.fields['food_variant_price'] = price.toString();
      request.fields['option_ids'] = jsonEncode(optionIds);

      // แนบไฟล์รูปภาพ
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'img_food_url',
            bytes,
            filename: imageFile.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && !json['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ')));
          _fetchfood();
        }
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                json['errorMessage'] ?? 'เกิดข้อผิดพลาดในการบันทึก',
              ),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      print("Error submit update variant: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
      return false;
    }
  }

Future<void> _showStatusDropdownDialog(Map<String, dynamic> item) async {
  final String rawFoodName = item['food_name']?.toString() ?? '';
  final String rawVariantName = item['variant_name']?.toString() ?? item['food_variant_name']?.toString() ?? '';
  final String foodName = rawVariantName.isNotEmpty ? '$rawFoodName ($rawVariantName)' : rawFoodName;
  
  final currentStatusId = item['food_status_id']?.toString();
  final bool hasMatch = _foodStatusList.any(
    (status) => status['food_status_id']?.toString() == currentStatusId,
  );
  
  String? selectedStatusId = hasMatch ? currentStatusId : null;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(
              'แก้ไขสถานะ: $foodName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เลือกสถานะสินค้า', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatusId,
                    hint: const Text('เลือกสถานะ'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _foodStatusList.map<DropdownMenuItem<String>>((status) {
                      final statusId = status['food_status_id']?.toString() ?? '';
                      final statusName = status['food_status_name']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: statusId,
                        child: Text(
                          statusName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedStatusId = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: selectedStatusId == null
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _updatefoodStatus(item, selectedStatusId!);
                      },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _updatefoodStatus(Map<String, dynamic> item, String newStatusId) async {
  final int foodVariantId = item['food_variant_id'] ?? item['food_id'] ?? 0;

  setState(() => _isLoading = true);

  try {
    final response = await AppAPI.post(
      '/food/update-food-status',
      {
        'food_variant_id': foodVariantId,
        'food_status_id': newStatusId,
      },
    );

    final jsonRes = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonRes['isError'] == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตสถานะสำเร็จ'),
            backgroundColor: Color.fromARGB(255, 2, 2, 2),
          ),
        );
        _fetchfood();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถอัปเดตสถานะได้'}'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint("Error updating food status: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
    }
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
                    final String foodtype = item['food_type_name'] ?? '';
                    final double foodPrice =
                        double.tryParse(
                          item['price']?.toString() ??
                              item['food_variant_price']?.toString() ??
                              '0',
                        ) ??
                        0.0;
                    final String? imgName = item['img_food_url'];
                    final String option_name = item['option_name'] ?? '';
                    final String food_status_name =
                        item['food_status_name'] ?? '';
                    final String food_status_id = item['food_status_id'] ?? '';
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
                        title: Row(
                          children: [
                            // 1. ชื่ออาหาร และ รูปแบบ
                            Expanded(
                              child: Text(
                                '$foodName $foodvariant'.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),

              

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                  food_status_id,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: getStatusColor(
                                    food_status_id,
                                  ).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                food_status_name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: getStatusColor(food_status_id),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                foodtype.trim(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. ราคา
                              Text(
                                '฿${foodPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // 2. รายการท็อปปิ้ง
                              Text(
                                'ท็อปปิ้ง: ${option_name.isNotEmpty ? option_name : '-'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                          
                        trailing: isManager
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => _showEditFoodDialog(item),
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
                                   IconButton(
                                    icon: const Icon(
                                      Icons.change_circle_outlined,
                                      color: Color.fromARGB(255, 95, 93, 91),
                                    ),
                                    onPressed: () =>
                                        _showStatusDropdownDialog(item),
                                    tooltip: 'เปลี่ยนสถานะ',
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   IconButton(
                                    icon: const Icon(
                                      Icons.change_circle_outlined,
                                      color: Color.fromARGB(255, 95, 93, 91),
                                    ),
                                    onPressed: () =>
                                        _showStatusDropdownDialog(item),
                                    tooltip: 'เปลี่ยนสถานะ',
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

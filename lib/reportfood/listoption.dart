import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class ListOptions extends StatefulWidget {
  final int? roleId; 

  const ListOptions({super.key, this.roleId});

  @override
  State<ListOptions> createState() => _ListOptionsState();
}

class _ListOptionsState extends State<ListOptions> {
  bool _isLoading = false;
  List<dynamic> _optionsList = [];
  int _currentRoleId = 2; 

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchOptions();
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

  // 1. ดึงรายการ Option ทั้งหมด
  Future<void> _fetchOptions() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/food/options');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _optionsList = json['data'] ?? [];
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching options: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. แสดง Dialog แก้ไขรายการ Option
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    //  แก้ไข: เปลี่ยนจาก 'option_id' เป็น 'options_id' ให้ตรงกับ DB
    final int optionId = item['options_id'] ?? item['option_id'] ?? 0;
    final TextEditingController nameController = TextEditingController(
      text: item['option_name'] ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: item['option_price']?.toString() ?? '0',
    );

    XFile? pickedXFile;
    Uint8List? imageBytes;
    final ImagePicker picker = ImagePicker();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('แก้ไขท็อปปิ้ง / ตัวเลือกเสริม'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ชื่อท็อปปิ้ง',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'กรอกชื่อท็อปปิ้ง',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ราคา',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'กรอกราคา',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('เปลี่ยนรูปภาพ (ถ้ามี)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? file = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (file != null) {
                              final bytes = await file.readAsBytes();
                              setDialogState(() {
                                pickedXFile = file;
                                imageBytes = bytes;
                              });
                            }
                          },
                          icon: const Icon(Icons.image, size: 18),
                          label: Text(pickedXFile == null
                              ? 'เลือกรูปภาพใหม่'
                              : 'เปลี่ยนรูปภาพ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pickedXFile != null)
                          const Expanded(
                            child: Text(
                              'เลือกไฟล์ใหม่แล้ว',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child:
                      const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD49A32),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('บันทึก', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true) {
      final String newName = nameController.text.trim();
      final double newPrice = double.tryParse(priceController.text.trim()) ?? 0;

      if (newName.isNotEmpty) {
        _updateOption(
          id: optionId,
          newName: newName,
          newPrice: newPrice,
          imageBytes: imageBytes,
          pickedXFile: pickedXFile,
        );
      }
    }
  }

  // ส่ง API แก้ไขข้อมูล Option
  Future<void> _updateOption({
    required int id,
    required String newName,
    required double newPrice,
    Uint8List? imageBytes,
    XFile? pickedXFile,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final uri = Uri.parse('${AppConfig.apiBaseUri}/food/update-option');
      var request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['options_id'] = id.toString();
      request.fields['option_name'] = newName;
      request.fields['option_price'] = newPrice.toString();

      if (imageBytes != null && pickedXFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'options_img',
            imageBytes,
            filename: pickedXFile.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แก้ไขข้อมูลตัวเลือกสำเร็จ')),
          );
        }
        _fetchOptions(); // โหลดรายการใหม่
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถแก้ไขได้'}')),
          );
        }
      }
    } catch (e) {
      print("Error updating option: $e");
    }
  }

  // 3. แสดง Dialog ยืนยันการลบ Option
  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final int optionId = item['options_id'] ?? item['option_id'] ?? 0;
    final String optionName = item['option_name'] ?? '';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณต้องการลบท็อปปิ้ง "$optionName" ใช่หรือไม่?'),
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
      _deleteOption(optionId);
    }
  }

  // ส่ง API ลบข้อมูล
  Future<void> _deleteOption(int id) async {
    try {
      
      final response = await AppAPI.post('/food/delete-option', {
        'options_id': id,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
          );
        }
        _fetchOptions(); // โหลดรายการใหม่
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถลบได้'}')),
          );
        }
      }
    } catch (e) {
      print("Error deleting option: $e");
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
                'รายการท็อปปิ้ง / ตัวเลือกเสริม (Options)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              IconButton(
                onPressed: _fetchOptions,
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
              : _optionsList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('ไม่พบรายการตัวเลือกเสริม')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _optionsList.length,
                      itemBuilder: (context, index) {
                        final item = _optionsList[index];
                        final String optionName = item['option_name'] ?? '';
                        final num optionPrice = num.tryParse(
                                item['option_price']?.toString() ?? '0') ??
                            0;
                        final String? imgName = item['options_img'];

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
                                      'http://localhost:3000/img/options/$imgName',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildDefaultAvatar(index),
                                    )
                                  : _buildDefaultAvatar(index),
                            ),
                            title: Text(
                              optionName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '+฿${optionPrice.toStringAsFixed(0)}',
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
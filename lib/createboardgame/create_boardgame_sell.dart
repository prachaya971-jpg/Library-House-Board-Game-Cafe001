import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:cafa_boardgame/utils/appapi.dart';

class CreateBoardgameSell extends StatefulWidget {
  const CreateBoardgameSell({super.key});

  @override
  State<CreateBoardgameSell> createState() => _CreateBoardgameSellState();
}

class _CreateBoardgameSellState extends State<CreateBoardgameSell> {
  final TextEditingController _sellboardgamenameController =
      TextEditingController();
  final TextEditingController _sellboardgamequantityController =
      TextEditingController();
  final TextEditingController _sellboardgamepriceController =
      TextEditingController();
  final TextEditingController _sellboardgamebarcodeController =
      TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchTypes();
  }

  bool _isLoading = false;
  List<dynamic> _typesList = [];
  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  List<bool> _checkboxValues = [];

  bool _isSubmitting = false;
  // คำสั่งดึงประเภทมาเป้น checkbox (มีไปทำไม)
  Future<void> _fetchTypes() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/boardgame/report-type');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _typesList = json['data'] ?? [];
            _checkboxValues = List<bool>.filled(_typesList.length, false);
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

  final ImagePicker _picker = ImagePicker();

  // เลือกรูปภาพ
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedXFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitboardgamecreate() async {
    final String sellboardgamename = _sellboardgamenameController.text.trim();
    final String sellboardgamequantity = _sellboardgamequantityController.text.trim();
    final double? sellboardgameprice = double.tryParse(_sellboardgamepriceController.text.trim());
    final String sellboardgamebarcode = _sellboardgamebarcodeController.text.trim();

    if (sellboardgamename.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อบอร์ดเกม')));
      return;
    }

    if (sellboardgamequantity.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวน')));
      return;
    }
    if (sellboardgameprice == null ) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('กรุณากรอกราคา')));
          return;
        }

    final int? quantity = int.tryParse(sellboardgamequantity);
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนด้วยตัวเลขจำนวนเต็ม')),
      );
      return;
    }

    final int? barcode = int.tryParse(sellboardgamebarcode);
    if (barcode == null || barcode < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนด้วยตัวเลขรหัส barcode')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มข้อมูล'),
          content: Text(
            'คุณต้องการเพิ่มบอร์ดเกมชื่อ "$sellboardgamename" (จำนวน $quantity, ราคา $sellboardgameprice) ใช่หรือไม่?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 167, 66),
              ),
              child: const Text(
                'ยืนยัน',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final uri = Uri.parse(
        '${AppConfig.apiBaseUri}/boardgame_for_sell/createboardgame_sell',
      );
      var request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['boardgame_sell_name'] = sellboardgamename;
      request.fields['boardgame_sell_quantity'] = quantity.toString();
      request.fields['boardgame_sell_price'] = sellboardgameprice.toString();
      request.fields['boardgame_sell_barcode'] = sellboardgamebarcode;

      if (_imageBytes != null && _pickedXFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'boardgame_sell_img',
            _imageBytes!,
            filename: _pickedXFile!.name,
          ),
        );
      }

      // ลูปเอาประเภทไปส่ง backend
      List<int> selectedCatagoryId = [];
      for (int i = 0; i < _typesList.length; i++) {
        if (i < _checkboxValues.length && _checkboxValues[i] == true) {
          final catId =
              _typesList[i]['catagory_bg_id'] ??
              _typesList[i]['boardgame_type_id'];
          if (catId != null) {
            selectedCatagoryId.add(int.parse(catId.toString()));
          }
        }
      }
      request.fields['catagory_id'] = jsonEncode(selectedCatagoryId);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('เพิ่มบอร์ดเกมสำเร็จ')));
          _sellboardgamenameController.clear();
          _sellboardgamequantityController.clear();
          _sellboardgamepriceController.clear();
          _sellboardgamebarcodeController.clear();
          setState(() {
            _pickedXFile = null;
            _imageBytes = null;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถบันทึกได้'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error creating option: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color.fromARGB(255, 8, 8, 8);

    if (_isSubmitting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
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
            'เพิ่มบอร์ดเกม',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ชื่อบอร์ดเกม',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _sellboardgamenameController,
            decoration: InputDecoration(
              hintText: 'ระบุชื่อบอร์ดเกม',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'จำนวน',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _sellboardgamequantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
            decoration: InputDecoration(
              hintText: 'ระบุจำนวน',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ราคา',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _sellboardgamepriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
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
          const SizedBox(height: 16),

          const Text(
            'รหัส barcode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _sellboardgamebarcodeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [LengthLimitingTextInputFormatter(13)],
            decoration: InputDecoration(
              hintText: 'กรอกรหัส barcode(สามารถใช้เครื่องแสกนในการกรอกได้)',
              border: OutlineInputBorder( 
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'รูปประกอบ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // 1. ปุ่มเลือก/เปลี่ยนรูปภาพ
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image, color: Colors.black87),
              label: Text(
                _pickedXFile == null ? 'เลือกรูปภาพ' : 'เปลี่ยนรูปภาพ',
                style: const TextStyle(color: Colors.black87),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                elevation: 0,
              ),
            ),
          ),

          if (_pickedXFile != null && _imageBytes != null) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                double imageSize = MediaQuery.of(context).size.width * 0.010;
                if (imageSize < 60) imageSize = 60;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pickedXFile!.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 30),

          //Checkbox ประเภท
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _typesList.length,
                  itemBuilder: (context, index) {
                    final item = _typesList[index];
                    final isSelected = _checkboxValues.length > index
                        ? _checkboxValues[index]
                        : false;
                    final String typeName = item['catagory_bg_name'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            _checkboxValues[index] = value ?? false;
                          });
                        },
                        title: Text(
                          typeName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.blue,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        dense: true,
                      ),
                    );
                  },
                ),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitboardgamecreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

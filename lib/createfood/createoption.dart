import 'dart:convert';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class CreateOptionPage extends StatefulWidget {
  const CreateOptionPage({super.key});

  @override
  State<CreateOptionPage> createState() => _CreateOptionPageState();
}

class _CreateOptionPageState extends State<CreateOptionPage> {
  final TextEditingController _optionNameController = TextEditingController();
  final TextEditingController _optionPriceController = TextEditingController();
  
  
  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  //  เลือกรูปภาพ
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedXFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitOption() async {
    final String optionName = _optionNameController.text.trim();
    final String priceText = _optionPriceController.text.trim();

    if (optionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อท็อปปิ้ง/ตัวเลือก')),
      );
      return;
    }

    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกราคา')),
      );
      return;
    }

    final double? price = double.tryParse(priceText);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกราคาให้ถูกต้อง')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มข้อมูล'),
          content: Text('คุณต้องการเพิ่มท็อปปิ้ง "$optionName" (ราคา $price บาท) ใช่หรือไม่?'),
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
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
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

      final uri = Uri.parse('${AppConfig.apiBaseUri}/food/create-option');
      var request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['option_name'] = optionName;
      request.fields['option_price'] = price.toString();

      if (_imageBytes != null && _pickedXFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'options_img',
            _imageBytes!,
            filename: _pickedXFile!.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เพิ่มตัวเลือกใหม่สำเร็จ')),
          );
          _optionNameController.clear();
          _optionPriceController.clear();
          setState(() {
            _pickedXFile = null;
            _imageBytes = null;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถบันทึกได้'}'),
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
            'เพิ่มท็อปปิ้ง / ตัวเลือกเสริม',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'ชื่อท็อปปิ้ง',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _optionNameController,
            decoration: InputDecoration(
              hintText: 'ระบุชื่อท็อปปิ้ง',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ราคา',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _optionPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: 'ระบุราคา',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'รูปประกอบ (ถ้ามี)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
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
              const SizedBox(width: 12),
              if (_pickedXFile != null)
                const Text(
                  'เลือกไฟล์แล้ว',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 30),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitOption,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('บันทึก', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
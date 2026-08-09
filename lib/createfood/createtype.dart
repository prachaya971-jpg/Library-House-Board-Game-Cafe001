import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/utils/appapi.dart';

class CreateTypesPage extends StatefulWidget {
  const CreateTypesPage({super.key});

  @override
  State<CreateTypesPage> createState() => _CreateTypesPageState();
}

class _CreateTypesPageState extends State<CreateTypesPage> {
  final TextEditingController _typeNameController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitType() async {
    final String typeName = _typeNameController.text.trim();
    if (typeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อประเภท')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มข้อมูล'),
          content: Text('คุณต้องการเพิ่มประเภท "$typeName" ใช่หรือไม่?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // ตอบ ยกเลิก
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // ตอบ ยืนยัน
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 167, 66),
              ),
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    // หากผู้ใช้กด "ยกเลิก" หรือปิด Dialog ให้หยุดการทำงาน
    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await AppAPI.post(
        '/food/create-type',
        {'type_name': typeName},
      );

      var jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เพิ่มประเภทใหม่สำเร็จ')),
          );
          _typeNameController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถบันทึกได้'}'),
            ),
          );
          print('Error creating type: ${jsonRes['errorMessage'] ?? 'ไม่สามารถบันทึกได้'}');
        }
      }
    } catch (e) {
      print("Error creating type: $e");
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
            'เพิ่มประเภท (Type)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'ชื่อประเภท',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _typeNameController,
            decoration: InputDecoration(
              hintText: 'ระบุชื่อประเภท',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 30),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitType,
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
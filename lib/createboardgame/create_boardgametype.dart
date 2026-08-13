import 'dart:convert';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:cafa_boardgame/utils/appapi.dart';

class CreateBoardgametype extends StatefulWidget {
  const CreateBoardgametype({super.key});

  @override
  State<CreateBoardgametype> createState() => _CreateBoardgametypeState();
}

class _CreateBoardgametypeState extends State<CreateBoardgametype> {
  final TextEditingController _boardgametypeNameController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitType() async {
    final String boardgametypeName = _boardgametypeNameController.text.trim();
    if (boardgametypeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อประเภทบอร์ดเกม')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มข้อมูล'),
          content: Text('คุณต้องการเพิ่มประเภท "$boardgametypeName" ใช่หรือไม่?'),
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
        '/boardgame/create-type',
        {'boardgame_typename': boardgametypeName},
      );

      var jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เพิ่มประเภทใหม่สำเร็จ')),
          );
          _boardgametypeNameController.clear();
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
            controller: _boardgametypeNameController,
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
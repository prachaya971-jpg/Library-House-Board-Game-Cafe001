import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sendadvice extends StatefulWidget {
  const Sendadvice({super.key});

  @override
  State<Sendadvice> createState() => _SendadviceState();
}

class _SendadviceState extends State<Sendadvice> {
  bool _isChecking = false;

  Future<void> _markreq() async {
    final messenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('customer_table_token');

    String? tableNumber;

    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      tableNumber = (decodedToken['table_number'] ?? decodedToken['tableno'])
          ?.toString();
    } else {
      print('ไม่พบ Token โต๊ะ หรือหมดอายุการใช้งาน');
    }

    if (!mounted) return;

    if (tableNumber == null || tableNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลโต๊ะ กรุณาสแกน QR Code ใหม่อีกครั้ง'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("ยืนยันการขอคำเเนะนำ"),
        content: Text(
          'ต้องการยืนยันการขอคำเเนะนำสำหรับโต๊ะ "$tableNumber" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF51A742),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'ยืนยันการขอคำเเนะนำ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await AppAPICUS.post('/advice-cus/reqadvice', {
          'table_no': tableNumber,
        });

        final jsonRes = jsonDecode(response.body);

        if (response.statusCode == 200 && !jsonRes['isError']) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('จัดการรายการของโต๊ะ $tableNumber เรียบร้อยแล้ว'),
            ),
          );
        } else {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถอัปเดตได้'}',
              ),
            ),
          );
        }
      } catch (e) {
        print("Error updating advice status: $e");
      }
    }
  }

  Future<void> _handleCheckAndSubmit() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('customer_table_token');

    String? tableNumber;

    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      tableNumber = (decodedToken['table_number'] ?? decodedToken['tableno'])
          ?.toString();
    } else {
      print('ไม่พบ Token โต๊ะ หรือหมดอายุการใช้งาน');
    }

    if (!mounted) return;

    if (tableNumber == null || tableNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลโต๊ะ กรุณาสแกน QR Code ใหม่อีกครั้ง'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (tableNumber == null || tableNumber.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบหมายเลขโต๊ะ กรุณาสแกน QR Code ใหม่อีกครั้ง'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final response = await AppAPICUS.get(
        '/advice-cus/getadviceList?table_no=$tableNumber',
      );

      dynamic resData;
      if (response.statusCode == 200) {
        resData = jsonDecode(response.body);
      }

      final bool hasPending =
          resData != null &&
          (resData['hasPending'] == true ||
              (resData['data'] is List &&
                  (resData['data'] as List).isNotEmpty));

      if (hasPending) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'โต๊ะ $tableNumber มีคำขอส่งไปแล้ว กำลังรอพนักงานดำเนินการ',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        return;
      }

      await _markreq();
    } catch (e) {
      debugPrint("Error checking advice status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการตรวจสอบสถานะคำขอ')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.support_agent,
                color: Color(0xFFD97706),
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'ส่งคำขอเเนะนำ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _handleCheckAndSubmit();
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('ส่งคำขอเเนะนำ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/cusapp_sidebar.dart';
import 'product/product_page.dart';
import 'boardgame/boardgame_page.dart';
import 'senddvice/sendadvice.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:cafa_boardgame/socket_service.dart';

class MenuHomeScreen extends StatefulWidget {
  const MenuHomeScreen({super.key});

  @override
  State<MenuHomeScreen> createState() => _MenuHomeScreenState();
}

class _MenuHomeScreenState extends State<MenuHomeScreen> {
  int _selectedTabIndex = 0;
  StreamSubscription? _tableClearedSub;

  final List<Widget> _pages = const [
    ProductPage(),
    BoardGamePage(),
    Sendadvice(),
  ];

  @override
  void initState() {
    super.initState();
    _listenTableCleared();
  }

  void _listenTableCleared() {
    _tableClearedSub = SocketService().onTableCleared.listen((data) async {
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('customer_table_token');
      await prefs.remove('saved_nickname');
      await prefs.remove('client_device_id');


      
      if (kIsWeb) {
        html.window.localStorage.remove('flutter.customer_table_token');
        html.window.localStorage.remove('flutter.flutter.client_device_id');
        html.window.localStorage.remove('customer_table_token');
        html.window.localStorage.remove('flutter.saved_nickname');
      }

      // 3. แสดง Modal แจ้งเตือนและดีดกลับหน้าแรก
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('ชำระเงินเรียบร้อย'),
              ],
            ),
            content: Text(
              data['message']?.toString() ??
                  'โต๊ะนี้เช็กบิลเรียบร้อยแล้ว ขอบคุณที่ใช้บริการ',
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF51A742),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);

                  if (mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/menucus', (route) => false);
                  }
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tableClearedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        // ใช้ IndexedStack เพื่อให้ UI จำตำแหน่ง scroll เดิมตอนสลับแท็บ
        child: IndexedStack(index: _selectedTabIndex, children: _pages),
      ),
      bottomNavigationBar: CustomerBottomBar(
        currentIndex: _selectedTabIndex,
        onTapIndex: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }
}

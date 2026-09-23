import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/cusapp_sidebar.dart';
import 'product_page.dart';
import 'boardgame_page.dart';
import 'sendadvice.dart';

class MenuHomeScreen extends StatefulWidget {
  const MenuHomeScreen({super.key});

  @override
  State<MenuHomeScreen> createState() => _MenuHomeScreenState();
}

class _MenuHomeScreenState extends State<MenuHomeScreen> {
  int _selectedTabIndex = 0;

  final List<Widget> _pages = const [
    ProductPage(),
    BoardGamePage(),
    Sendadvice(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        // ใช้ IndexedStack เพื่อให้ UI จำตำแหน่ง scroll เดิมตอนสลับแท็บ
        child: IndexedStack(
          index: _selectedTabIndex,
          children: _pages,
        ),
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
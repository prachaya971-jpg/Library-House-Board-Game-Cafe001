import 'package:flutter/material.dart';

class BoardGamePage extends StatefulWidget {
  const BoardGamePage({super.key});

  @override
  State<BoardGamePage> createState() => _BoardGamePageState();
}

class _BoardGamePageState extends State<BoardGamePage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'หน้าบอร์ดเกม',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
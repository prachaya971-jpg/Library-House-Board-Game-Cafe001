import 'package:flutter/material.dart';

class Cusorder extends StatefulWidget {
  final String? tableNum;

  const Cusorder({super.key, this.tableNum});

  @override
  State<Cusorder> createState() => _CusorderState();
}

class _CusorderState extends State<Cusorder> {
  String _currentTable = '-';

  @override
  void initState() {
    super.initState();
    _resolveTableNumber();
  }

  void _resolveTableNumber() {

    if (widget.tableNum != null && widget.tableNum!.isNotEmpty) {
      _currentTable = widget.tableNum!;
      return;
    }

  
    final uri = Uri.base;
    String? table = uri.queryParameters['table'];

    if (table == null && uri.fragment.isNotEmpty) {
      final fragment = uri.fragment; 
      if (fragment.contains('?')) {
        final queryPart = fragment.substring(fragment.indexOf('?'));
        table = Uri.parse(queryPart).queryParameters['table'];
      }
    }

    setState(() {
      _currentTable = table ?? '1'; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'หน้าจอสั่งอาหารสำหรับโต๊ะ: $_currentTable',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
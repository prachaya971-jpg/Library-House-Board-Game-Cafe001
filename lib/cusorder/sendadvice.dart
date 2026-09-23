import 'package:flutter/material.dart';

class Sendadvice extends StatefulWidget {
  const Sendadvice({super.key});

  @override
  State<Sendadvice> createState() => _SendadviceState();
}

class _SendadviceState extends State<Sendadvice> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'หน้าให้คำปรึกษา',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
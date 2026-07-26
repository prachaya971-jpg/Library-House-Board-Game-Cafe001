import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'login.dart'; // import หน้า login ไว้สำหรับกดเปลี่ยนหน้า

class testbarcodegen extends StatefulWidget {
  const testbarcodegen({Key? key}) : super(key: key);

  @override
  State<testbarcodegen> createState() => _testbarcodegenState();
}

class _testbarcodegenState extends State<testbarcodegen> {
  // รหัสเริ่มต้น (ตัวอย่าง EAN-13 แบบ Internal ใส่ 12 หลักแรก)
  String _barcodeData = '200000000123'; 
  bool _isEan13 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Game Barcode Generator'),
        backgroundColor: Colors.indigo,
        actions: [
          // ปุ่มสำหรับกดไปหน้า Login ที่มุมขวาบน
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'ไปหน้า Login',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ตัวอย่างป้ายบาร์โค้ดบอร์ดเกม',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // ส่วนแสดงบาร์โค้ด
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: BarcodeWidget(
                      barcode: _isEan13 ? Barcode.ean13() : Barcode.code128(), 
                      data: _barcodeData,
                      width: 280,
                      height: 100,
                      drawText: true,
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.black,
                      ),
                      errorBuilder: (context, error) => Center(
                        child: Text(
                          'รหัสไม่ถูกต้องสำหรับชนิดนี้!\n($error)',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ช่องกรอกรหัสทดสอบ
                  TextField(
                    decoration: InputDecoration(
                      labelText: _isEan13 ? 'กรอกเลข 12 หลัก (EAN-13)' : 'กรอกรหัสอะไรก็ได้ (Code 128)',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _barcodeData = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // ปุ่มสลับประเภท Barcode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('EAN-13 (เน้นตัวเลข)'),
                        selected: _isEan13,
                        onSelected: (selected) {
                          setState(() {
                            _isEan13 = true;
                            _barcodeData = '200000000123';
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('Code 128 (ผสมตัวอักษร)'),
                        selected: !_isEan13,
                        onSelected: (selected) {
                          setState(() {
                            _isEan13 = false;
                            _barcodeData = 'BG-CATAN-TH01';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _pricevariantFoodController =
      TextEditingController();

  //  Mock Data: ประเภทอาหาร
  final List<Map<String, dynamic>> _mockTypesList = [
    {'food_type_id': 1, 'food_type_name': 'เครื่องดื่ม'},
    {'food_type_id': 2, 'food_type_name': 'ของทานเล่น'},
    {'food_type_id': 3, 'food_type_name': 'เบเกอรี่'},
  ];

  //  Mock Data: ท็อปปิ้งทั้งหมด
  final List<Map<String, dynamic>> _mockOptionsList = [
    {'options_id': 101, 'option_name': 'ไข่มุก', 'option_price': 10.00},
    {'options_id': 102, 'option_name': 'โอริโอ้', 'option_price': 15.00},
    {'options_id': 103, 'option_name': 'หวานน้อย ', 'option_price': 0.00},
    {'options_id': 104, 'option_name': 'หวานกลาง', 'option_price': 0.00},
    {'options_id': 105, 'option_name': 'วิปครีม', 'option_price': 15.00},
  ];

  // Map เก็บ State ของรูปแบบ (ร้อน/เย็น/ปั่น)
  final List<Map<String, dynamic>> _variantList = [
    {'variant_id': 1, 'variant_name': 'ร้อน'},
    {'variant_id': 2, 'variant_name': 'เย็น'},
    {'variant_id': 3, 'variant_name': 'ปั่น'},
  ];
  String? _selectedTypeId;
  @override
  void initState() {
    super.initState();
  }

  // ตัวแปรสำหรับแสดงสถานะกำลังบันทึก


  Future<void> _submitFood() async {
      print('บันทึกสำเร็จ:');
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color.fromARGB(255, 8, 8, 8);

    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
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
          // หัวข้อหลัก
          const Text(
            'เพิ่มข้อมูลอาหาร',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ชื่ออาหาร',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _foodNameController,
                      decoration: InputDecoration(
                        hintText: 'ระบุชื่ออาหาร',

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. เลือกประเภทอาหาร
                    const Text(
                      'ประเภทอาหาร',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedTypeId,
                      hint: const Text('เลือกประเภทอาหาร'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _mockTypesList.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['food_type_id'].toString(),
                          child: Text(item['food_type_name'].toString()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTypeId = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. รูปแบบอาหาร
                    const Text(
                      'รูปแบบอาหาร',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),

                      //  เพิ่ม child: ตรงนี้
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _variantList.length,
                        itemBuilder: (context, index) {
                          final item = _variantList[index];
                          final bool isSelected = item['is_selected'] ?? false;

                          // สร้าง TextEditingController แยกเฉพาะสำหรับช่องราคาของแต่ละแถว
                          item['price_controller'] ??= TextEditingController(
                            text: item['variant_price']?.toString() ?? '',
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: Colors.blue,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  dense: true,

                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['variant_name']?.toString() ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // 2. ช่องกรอกราคา (ฝั่งขวา)
                                      SizedBox(
                                        width: 85, // กำหนดความกว้างช่องราคา
                                        child: TextField(
                                          controller:
                                              _pricevariantFoodController, // ใช้ controller ประจำแถว
                                          keyboardType: TextInputType
                                              .number, // โชว์คีย์บอร์ดตัวเลข
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d*'),
                                            ),
                                          ],
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            hintText: 'ราคา',
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            // บันทึกค่าราคาลงใน Map ของแถวนั้นๆ
                                            item['variant_price'] = val;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      //  3. ปุ่มอัปโหลดรูปภาพ (เพิ่มใหม่)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO
                                        },
                                        icon: const Icon(Icons.image,color: Colors.black87,),
                                        label: Text('เลือกรูปภาพ',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          elevation: 0,
                                        ),
                                      ),
                                       
                                    ],
                                  ),
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      item['is_selected'] = newValue ?? false;
                                    });
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ท็อปปิ้ง',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 320,
                      ), // ขยายความสูงให้สมดุลกับความยาวของฝั่งซ้าย
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _mockOptionsList.length,
                        itemBuilder: (context, index) {
                          final item = _mockOptionsList[index];
                          final bool isSelected = item['is_selected'] ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: Colors.blue,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  dense: true,
                                  title: Text(
                                    item['option_name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      item['is_selected'] = newValue ?? false;
                                    });
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

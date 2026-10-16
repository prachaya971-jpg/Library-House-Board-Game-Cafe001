import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/createboardgame/create_boardgame_sell.dart';

class ReportBoardgameforsell extends StatefulWidget {
  final int? roleId;

  const ReportBoardgameforsell({super.key, this.roleId});

  @override
  State<ReportBoardgameforsell> createState() => _ReportBoardgameforsellState();
}

class _ReportBoardgameforsellState extends State<ReportBoardgameforsell> {
  bool _isLoading = false;
  List<dynamic> _bgsellList = [];
  int _currentRoleId = 2;
  List<dynamic> _typesList = [];
  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  List<bool> _checkboxValues = [];
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredboardgamesell = [];

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchbgsell();
    _fetchTypes();
  }

  // สำหรับดึงประเภทบอร์ดเกม
  Future<void> _fetchTypes() async {
    try {
      final response = await AppAPI.get('/boardgame/report-type');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _typesList = json['data'] ?? [];
          });
        }
      }
    } catch (e) {
      print("Error fetching types: $e");
    }
  }

  // เลือกรูปภาพจาก Gallery
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _pickedXFile = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _filterboardgamesell(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredboardgamesell = List.from(_bgsellList);
      } else {
        _filteredboardgamesell = _bgsellList.where((bgsell) {
          final bgsellName = bgsell['bg_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return bgsellName.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadRole() async {
    if (widget.roleId != null) {
      setState(() => _currentRoleId = widget.roleId!);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (mounted) {
        setState(() {
          _currentRoleId = decodedToken['emp_role_id'] ?? 2;
        });
      }
    }
  }

  //สร้าง barcode
  Widget buildBarcode(String barcodeNumber) {
    if (barcodeNumber.trim().isEmpty) {
      return const Text('ไม่มีบาร์โค้ด', style: TextStyle(color: Colors.grey));
    }

    // แยก บาร์โค้ด
    final List<String> barcodes = barcodeNumber
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      children: barcodes.map((code) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: code,
            width: 250,
            height: 80,
            drawText: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  // function แสดงข้อมูลของปุ่มแสดงรายละเอียด
  void _showDetailDialog(Map<String, dynamic> item) {
    final String? imgName = item['img_game_sale'] ?? item['sell_img'];
    // final int bgsellid = item['bg_id'] ?? '';
    final String imagepath = imgName != null && imgName.isNotEmpty
        ? '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/boardgame/$imgName'
        : '';

    final String barcodeData = item['barcodelist']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'รายละเอียดบอร์ดเกม',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                // const SizedBox(height: 200),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: imgName != null && imgName.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imagepath,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ไม่มีรูปภาพ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                const SizedBox(height: 20),
                // ข้อความ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อบอร์ดเกม/ชื่อประเภท
                    Text(
                      item['bg_name'] ?? 'ไม่มีชื่อรายการ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // จำนวน
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'จำนวนที่มี: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['quantity'].toString(),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    // id
                    Row(
                      children: [
                        const Text(
                          'ราคา: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          (item['price'] ??
                                  item['boardgame_sell_price'] ??
                                  'ไม่พบราคา')
                              .toString(),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // ประเภท
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ประเภท: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['catagorylist'] ?? 'ไม่ทราบประเภท',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                //แสดง barcode
                const SizedBox(height: 16),
                const Text(
                  'รายการบาร์โค้ด:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: buildBarcode(barcodeData)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchbgsell() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/boardgame/report-bgsell');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _bgsellList = json['data'] ?? [];
            _filteredboardgamesell = List.from(_bgsellList);
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching types: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // แสดง Dialog แก้ไขรายการ
  // 2. แสดง Dialog แก้ไขรายการ
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final int bgsellid =
        item['bgsell_id'] ?? item['bg_id'] ?? item['bgs_id'] ?? 0;
    final TextEditingController nameController = TextEditingController(
      text: item['bg_name'] ?? '',
    );
    final TextEditingController quantityController = TextEditingController(
      text: item['quantity']?.toString() ?? '0',
    );
    final TextEditingController priceController = TextEditingController(
      text: item['price']?.toString() ?? '0',
    );

    _pickedXFile = null;
    _imageBytes = null;

    String currentCatStr = item['catagorylist']?.toString() ?? '';
    List<String> currentCatNames = currentCatStr
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();

    List<bool> dialogCheckboxValues = List<bool>.generate(_typesList.length, (
      index,
    ) {
      final typeItem = _typesList[index];
      final String typeName = (typeItem['catagory_bg_name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return currentCatNames.contains(typeName);
    });

    final dynamic confirm = await showDialog<dynamic>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (dialogCheckboxValues.length != _typesList.length) {
              dialogCheckboxValues = List<bool>.generate(_typesList.length, (
                index,
              ) {
                final typeItem = _typesList[index];
                final String typeName = (typeItem['catagory_bg_name'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
                return currentCatNames.contains(typeName);
              });
            }

            return AlertDialog(
              title: const Text('แก้ไขข้อมูลบอร์ดเกมสำหรับขาย'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8 > 500
                    ? 500
                    : MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ชื่อบอร์ดเกม',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'กรอกชื่อบอร์ดเกม',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'จำนวน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'กรอกจำนวน',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ราคา (บาท)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'กรอกราคาขาย',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _pickImage();
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.image, color: Colors.black87),
                          label: Text(
                            _pickedXFile == null
                                ? 'เลือกรูปภาพ'
                                : 'เปลี่ยนรูปภาพ',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            elevation: 0,
                          ),
                        ),
                      ),
                      if (_pickedXFile != null && _imageBytes != null) ...[
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _pickedXFile!.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'ประเภทบอร์ดเกม',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_typesList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Column(
                          children: List.generate(_typesList.length, (index) {
                            final typeItem = _typesList[index];
                            final isSelected = dialogCheckboxValues[index];
                            final String typeName =
                                typeItem['catagory_bg_name'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    dialogCheckboxValues[index] =
                                        value ?? false;
                                  });
                                },
                                title: Text(
                                  typeName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: Colors.blue,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
                                ),
                                dense: true,
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context, null);
                  },
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD49A32),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();

                    List<int> selectedCategoryId = [];
                    for (int i = 0; i < _typesList.length; i++) {
                      if (i < dialogCheckboxValues.length &&
                          dialogCheckboxValues[i]) {
                        final catId =
                            _typesList[i]['catagory_bg_id'] ??
                            _typesList[i]['boardgame_type_id'];
                        if (catId != null) {
                          selectedCategoryId.add(int.parse(catId.toString()));
                        }
                      }
                    }
                    Navigator.pop(context, selectedCategoryId);
                  },
                  child: const Text(
                    'บันทึก',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != null && confirm is List<int>) {
      final newName = nameController.text.trim();
      final newQuantity = int.tryParse(quantityController.text.trim()) ?? 0;
      final newPrice = double.tryParse(priceController.text.trim()) ?? 0.0;
      final List<int> selectedCategoryId = confirm;
      if (newName.isNotEmpty) {
        await _updateboardgamesell(
          bgId: bgsellid,
          bgName: newName,
          quantity: newQuantity,
          price: newPrice,
          categoryIds: selectedCategoryId,
          imageFile: _pickedXFile,
        );
      }
    }
  }

  // function แก้ไขข้อมูล
  Future<void> _updateboardgamesell({
    required int bgId,
    required String bgName,
    required int quantity,
    required double price,
    required List<int> categoryIds,
    XFile? imageFile,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUri}/boardgame/update-bgsell');
      final request = http.MultipartRequest('PUT', uri);
      request.fields['bg_id'] = bgId.toString();
      request.fields['bg_name'] = bgName;
      request.fields['quantity'] = quantity.toString();
      request.fields['price'] = price.toString();
      request.fields['category_id'] = jsonEncode(categoryIds);

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'sell_img',
          bytes,
          filename: imageFile.name,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['isError'] == false) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จ')));
          _fetchbgsell();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${resData['errorMessage']}'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      print("Error updating boardgame sale: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  // 3. แสดง Dialog ยืนยันการลบ
  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final int bgsellid = item['bg_id'] ?? item['bgs_id'] ?? 0;
    final String bgsellName = item['bgsell_name'] ?? item['bg_name'] ?? '';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text('คุณต้องการลบบอร์ดเกม "$bgsellName" ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteType(bgsellid);
    }
  }

  // ส่ง API ลบข้อมูล
  Future<void> _deleteType(int id) async {
    try {
      final response = await AppAPI.post('/boardgame/delete-bgsell', {
        'bgs_id': id,
      });

      final jsonRes = jsonDecode(response.body);
      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลสำเร็จ')));
        }
        _fetchbgsell();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถลบได้'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error deleting type: $e");
    }
  }

  // 4.แสดง dialog เพิ่มจำนวนด้วยบาร์โค้ด
  Future<void> _showaddquantity() async {
    final TextEditingController barcodeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'เพิ่มรหัสบาร์โค้ดบอร์ดเกม',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8 > 400
                ? 400
                : MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'รหัสบาร์โค้ด',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: barcodeController,
                  autofocus: true,
                  inputFormatters: [LengthLimitingTextInputFormatter(13)],
                  decoration: InputDecoration(
                    hintText: 'กรอกรหัสบาร์โค้ด...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    final barcodeText = value.trim();
                    if (barcodeText.isNotEmpty) {
                      Navigator.pop(context, barcodeText);
                    }
                  },
                  onChanged: (value) {
                    if (value.trim().length == 13) {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context, value.trim());
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                FocusScope.of(context).unfocus();
                final barcodeText = barcodeController.text.trim();
                Navigator.pop(
                  context,
                  barcodeText.isNotEmpty ? barcodeText : null,
                );
              },
              child: const Text('ตกลง', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((barcode) {
      if (barcode != null && barcode is String && barcode.isNotEmpty) {
        _AddQuantitysell(barcode);
      }
    });
  }

  // ส่ง api เพิ่มจำนวน
  Future<void> _AddQuantitysell(String barcode) async {
    try {
      setState(() => _isLoading = true);

      final response = await AppAPI.post('/boardgame/addquantity-bgsell', {
        'barcode': barcode,
      });

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['isError'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(resData['data'] ?? 'เพิ่มจำนวนบอร์ดเกมสำเร็จ'),
              ),
            );
          }
          await _fetchbgsell();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: ${resData['errorMessage']}'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          _shownoaddquantity(barcode);
        }
      }
    } catch (e) {
      print("Error scanning barcode: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // dialog กรณีเพิ่มจำนวนสินค้าไม่ได้เพราะ barcode ไม่ถูกต้อง
  void _shownoaddquantity(String barcode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              SizedBox(width: 8),
              Text(
                'ไม่พบข้อมูลบาร์โค้ด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8 > 400
                ? 400
                : MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ไม่มีข้อมูลบาร์โค้ด "$barcode" นี้ในระบบ',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คุณต้องการไปยังหน้าเพิ่มข้อมูลบอร์ดเกมสำหรับขายหรือไม่?',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49A32),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                  context,
                  '/createboardgame',
                  arguments: {'initialType': 'sell_boardgame'},
                );
              },
              child: const Text(
                'ยืนยัน',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isManager = _currentRoleId == 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // หัวข้อ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายการบอร์ดเกมสำหรับขาย (boardgame for sell)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Container(
                  height: 42,
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อบอร์ดเกม...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterboardgamesell('');
                              },
                            )
                          : null,

                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      _filterboardgamesell(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _showaddquantity();
                  print("กดปุ่มเพิ่มบอร์ดเกมใหม่");
                },
                icon: const Icon(Icons.add, color: Colors.green),
                tooltip: 'เพิ่มจำนวนสินค้าในคลัง',
              ),
              IconButton(
                onPressed: _fetchbgsell,
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'รีเฟรชข้อมูล',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // รายการข้อมูล
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _bgsellList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('ไม่พบรายการบอร์ดเกม')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredboardgamesell.length,
                  itemBuilder: (context, index) {
                    final item = _filteredboardgamesell[index];
                    final String typeName = item['bg_name'] ?? '';
                    final String? imgicon = item['img_game_sale'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      color: const Color(0xFFF8F9FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imgicon != null && imgicon.isNotEmpty
                              ? Image.network(
                                  '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/boardgame/$imgicon',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(index),
                                )
                              : _buildDefaultAvatar(index),
                        ),
                        title: Text(
                          typeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        trailing: isManager
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => _showDetailDialog(item),
                                    tooltip: 'ดูรายละเอียด',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => _showEditDialog(item),
                                    tooltip: 'แก้ไข',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _showDeleteDialog(item),
                                    tooltip: 'ลบ',
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(int index) {
    return CircleAvatar(
      backgroundColor: Colors.amber.shade100,
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          color: Color(0xFFD49A32),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

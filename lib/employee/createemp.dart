import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

class Createemp extends StatefulWidget {
  const Createemp({super.key});

  @override
  State<Createemp> createState() => _CreateempState();
}

class _CreateempState extends State<Createemp> {
  String? _selectedSex;
  String? selectedRole_id;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  List<dynamic> _roleList = [];
  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  bool _isGenerating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchrole();
    _generateEmployeeId();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedXFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _generateEmployeeId() async {
    setState(() => _isGenerating = true);

    try {
      final response = await AppAPI.get('/emp/generate-id');

      if (response.statusCode == 200) {
        // 2. แปลง String JSON จาก body ให้เป็น Map
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == true) {
          final generatedId = data['emp_id']?.toString() ?? '';

          if (mounted) {
            setState(() {
              _userIdController.text = generatedId;
            });
          }
        } else {
          _showError(data['message'] ?? 'ไม่สามารถสร้างรหัสพนักงานได้');
        }
      } else {
        _showError('Server ตอบกลับรหัสข้อผิดพลาด: ${response.statusCode}');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 3, 3, 3),
      ),
    );
  }

  Future<void> _fetchrole() async {
    try {
      final response = await AppAPI.get('/emp/emp-role');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['isError'] == false && json['data'] != null) {
          if (mounted) {
            setState(() {
              _roleList = (json['data'] is List) ? json['data'] : [];
            });
          }
        }
      } else {
        debugPrint("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching roles: $e");
    }
  }

  Future<void> _submitemp() async {
    if (!_formkey.currentState!.validate()) {
      return;
    }

    final String userId = _userIdController.text.trim();
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String password = _passwordController.text.trim();
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    
    final String age = _ageController.text.trim();
    final String sex = _selectedSex ?? '';
    final String roleId = selectedRole_id ?? '';
    final String phone = _phoneController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อและนามสกุล')));
      return;
    }
    if (age.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกอายุ')));
      return;
    }
    if (sex.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเพศ')));
      return;
    }
    if (roleId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกตำแหน่ง')));
      return;
    }

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('ยืนยันข้อมูลการเพิ่ม'),
              content: Text(
                'คุณต้องการเพิ่มพนักงานชื่อ "$firstName $lastName" ใช่หรือไม่?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 167, 66),
                  ),
                  child: const Text(
                    'ยืนยัน',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted) return;
    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final uri = Uri.parse('${AppConfig.apiBaseUri}/emp/create-emp');
      var request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['user_id'] = userId;
      request.fields['emp_first_name'] = firstName;
      request.fields['emp_last_name'] = lastName;
      request.fields['password'] = passwordHash;
      request.fields['age'] = age;
      request.fields['tel'] = phone;
      request.fields['sex']=sex;
      request.fields['emp_role_id'] = roleId;

      if (_imageBytes != null && _pickedXFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'img_emp',
            _imageBytes!,
            filename: _pickedXFile!.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เพิ่มตัวเลือกใหม่สำเร็จ')),
          );
          _firstNameController.clear();
          _lastNameController.clear();
          _ageController.clear();
          _confirmPasswordController.clear();
          _passwordController.clear();
          _phoneController.clear();
          _generateEmployeeId();
          setState(() {
            selectedRole_id = null; 
            _selectedSex = null; 
            _pickedXFile = null;
            _imageBytes = null;
          });
        }
      }
      else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถบันทึกได้'}'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error creating option: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Form(
        key: _formkey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แบบฟอร์มเพิ่มพนักงาน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'รหัสพนักงาน',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _userIdController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'รหัสพนักงาน (สร้างอัตโนมัติ)',
                hintText: 'กำลังสุ่มรหัส...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                // แสดง Loading เล็กๆ หรือไอคอนกดสุ่มใหม่
                suffixIcon: _isGenerating
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'สุ่มรหัสใหม่',
                        onPressed: _generateEmployeeId,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ชื่อพนักงาน',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                hintText: 'ชื่อ',
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
            const Text(
              'นามสกุล',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                hintText: 'นามสกุล',
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
            const Text(
              'รหัสผ่านชั่วคราว',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'รหัสผ่านชั่วคราวขั้นต่ำ 10 ตัวอักษร',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกรหัสผ่านชั่วคราว';
                }
                if (value.length < 10) {
                  return 'รหัสผ่านชั่วคราวต้องมีอย่างน้อย 10 ตัวอักษร';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'รหัสผ่านชั่วคราว',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'ยืนยันรหัสผ่านชั่วคราว',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกรหัสผ่านชั่วคราว';
                }
                if (value.trim() != _passwordController.text.trim()) {
                  return "รหัสผ่านไม่ตรงกัน";
                }
                return null;
              },
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
                        'อายุ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          hintText: 'อายุ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เพศ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSex,
                        hint: const Text('เลือกเพศ'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ชาย', child: Text('ชาย')),
                          DropdownMenuItem(value: 'หญิง', child: Text('หญิง')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSex = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'เลือกตำแหน่ง',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedRole_id,
              hint: const Text('เลือกตำแหน่ง'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: (_roleList).map<DropdownMenuItem<String>>((role) {
                return DropdownMenuItem<String>(
                  value: role['emp_role_id']?.toString() ?? '',
                  child: Text(role['emp_role_name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedRole_id = val;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'กรอกเบอร์โทรศัพท์',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                hintText: 'เบอร์โทรศัพท์',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกเบอร์โทรศัพท์';
                }
                if (value.trim().length != 10) {
                  return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'รูปประกอบ (ถ้ามี)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.black87),
                  label: Text(
                    _pickedXFile == null ? 'เลือกรูปภาพ' : 'เปลี่ยนรูปภาพ',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                if (_pickedXFile != null)
                  const Text(
                    'เลือกไฟล์แล้ว',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _submitemp,
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
      ),
    );
  }
}

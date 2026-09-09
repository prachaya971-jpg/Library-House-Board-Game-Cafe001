import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:crypto/crypto.dart';
import 'package:cafa_boardgame/utils/date_util.dart';

class Listemp extends StatefulWidget {
  final int? roleId;

  const Listemp({super.key, this.roleId});

  @override
  State<Listemp> createState() => _ListempState();
}

class _ListempState extends State<Listemp> {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _empList = [];
  List<dynamic> _filteredempList = [];
  List<dynamic> _roleList = [];
  int _currentRoleId = 2;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _fetchemp();
    _fetchrole();
  }

  void _filteremp(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredempList = List.from(_empList);
      } else {
        _filteredempList = _filteredempList.where((emp) {
          final userid = emp['user_id']?.toString().toLowerCase() ?? '';
          final fullname = emp['full_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return userid.contains(searchLower) || fullname.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<Map<String, String>?> _showResetPasswordDialog(
    String targetEmpName,
  ) async {
    final formKey = GlobalKey<FormState>();

    final currentPasswordController = TextEditingController();
    final newTempPasswordController = TextEditingController();
    final confirmNewTempPasswordController = TextEditingController();

    InputDecoration inputStyle({required String hint, required IconData icon}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 24,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromARGB(255, 104, 104, 104),
            width: 1.5,
          ),
        ),
      );
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Text(
          'ยืนยันการรีเซ็ตรหัสผ่านของ $targetEmpName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  autofocus: true,
                  obscureText: true,
                  decoration: inputStyle(
                    hint: 'กรอกรหัสผ่านของคุณเพื่อยืนยัน',
                    icon: Icons.lock_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "กรุณากรอกรหัสผ่านของคุณ";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newTempPasswordController,
                  obscureText: true,
                  decoration: inputStyle(
                    hint: 'ตั้งรหัสผ่านใหม่ชั่วคราว (ขั้นต่ำ 10 ตัว)',
                    icon: Icons.vpn_key_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "กรุณากรอกรหัสผ่านใหม่ชั่วคราว";
                    }
                    if (value.trim().length < 10) {
                      return "รหัสผ่านต้องมีความยาวอย่างน้อย 10 ตัวอักษร";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmNewTempPasswordController,
                  obscureText: true,
                  decoration: inputStyle(
                    hint: 'ยืนยันรหัสผ่านใหม่ชั่วคราว',
                    icon: Icons.vpn_key_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "กรุณากรอกยืนยันรหัสผ่านใหม่ชั่วคราว";
                    }
                    if (value.trim() != newTempPasswordController.text.trim()) {
                      return "รหัสผ่านไม่ตรงกัน";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 6, 6, 6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, {
                  'myPassword': currentPasswordController.text.trim(),
                  'newTempPassword': newTempPasswordController.text.trim(),
                  'confirmNewTempPassword': confirmNewTempPasswordController
                      .text
                      .trim(),
                });
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<Map<String, dynamic>> _accessRequest(
    String currentUserId,
    String myPassword,
  ) async {
    try {
      final now = DateTime.now();
      final formattedDate = DateUtil().getFormattedDate(now);
      final rawAuthenString = "$currentUserId&$formattedDate";
      final authenRequestSignature = sha256
          .convert(utf8.encode(rawAuthenString))
          .toString();

      // 1. ขอ authen_token
      final authenRes = await http.post(
        Uri.parse("${AppConfig.apiBaseUri}/authen/authen_request"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'authen_request': authenRequestSignature}),
      );

      final authenJson = jsonDecode(authenRes.body);
      if (authenJson["isError"] == true) {
        return {
          'isValid': false,
          'errorMessage': authenJson["errorMessage"] ?? "ยืนยันตัวตนไม่สำเร็จ",
        };
      }

      final String authenToken = authenJson["data"];

      // 2. ยืนยันรหัสผ่าน
      final passwordEncode = sha256.convert(utf8.encode(myPassword)).toString();
      final combinedSignatureString =
          "$currentUserId&$passwordEncode&$authenToken";
      final accessSignature = sha256
          .convert(utf8.encode(combinedSignatureString))
          .toString();

      final accessRes = await http.post(
        Uri.parse("${AppConfig.apiBaseUri}/authen/access_request"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'authen_signature': accessSignature,
          'authen_token': authenToken,
        }),
      );

      final accessJson = jsonDecode(accessRes.body);
      if (accessJson["isError"] == true) {
        return {
          'isValid': false,
          'errorMessage':
              accessJson["errorMessage"] ?? "รหัสผ่านของคุณไม่ถูกต้อง",
        };
      }

      return {'isValid': true, 'errorMessage': null};
    } catch (e) {
      return {
        'isValid': false,
        'errorMessage': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
      };
    }
  }

  Future<bool> _sendResetPasswordRequest(
    int empId,
    String newPasswordHash,
  ) async {
    final response = await AppAPI.post('/emp/update-emp-status', {
      'emp_id': empId,
      'new_temp_password': newPasswordHash,
    });

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['isError'] == false) {
      return true;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาด: ${json['errorMessage'] ?? 'ไม่สามารถอัปเดตได้'}',
            ),
            backgroundColor: const Color.fromARGB(255, 9, 9, 9),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _updataeemppass(Map<String, dynamic> item) async {
    final int targetEmpId = item['emp_id'] ?? 0;
    final String firstName = item['emp_first_name'] ?? '';
    final String lastName = item['emp_last_name'] ?? '';
    final String targetEmpName = '$firstName $lastName'.trim();

    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('token');

    if (currentToken == null || JwtDecoder.isExpired(currentToken)) {
      if (mounted)
        _showErrorDialog(context, "เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่");
      return;
    }

    final Map<String, dynamic> decodedToken = JwtDecoder.decode(currentToken);
    final String currentUserId = decodedToken['user_id']?.toString() ?? '';

    final resultPasswords = await _showResetPasswordDialog(targetEmpName);
    if (resultPasswords == null) return;

    final String myPassword = resultPasswords['myPassword']?.trim() ?? '';
    final String newTempPassword =
        resultPasswords['newTempPassword']?.trim() ?? '';
    final newPasswordHash = sha256
        .convert(utf8.encode(newTempPassword.trim()))
        .toString();

    BuildContext? loadingDialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loadingDialogContext = ctx;
        return const Center(
          child: CircularProgressIndicator(color: Colors.black),
        );
      },
    );

    try {
      // 2. ตรวจสอบรหัสผ่าน
      final verifyResult = await _accessRequest(currentUserId, myPassword);

      if (loadingDialogContext != null &&
          Navigator.canPop(loadingDialogContext!)) {
        Navigator.pop(loadingDialogContext!);
        loadingDialogContext = null;
      }

      if (verifyResult['isValid'] == false) {
        if (mounted) {
          _showErrorDialog(
            context,
            verifyResult['errorMessage'] ?? "รหัสผ่านไม่ถูกต้อง",
          );
        }
        return;
      }

      final bool isSuccess = await _sendResetPasswordRequest(
        targetEmpId,
        newPasswordHash,
      );
      print("newPassword: $newPasswordHash");

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('รีเซ็ตรหัสผ่านของ $targetEmpName เรียบร้อยแล้ว'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
        _fetchemp();
      }
    } catch (e) {
      if (loadingDialogContext != null &&
          Navigator.canPop(loadingDialogContext!)) {
        Navigator.pop(loadingDialogContext!);
      }
      debugPrint("Error in _updataeemp: $e");
      if (mounted) {
        _showErrorDialog(context, 'เกิดข้อผิดพลาด: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ยืนยันไม่สำเร็จ"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ตกลง"),
            ),
          ],
        );
      },
    );
  }

  // ดึงข้อมูล Role จาก Token
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

  // 1. ดึงรายการ Option ทั้งหมด
  Future<void> _fetchemp() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/emp/emp');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _empList = json['data'] ?? [];
            _filteredempList = List.from(_empList);
          });
        }
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching emp: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. แสดง Dialog ยืนยันการลบ
  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
  final int empId = item['emp_id'] ?? 0;
  final String empName = item['full_name'] ?? item['emp_first_name'] ?? '';

  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('ยืนยันการลบข้อมูล'),
        content: Text('คุณต้องการลบพนักงานชื่อ "$empName" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );

  if (confirm == true && mounted) {
    await _deleteemp(empId);
  }
}

  // ส่ง API ลบข้อมูล
  Future<void> _deleteemp(int id) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(color: Colors.amber),
    ),
  );

  try {
    final response = await AppAPI.post('/emp/delete-emp', {'emp_id': id});

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final jsonRes = jsonDecode(response.body);
    if (!mounted) return;

    if (response.statusCode == 200 && jsonRes['isError'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบข้อมูลสำเร็จ'),
          backgroundColor: Colors.black,
        ),
      );

      await _fetchemp();
    } else {
      String rawError = jsonRes['errorMessage']?.toString() ?? '';
      String displayError = 'เกิดข้อผิดพลาด: $rawError';

      if (rawError.contains('1451') ||
          rawError.contains('foreign key constraint fails') ||
          rawError.contains('ER_ROW_IS_REFERENCED')) {
        displayError = 'ไม่สามารถลบได้ เนื่องจากมีประวัติการทำรายการในระบบแล้ว';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayError),
          backgroundColor: const Color.fromARGB(255, 2, 2, 2),
        ),
      );
    }
  } catch (e) {
    // ปิดตัวหมุนโหลดเมื่อมี Exception
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }
}

  // 3. แสดง Dialog ยืนยันการลบ
  Future<void> _showupdatestatusDialog(Map<String, dynamic> item) async {
    final int empId = item['emp_id'] ?? 0;
    final String empName = item['full_name'];
    final String empStatus = item['emp_status_id'];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการอัปเดตสถานะ'),
          content: Text(
            'คุณต้องการอัปเดตสถานะพนักงานชื่อ "$empName" ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 250, 92, 0),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'อัปเดต',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _updateempstatus(empId, empStatus);
    }
  }

  // ส่ง API อัปเดตสถานะ
  Future<void> _updateempstatus(int id, String status) async {
    try {
      final response = await AppAPI.post('/emp/update-emp-newstatus', {
        'emp_id': id,
        ' ': status,
      });

      final jsonRes = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && jsonRes['isError'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตสถานะสำเร็จ'),
            backgroundColor: Colors.black,
          ),
        );
        _fetchemp();
      } else {
        String rawError = jsonRes['errorMessage']?.toString() ?? '';
        String displayError = 'เกิดข้อผิดพลาด: $rawError';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayError),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  Future<void> _fetchrole() async {
    try {
      final response = await AppAPI.get('/emp/emp-role');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            _roleList = (json['data'] is List) ? json['data'] : [];
          });
        }
      } else {
        debugPrint("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching roles: $e");
    }
  }

  // 2. แสดง Dialog แก้ไขรายการ Option/Employee
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final int emp_id = item['emp_id'] ?? 0;
    final String user_id = item['user_id']?.toString() ?? '';
    final String emp_first_name = item['emp_first_name']?.toString() ?? '';
    final String emp_last_name = item['emp_last_name']?.toString() ?? '';

    final TextEditingController fistnameController = TextEditingController(
      text: emp_first_name,
    );
    final TextEditingController lastnameController = TextEditingController(
      text: emp_last_name,
    );
    final TextEditingController ageController = TextEditingController(
      text: item['age']?.toString() ?? '',
    );
    final TextEditingController telController = TextEditingController(
      text: item['tel']?.toString() ?? '',
    );

    final TextEditingController sexController = TextEditingController(
      text: item['sex']?.toString() ?? '',
    );

    final currentRoleId = item['emp_role_id']?.toString();
    final bool hasMatchRole = _roleList.any(
      (role) => role['emp_role_id']?.toString() == currentRoleId,
    );
    String? selectedRole_id = hasMatchRole ? currentRoleId : null;

    XFile? pickedXFile;
    Uint8List? imageBytes;
    final ImagePicker picker = ImagePicker();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'แก้ไขข้อมูลพนักงาน รหัส $user_id ($emp_first_name $emp_last_name)',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ชื่อพนักงาน',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: fistnameController,
                      decoration: InputDecoration(
                        hintText: 'กรอกชื่อพนักงาน',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'นามสกุลพนักงาน',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: lastnameController,
                      decoration: InputDecoration(
                        hintText: 'กรอกนามสกุลพนักงาน',
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
                      'อายุ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'กรอกอายุ',
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
                      'เบอร์โทรศัพท์',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: telController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: 'กรอกเบอร์โทรศัพท์',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const Text(
                      'เพศ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: sexController.text.isNotEmpty
                          ? sexController.text
                          : null,
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
                          sexController.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาเลือกเพศ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ตำแหน่ง*',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                      items: _roleList.map<DropdownMenuItem<String>>((role) {
                        return DropdownMenuItem<String>(
                          value: role['emp_role_id']?.toString() ?? '',
                          child: Text(role['emp_role_name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedRole_id = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'เปลี่ยนรูปภาพ (ถ้ามี)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? file = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (file != null) {
                              final bytes = await file.readAsBytes();
                              setDialogState(() {
                                pickedXFile = file;
                                imageBytes = bytes;
                              });
                            }
                          },
                          icon: const Icon(Icons.image, size: 18),
                          label: Text(
                            pickedXFile == null
                                ? 'เลือกรูปภาพใหม่'
                                : 'เปลี่ยนรูปภาพ',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pickedXFile != null)
                          const Expanded(
                            child: Text(
                              'เลือกไฟล์ใหม่แล้ว',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
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
                    if (selectedRole_id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณาเลือกตำแหน่งพนักงาน'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
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

    if (confirm == true) {
      final int finalAge =
          int.tryParse(ageController.text.trim()) ?? (item['age'] ?? 0);
      final String finalFirstName = fistnameController.text.trim().isNotEmpty
          ? fistnameController.text.trim()
          : emp_first_name;
      final String finalLastName = lastnameController.text.trim().isNotEmpty
          ? lastnameController.text.trim()
          : emp_last_name;

      await _updateEmployee(
        id: emp_id,
        firstName: finalFirstName,
        lastName: finalLastName,
        age: finalAge,
        tel: telController.text.trim(),
        sex: sexController.text.trim(),
        emprole: selectedRole_id ?? currentRoleId ?? '1',
        imageBytes: imageBytes,
        pickedXFile: pickedXFile,
      );
    }
  }

  // ส่ง API แก้ไขข้อมูล Employee
  Future<void> _updateEmployee({
    required int id,
    required String firstName,
    required String lastName,
    required int age,
    required String tel,
    required String sex,
    required String emprole,
    Uint8List? imageBytes,
    XFile? pickedXFile,
  }) async {
    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final uri = Uri.parse('${AppConfig.apiBaseUri}/emp/update-emp');
      var request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['emp_id'] = id.toString();
      request.fields['emp_first_name'] = firstName;
      request.fields['emp_last_name'] = lastName;
      request.fields['age'] = age.toString();
      request.fields['tel'] = tel;
      request.fields['sex'] = sex;
      request.fields['emp_role_id'] = emprole;

      if (imageBytes != null && pickedXFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'img_emp',
            imageBytes,
            filename: pickedXFile.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final jsonRes = jsonDecode(response.body);

      if (response.statusCode == 200 && !jsonRes['isError']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขข้อมูลพนักงานสำเร็จ'),
              backgroundColor: Color.fromARGB(255, 2, 2, 2),
            ),
          );
        }
        _fetchemp();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถแก้ไขได้'}',
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating employee: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                'รายการพนักงาน',
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
                      hintText: 'ค้นหาพนักงาน...',
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
                                _filteremp('');
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
                      _filteremp(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _fetchemp,
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
              : _empList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('ไม่พบรายการพนักงาน')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredempList.length,
                  itemBuilder: (context, index) {
                    final item = _filteredempList[index];
                    final String userid = item['user_id']?.toString() ?? '';
                    final String empfirstName =
                        item['emp_first_name']?.toString() ?? '-';
                    final String emplastName =
                        item['emp_last_name']?.toString() ?? '-';
                    final String age = item['age']?.toString() ?? '-';
                    final String sex = item['sex']?.toString() ?? '-';
                    final String tel = item['tel']?.toString() ?? '-';
                    final String empRole =
                        item['emp_role_name']?.toString() ?? 'พนักงาน';
                    final double salary =
                        double.tryParse(item['salary']?.toString() ?? '0') ?? 0;
                    final String passwordStatus =
                        item['password_status_name']?.toString() ?? '';
                    final String? imgName = item['img_emp'];
                    final String empstid =
                        item['emp_status_id']?.toString() ?? '-';
                    final String empstatus =
                        item['emp_status_name']?.toString() ?? '-';
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
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imgName != null && imgName.isNotEmpty
                              ? Image.network(
                                  '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/emp/$imgName',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(index),
                                )
                              : _buildDefaultAvatar(index),
                        ),
                        // 1. ส่วนหัวข้อ: แสดงชื่อ, รหัส และป้ายตำแหน่ง
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$empfirstName $emplastName (#$userid)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                empRole,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: empstid == 'Y'
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: empstid == 'Y'
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                'สถานะ: $empstatus',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: empstid == 'Y'
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เพศ: $sex  |  อายุ: $age ปี  |  โทร: $tel',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'เงินเดือน: ฿${salary.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (passwordStatus.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Text(
                                      '•สถานะบัญชี $passwordStatus',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: passwordStatus.contains('ตั้ง')
                                            ? Colors.grey.shade600
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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
                                    onPressed: () => const Text("5555"),
                                    tooltip: 'ดูรายละเอียด',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.lock_reset,
                                      color: Colors.purple,
                                      size: 20,
                                    ),
                                    onPressed: () => _updataeemppass(item),
                                    tooltip: 'รีเซ็ตรหัสผ่าน',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    onPressed: () => _showEditDialog(item),
                                    tooltip: 'แก้ไข',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _showDeleteDialog(item),
                                    tooltip: 'ลบ',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.no_accounts_outlined,
                                      color: Color.fromARGB(255, 250, 79, 0),
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showupdatestatusDialog(item),
                                    tooltip: 'เปลี่ยนสถานะพนักงาน',
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

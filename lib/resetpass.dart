import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:cafa_boardgame/utils/appapi.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';


class ResetPass extends StatefulWidget {
  const ResetPass({super.key});

  @override
  _ResetPassState createState() => _ResetPassState();
}

class _ResetPassState extends State<ResetPass> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

 Future<bool> _resetPassword(String newPassword, int empId) async {
  try {
    final response = await AppAPI.post('/emp/reset-password-status', {
      'emp_id': empId,
      'new_password': newPassword,
    });
    if (response.statusCode == 200) {
      return true;
    } else {
      print("เปลี่ยนรหัสผ่านไม่สำเร็จ: ${response.body}");
      return false;
    }
  } catch (e) {
    print("เกิดข้อผิดพลาด: $e");
    return false;
  }
}
 void _doLogin(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(color: Colors.amber),
    ),
  );
   
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final String empId = decodedToken['emp_id']?.toString() ?? '';
    final newPassword = _newPasswordController.text.trim();
    final newpasswordHash = sha256.convert(utf8.encode(newPassword)).toString();
    
    final bool isSuccess = await _resetPassword(newpasswordHash, int.parse(empId));

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); 

    if (isSuccess) {
      _showsuccessDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนรหัสผ่านไม่สำเร็จ กรุณาลองใหม่อีกครั้ง')),
      );
    }

  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
  }
}

void _showsuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Text("ยืนยันการเปลี่ยนรหัสผ่าน"),
        content: const Text("ดำเนินการสำเร็จเรียบร้อยแล้ว"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text("ตกลง"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/1.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "เปลี่ยนรหัสผ่าน",
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                textAlign: TextAlign.center,
              ),

              Container(
                height: 400,
                width: 600,
                margin: const EdgeInsets.only(top: 50, left: 30, right: 30),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
                child: Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.vpn_key_outlined,
                              color: Color.fromARGB(136, 0, 0, 0),
                            ),

                            hintText: "รหัสผ่านใหม่",
                            hintStyle: TextStyle(
                              color: Color.fromARGB(100, 0, 0, 0),
                            ),

                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(136, 0, 0, 0),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 0, 0, 0),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "กรุณากรอกรหัสผ่านใหม่";
                            }
                            if (value.trim().length < 10) {
                              return "รหัสผ่านต้องมีความยาวอย่างน้อย 10 ตัวอักษร";
                            }
                            final englishLettersCount = RegExp(r'[a-zA-Z]').allMatches(value.trim()).length;
                            if (englishLettersCount < 3) {
                              return "รหัสผ่านต้องมีตัวอักษรภาษาอังกฤษอย่างน้อย 3 ตัว";
                            }
                            return null;
                          },
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.only(top: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: TextFormField(
                          obscureText: true,
                          controller: _confirmPasswordController,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.vpn_key_outlined,
                              color: Color.fromARGB(137, 0, 0, 0),
                            ),

                            hintText: "ยืนยันรหัสผ่าน",
                            hintStyle: TextStyle(
                              color: Color.fromARGB(100, 0, 0, 0),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(137, 0, 0, 0),
                              ),
                            ),

                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 0, 0, 0),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "กรุณากรอกยืนยันรหัสผ่าน";
                            }
                            if (value.trim() !=
                                _newPasswordController.text.trim()) {
                              return "รหัสผ่านไม่ตรงกัน";
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 30),
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF1A1A1A),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            if (_formkey.currentState!.validate()) {
                              _doLogin(context);
                            }
                          },
                          child: const Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

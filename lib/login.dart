import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:cafa_boardgame/utils/date_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'employeemoule/orders.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}



class _LoginState extends State<Login> {
  final _formkey = GlobalKey<FormState>();
  final _empidValueController = TextEditingController();
  final _passwordValueController = TextEditingController();

Future <(bool,String,String)> _authenRequest() async{
  String empid = _empidValueController.text;
  DateTime now = DateTime.now();
  String formattedDateString = DateUtil().getFormattedDate (now);

  String comdinedSring = "$empid&$formattedDateString";
  print(comdinedSring);

  String _authenRequestStrig = sha256
  .convert(utf8.encode(comdinedSring)).
  toString();

  print(_authenRequestStrig);

  final response = await http.post(
    Uri.parse("${AppConfig.apiBaseUri}/authen/authen_request"),
    headers:<String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'authen_request': _authenRequestStrig}),
  );

  final json =jsonDecode(response.body);

  print(json);

  return(
    json["isError"]as bool,
    json["data"] as String,
    json["errorMessage"] as String,
  );
}



 Future<({bool isError, String data, String errorMessage})> _accessRequest(
    String authenToken,
  ) async {
      String empid = _empidValueController.text;
      String password = _passwordValueController.text;
      String passwordEncode = sha256.convert(utf8.encode(password)).toString();
      String combinedString = "$empid&$passwordEncode&$authenToken";
      String authenSignature = sha256.convert(utf8.encode(combinedString)).toString();

      final response = await http.post(
        Uri.parse("${AppConfig.apiBaseUri}/authen/access_request"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'authen_signatrue': authenSignature,
          'authen_token': authenToken,
        }),
      );

      final json = jsonDecode(response.body);
      print("Access Request Response: $json");

       if (!json["isError"]) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', json["data"]["access_token"]);
        await prefs.setString('empid', _empidValueController.text);
      }
      return (
        isError: json["isError"] as bool,
        data: json["data"]["access_token"] as String,
        errorMessage: json["errorMessage"] as String,
      );
     
  }

void _doLogin(BuildContext context) async {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

   
    var (isError, authenToken, errorMessage) = await _authenRequest();

    if (isError) {
      Navigator.pop(context); 
      _showErrorDialog(context, errorMessage);
    } else {
      
      var (:isError, :data, :errorMessage) = await _accessRequest(authenToken);
      Navigator.pop(context); 

      if (isError) {
        _showErrorDialog(context, errorMessage);
      } else {
        
        Map<String, dynamic> decodedToken = JwtDecoder.decode(data);
        int roleId = decodedToken['emp_role_id'] ?? 1;

        
        Widget targetPage;
        if (roleId == 2) {
          targetPage = const Scaffold(body: Center(child: Text(".............."))); 
        } else {
          targetPage = const Scaffold(body: Center(child: Text("................")));
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        }
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("เข้าสู่ระบบไม่สำเร็จ"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ตกลง"),
            )
          ],
        );
      },
    );
  }

  // It's good practice to dispose of controllers to prevent memory leaks
  @override
  void dispose() {
    _empidValueController.dispose();
    _passwordValueController.dispose();
    super.dispose();
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
                "Library House Board Game Cafe",
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
                          controller: _empidValueController,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Color.fromARGB(136, 0, 0, 0),
                            ),

                            hintText: "หมายเลขพนักงาน",
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
                              return "กรุณากรอกหมายเลขพนักงานของคุณ";
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
                          controller: _passwordValueController,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color.fromARGB(137, 0, 0, 0),
                            ),

                            hintText: "Password",
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
                              return "กรุณากรอกรหัสผ่านของคุณ";
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                        ), 
                        width: double
                            .infinity, 
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Colors.white, 
                            backgroundColor: const Color(
                              0xFF1A1A1A,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ), 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                15,
                              ), 
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
                              letterSpacing:
                                  2, 
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

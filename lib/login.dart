import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formkey = GlobalKey<FormState>();
  final _usernameValueController = TextEditingController();
  final _passwordValueController = TextEditingController();

  // It's good practice to dispose of controllers to prevent memory leaks
  @override
  void dispose() {
    _usernameValueController.dispose();
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
                          controller: _usernameValueController,
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
                              // จัดการต่อเมื่อกดปุ่มสำเร็จ
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

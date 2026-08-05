import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../app_sidebar.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';

class OrderraelScreen extends StatefulWidget {
  const OrderraelScreen({Key? key}) : super(key: key);

  @override
  State<OrderraelScreen> createState() => _OrderraelScreenState();
}

class _OrderraelScreenState extends State<OrderraelScreen> {
  int roleId = 1;

  @override
  void initState() {
    super.initState();
    _loadRoleFromToken();
  }

  Future<void> _loadRoleFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      setState(() {
        roleId = decodedToken['emp_role_id'] ?? 1;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      body: Row(
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "ออร์เดอร์"),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "รายการออร์เดอร์",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 31, 41, 55),
                    ),
                  ),
            
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

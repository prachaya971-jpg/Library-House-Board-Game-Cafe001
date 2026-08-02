import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'app_sidebar.dart';
import 'package:cafa_boardgame/dashdorad/revenue_card.dart';
import 'package:cafa_boardgame/dashdorad/OrderCountCard.dart';
import 'package:cafa_boardgame/dashdorad/adviceCountCard.dart';
import 'package:cafa_boardgame/dashdorad/borrowcountCard.dart';
import 'package:cafa_boardgame/dashdorad/RevenueBarChart.dart';
import 'package:cafa_boardgame/dashdorad/listtopproduct.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int roleId = 1;
  bool isLoading = true;

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
      resizeToAvoidBottomInset: false,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSidebar(currentRoleId: roleId, currentRouteName: "หน้าเเรก"),

          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(child: RevenueCard()),
                        SizedBox(width: 16), 
                        Expanded(child: OrderCountCard()),
                        SizedBox(width: 16),
                        Expanded(child: AdviceCountCard()),
                        SizedBox(width: 16),
                        Expanded(child: BorrowCountCard()),
                      ],
                    ),

                    SizedBox(height: 24),

                    // ส่วนกราฟแท่ง
                    RevenueBarChartCard(),

                    SizedBox(height: 24),
                    Listtopproduct(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

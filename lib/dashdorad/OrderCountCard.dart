import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart';

class OrderCountCard extends StatefulWidget {
  const OrderCountCard({super.key});

  @override
  State<OrderCountCard> createState() => _OrderCountCardState();
}

class _OrderCountCardState extends State<OrderCountCard> {
  int _orderCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderCount();
  }

  Future<void> _fetchOrderCount() async {
    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final uri = Uri.parse('${AppConfig.apiBaseUri}/reports/order-count');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      final json = jsonDecode(response.body);

      if (!json['isError']) {
        setState(() {
          var rawCount = json['data']['total_orders'];
          if (rawCount is int) {
            _orderCount = rawCount;
          } else if (rawCount is String) {
            _orderCount = int.tryParse(rawCount) ?? 0;
          } else {
            _orderCount = 0;
          }
        });
      }
    } catch (e) {
      print("Error fetching order count: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      constraints: const BoxConstraints(
        minHeight: 180, 
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อการ์ด
          const Text(
            "รายการออเดอร์",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),

          // ส่วนแสดงผลข้อมูล
          Center(
            child: _isLoading
                ? const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(color: Color(0xFF6E8B7E)),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_orderCount == 0) {
      return const Text(
        "ยังไม่มีการสั่ง",
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          "$_orderCount",
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          "รายการ", // หรือใช้คำว่า "ออเดอร์"
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

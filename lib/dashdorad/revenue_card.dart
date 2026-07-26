import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafa_boardgame/config/app_config.dart'; // ปรับ path ตามโปรเจกต์คุณ

class RevenueCard extends StatefulWidget {
  const RevenueCard({super.key});

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard> {
  String _selectedPeriod = 'daily';     // 'daily', 'monthly', 'yearly'
  String _selectedCategory = 'food';    // 'all', 'food', 'boardgame'

  num _totalRevenue = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRevenue();
  }

  Future<void> _fetchRevenue() async {
  setState(() => _isLoading = true);

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final uri = Uri.parse('${AppConfig.apiBaseUri}/reports/revenue').replace(
      queryParameters: {
        'period': _selectedPeriod,
        'category': _selectedCategory,
      },
    );

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
        // 🟢 แปลงค่าไม่ว่าจะส่งมาเป็น String, int หรือ double ให้เป็น num อย่างปลอดภัย
        var rawRevenue = json['data']['total_revenue'];
        if (rawRevenue is String) {
          _totalRevenue = num.tryParse(rawRevenue) ?? 0;
        } else if (rawRevenue is num) {
          _totalRevenue = rawRevenue;
        } else {
          _totalRevenue = 0;
        }
      });
    }
  } catch (e) {
    print("Error fetching revenue: $e");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Row บน: หัวข้อ "รายได้" และ Dropdown เลือกช่วงเวลา
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "รายได้",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              _buildCustomDropdown(
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text("รายวัน")),
                  DropdownMenuItem(value: 'monthly', child: Text("รายเดือน")),
                  DropdownMenuItem(value: 'yearly', child: Text("รายปี")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPeriod = val);
                    _fetchRevenue();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dropdown เลือกประเภทรายการ
          _buildCustomDropdown(
            value: _selectedCategory,
            items: const [
              DropdownMenuItem(value: 'all', child: Text("ทั้งหมด")),
              DropdownMenuItem(value: 'food', child: Text("อาหาร")),
              DropdownMenuItem(value: 'boardgame', child: Text("บอร์ดเกม")),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCategory = val);
                _fetchRevenue();
              }
            },
          ),
          const SizedBox(height: 12),

          // ตัวเลขแสดงยอดรวมรายได้
          Center(
            child: _isLoading
                ? const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(color: Color(0xFF6E8B7E)),
                  )
                : Text(
                    "$_totalRevenue",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EBE6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4A6B5D)),
          style: const TextStyle(
            color: Color(0xFF4A6B5D),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
// revenue_card.dart (ปรับปรุง UI)
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cafa_boardgame/utils/appapi.dart';

class RevenueCard extends StatefulWidget {
  const RevenueCard({super.key});

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard> {
  String _selectedPeriod = 'daily';
  String _selectedCategory = 'food';
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
      final queryString = '/reports/revenue?period=$_selectedPeriod&category=$_selectedCategory';
      final response = await AppAPI.get(queryString);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!json['isError']) {
          setState(() {
            var raw = json['data']['total_revenue'];
            _totalRevenue = (raw is num) ? raw : (double.tryParse('$raw') ?? 0);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching revenue: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_rounded, color: Color(0xFF059669), size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "ยอดรายได้",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              _buildMiniDropdown<String>(
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _buildMiniDropdown<String>(
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: 'all', child: Text("ทุกหมวดหมู่")),
                DropdownMenuItem(value: 'food', child: Text("อาหาร/เครื่องดื่ม")),
                DropdownMenuItem(value: 'boardgame', child: Text("บอร์ดเกม")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                  _fetchRevenue();
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF059669)),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      "฿",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormat('#,##0.00').format(_totalRevenue),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMiniDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
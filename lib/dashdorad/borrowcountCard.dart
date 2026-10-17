import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';

class BorrowCountCard extends StatefulWidget {
  const BorrowCountCard({super.key});

  @override
  State<BorrowCountCard> createState() => _BorrowCountCardState();
}

class _BorrowCountCardState extends State<BorrowCountCard> {
  int _borrowCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBorrowCount();
  }

  Future<void> _fetchBorrowCount() async {
    setState(() => _isLoading = true);

    try {
      final response = await AppAPI.get('/reports/borrow-count');
      final json = jsonDecode(response.body);

      if (!json['isError']) {
        setState(() {
          var rawCount = json['data']['total_borrows'];
          if (rawCount is int) {
            _borrowCount = rawCount;
          } else if (rawCount is String) {
            _borrowCount = int.tryParse(rawCount) ?? 0;
          } else {
            _borrowCount = 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching borrow count: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFD97706); // โทน Warm Amber

    return Container(
      width: 250,
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
          // แถวบน: Icon + Badge หมวดหมู่
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                ),
            
              ),
            ],
          ),
          const SizedBox(height: 16),

          // หัวข้อ
          const Text(
            "รายการยืมเล่นบอร์ดเกม",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),

          // ตัวเลขแสดงผล
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: accentColor,
                    ),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "$_borrowCount",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "รายการ",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
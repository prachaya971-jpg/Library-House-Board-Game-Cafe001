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
    //  ใช้ AppAPI.get ยิงไปยัง endpoint ได้สั้นๆ บรรทัดเดียว
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
    print("Error fetching borrow count: $e");
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
            "รายการการยืม",
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
    if (_borrowCount == 0) {
      return const Text(
        "ยังไม่มีรายการการยืม",
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
          "$_borrowCount",
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          "รายการ",
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

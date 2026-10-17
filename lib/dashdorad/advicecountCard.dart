import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';

class AdviceCountCard extends StatefulWidget {
  const AdviceCountCard({super.key});

  @override
  State<AdviceCountCard> createState() => _AdviceCountCardState();
}

class _AdviceCountCardState extends State<AdviceCountCard> {
  int _adviceCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAdviceCount();
  }

  Future<void> _fetchAdviceCount() async {
    setState(() => _isLoading = true);

    try {
      final response = await AppAPI.get('/reports/advice-count');
      final json = jsonDecode(response.body);

      if (!json['isError']) {
        setState(() {
          var rawCount = json['data']['total_advice'];
          if (rawCount is int) {
            _adviceCount = rawCount;
          } else if (rawCount is String) {
            _adviceCount = int.tryParse(rawCount) ?? 0;
          } else {
            _adviceCount = 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching advice count: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6366F1); // โทน Indigo

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
          // แถวบน: Icon + Badge
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
                  Icons.chat_bubble_outline_rounded,
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
            "รายการขอคำแนะนำ",
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
                      "$_adviceCount",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "ข้อความ",
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
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/socket_service.dart';

class Reqtablecard extends StatefulWidget {
  const Reqtablecard({super.key});

  @override
  State<Reqtablecard> createState() => _ReqtablecardState();
}

class _ReqtablecardState extends State<Reqtablecard> {
  int _tableRequestCount = 0;
  bool _isLoading = false;

  late final void Function(dynamic) _cardTableHandler;

  @override
  void initState() {
    super.initState();
    _fetchTableRequestCount();

    _cardTableHandler = (data) {
      if (mounted) {
        _fetchTableRequestCount();
      }
    };

    _bindSocketListener();
  }

  void _bindSocketListener() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.off('new_table_request', _cardTableHandler);
      socket.on('new_table_request', _cardTableHandler);

      if (!socket.connected) {
        socket.connect();
      }
    }
  }

  Future<void> _fetchTableRequestCount() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/table_requests/count');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['isError'] == false && json['data'] != null) {
          if (mounted) {
            setState(() {
              _tableRequestCount = int.tryParse(
                    json['data']['total_pending_requests']?.toString() ?? '0',
                  ) ??
                  0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching table request count: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    SocketService().socket?.off('new_table_request', _cardTableHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF0D9488); // โทน Teal

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
          // แถวบน: Icon Badge + ป้ายรอคิว
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
                  Icons.table_restaurant_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _tableRequestCount > 0
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_tableRequestCount > 0)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      _tableRequestCount > 0 ? "รอดำเนินการ" : "ยังไม่มี",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _tableRequestCount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // หัวข้อ
          const Text(
            "รายการขอเปิดโต๊ะ",
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
                      "$_tableRequestCount",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "โต๊ะ",
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
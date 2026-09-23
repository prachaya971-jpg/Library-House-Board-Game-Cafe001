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
  int  _tableRequestCount = 0;
  bool _isLoading = false;

  late final void Function(dynamic) _cardTableHandler;
  @override
  void initState() {
    super.initState();
    _fetchTableRequestCount();

    _cardTableHandler = (data) {
      print(" [Reqtablecard] Real-time Triggered: ${data['table_number']}");
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
  try {
    final response = await AppAPI.get('/table_requests/count');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json['isError'] == false && json['data'] != null) {
        if (mounted) {
          setState(() {
            _tableRequestCount = int.tryParse(
              json['data']['total_pending_requests']?.toString() ?? '0',
            ) ?? 0;
          });
        }
      }
    }
  } catch (e) {
    print("Error fetching table request count: $e");
  }
}

@override
  void dispose() {
    SocketService().socket?.off('new_table_request', _cardTableHandler);
    super.dispose();
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
            "รายการขอเปิดโต๊ะ",
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
    if (_tableRequestCount == 0) {
      return const Text(
        "ยังไม่มีขอเปิดโต๊ะ",
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
          "$_tableRequestCount",
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

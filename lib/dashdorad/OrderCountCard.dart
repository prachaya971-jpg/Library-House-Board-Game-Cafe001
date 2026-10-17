// order_count_card.dart (ปรับปรุง UI)
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:cafa_boardgame/socket_service.dart';

class OrderCountCard extends StatefulWidget {
  const OrderCountCard({super.key});

  @override
  State<OrderCountCard> createState() => _OrderCountCardState();
}

class _OrderCountCardState extends State<OrderCountCard> {
  int _orderCount = 0;
  bool _isLoading = false;
  late final void Function(dynamic) _cardTableHandler;

  @override
  void initState() {
    super.initState();
    _fetchOrderCount();
    _cardTableHandler = (data) {
      if (mounted) _fetchOrderCount();
    };
    _bindSocketListener();
  }

  void _bindSocketListener() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.off('new_order', _cardTableHandler);
      socket.on('new_order', _cardTableHandler);
      if (!socket.connected) socket.connect();
    }
  }

  Future<void> _fetchOrderCount() async {
    setState(() => _isLoading = true);
    try {
      final response = await AppAPI.get('/reports/order-count');
      final json = jsonDecode(response.body);
      if (!json['isError']) {
        setState(() {
          var rawCount = json['data']['total_orders'];
          _orderCount = (rawCount is int) ? rawCount : (int.tryParse('$rawCount') ?? 0);
        });
      }
    } catch (e) {
      debugPrint("Error fetching order count: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    SocketService().socket?.off('new_order', _cardTableHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF2563EB); // โทน Blue

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: accentColor, size: 22),
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
          const Text(
            "รายการออเดอร์",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: accentColor),
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "$_orderCount",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "ออเดอร์",
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
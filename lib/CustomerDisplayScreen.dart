import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cafa_boardgame/config/app_config.dart';

class CustomerDisplayScreen extends StatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  late IO.Socket socket;
  String currentStatus = 'STANDBY'; // 'STANDBY' หรือ 'SHOW_QR'
  String? qrPayload;
  double amount = 0.0;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io(AppConfig.socketUri, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.on('customer_display_update', (data) {
      if (mounted) {
        setState(() {
          currentStatus = data['status'] ?? 'STANDBY';
          if (currentStatus == 'SHOW_QR') {
            qrPayload = data['qrPayload'];
            amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          } else {
            qrPayload = null;
            amount = 0.0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: currentStatus == 'SHOW_QR'
                // 1. หน้าจอตอนแคชเชียร์คิดเงิน (แสดงยอด + QR Code)
                ? SingleChildScrollView(
                    key: const ValueKey('SHOW_QR'),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ยอดชำระทั้งหมด',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '฿${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // กล่องแสดง QR Code พร้อมเงาตกกระทบ
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                spreadRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: qrPayload != null && qrPayload!.isNotEmpty
                              ? QrImageView(
                                  data: qrPayload!,
                                  size: 260,
                                  version: QrVersions.auto,
                                  backgroundColor: Colors.white,
                                )
                              : const SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'สแกน QR ผ่านแอปธนาคารเพื่อชำระเงิน',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                // 2. หน้าจอต้อนรับ Standby (แสดงเมื่อยังไม่มีการคิดเงิน)
                : const Column(
                    key: ValueKey('STANDBY'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_esports_outlined,
                        size: 90,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'ยินดีต้อนรับสู่ คาเฟ่บอร์ดเกม',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'พร้อมให้บริการ ขอให้สนุกกับการเล่นเกม',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
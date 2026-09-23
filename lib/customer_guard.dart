import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class CustomerRouteGuard extends StatefulWidget {
  final Widget child;

  const CustomerRouteGuard({super.key, required this.child});

  @override
  State<CustomerRouteGuard> createState() => _CustomerRouteGuardState();
}

class _CustomerRouteGuardState extends State<CustomerRouteGuard> {
  bool _isChecking = true;
  bool _isAuthorized = false;
  String _deniedMessage = '';

  @override
  void initState() {
    super.initState();
    _verifyCustomerSession();
  }

  Future<void> _verifyCustomerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('customer_table_token');

      if (token == null || token.trim().isEmpty) {
        _denyAccess('กรุณาสแกน QR Code ประจำโต๊ะก่อนเข้าใช้งาน');
        return;
      }

      
      if (JwtDecoder.isExpired(token)) {
        _denyAccess('Session ของโต๊ะหมดอายุแล้ว กรุณาสแกนใหม่อีกครั้ง');
        return;
      }
      final decoded = JwtDecoder.decode(token);
      final status = decoded['table_status_id']?.toString();

      if (status != 'N') {
       _denyAccess('โต๊ะยังไม่พร้อมให้บริการหรือยังไม่ได้รับการอนุมัติ');
        return;
      }

      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _isChecking = false;
        });
      }
    } catch (e) {
      _denyAccess('เกิดข้อผิดพลาดในการตรวจสอบสิทธิ์');
    }
  }

  void _denyAccess(String message) {
    if (mounted) {
      setState(() {
        _isAuthorized = false;
        _isChecking = false;
        _deniedMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
   
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    
    if (!_isAuthorized) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_meals_outlined, color: Colors.redAccent, size: 70),
                const SizedBox(height: 16),
                Text(
                  _deniedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),    
              ],
            ),
          ),
        ),
      );
    }

   
    return widget.child;
  }
}
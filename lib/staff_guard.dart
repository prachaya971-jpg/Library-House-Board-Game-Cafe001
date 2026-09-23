import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class StaffRouteGuard extends StatefulWidget {
  final Widget child;

  const StaffRouteGuard({super.key, required this.child});

  @override
  State<StaffRouteGuard> createState() => _StaffRouteGuardState();
}

class _StaffRouteGuardState extends State<StaffRouteGuard> {
  bool _isChecking = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _verifyStaffSession();
  }

  Future<void> _verifyStaffSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.trim().isEmpty) {
        _kickToLogin();
        return;
      }


      if (JwtDecoder.isExpired(token)) {
        await prefs.remove('token');
        _kickToLogin();
        return;
      }

      
      final Map<String, dynamic> decoded = JwtDecoder.decode(token);
      final String? role = decoded['emp_role_id']?.toString();

      
      if (role != null && role != '1' && role != '2') {
        _kickToLogin();
        return;
      }

    
      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _isChecking = false;
        });
      }
    } catch (e) {
      _kickToLogin();
    }
  }

  void _kickToLogin() {
    if (mounted) {
      setState(() {
        _isAuthorized = false;
        _isChecking = false;
      });

      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
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

    return _isAuthorized ? widget.child : const SizedBox.shrink();
  }
}
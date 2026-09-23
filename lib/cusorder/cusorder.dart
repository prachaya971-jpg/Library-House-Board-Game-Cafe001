import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cafa_boardgame/config/app_config.dart';
import 'package:cafa_boardgame/utils/date_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'package:cafa_boardgame/socket_service.dart';

class Cusorder extends StatefulWidget {
  final String? tableNum;

  const Cusorder({super.key, this.tableNum});

  @override
  State<Cusorder> createState() => _CusorderState();
}

class _CusorderState extends State<Cusorder> {
  String _currentTable = '-';
  bool _isLoading = true;
  String _errorMessage = '';
  String? _tableStatusId;
  late StreamSubscription _approvedSub;
  late StreamSubscription _rejectedSub;

  @override
  void initState() {
    super.initState();
    _initFlow();
    _checkTokenAndStatus();
    SocketService().initSocket();

    _approvedSub = SocketService().onTableApproved.listen((data) {
      print("หน้าจอได้รับสัญญาณอนุมัติ: $data");
      if (mounted) _initFlow();
    });

    
    _rejectedSub = SocketService().onTableRejected.listen((data) {
      print(" ได้รับสัญญาณ table_rejected: $data");
      if (mounted) {
        final msg = data['message'] ?? 'คำขอเปิดโต๊ะถูกปฏิเสธ';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color.fromARGB(255, 6, 6, 6)),
        );
        _initFlow();
      }
    });
  }

  void joinTableRoom(String tableNumber) {
  final cleanTable = tableNumber.trim();
  if (cleanTable.isEmpty || cleanTable == '-') {
    print(" เลขโต๊ะไม่ถูกต้อง ($cleanTable) ไม่ส่งคำขอเข้าห้อง");
    return;
  }

  SocketService().joinTableRoom(cleanTable);
  print("สั่งเข้าห้อง: table_$cleanTable");
}

  String _resolveTableHash() {
    if (widget.tableNum != null && widget.tableNum!.isNotEmpty) {
      return widget.tableNum!;
    }

    final uri = Uri.base;
    String? table = uri.queryParameters['table'];

    if (table == null && uri.fragment.isNotEmpty) {
      final fragment = uri.fragment;
      if (fragment.contains('?')) {
        final queryPart = fragment.substring(fragment.indexOf('?'));
        table = Uri.parse(queryPart).queryParameters['table'];
      }
    }

    return table ?? '';
  }

 Future<void> _initFlow() async {
    final tableHash = _resolveTableHash();

    if (tableHash.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "ไม่พบรหัสโต๊ะใน URL";
        });
      }
      return;
    }

    final (isAuthErr, authenToken, authErrMsg) = await _authenRequest(
      tableHash,
    );

    if (isAuthErr || authenToken.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = authErrMsg;
        });
      }
      return;
    }

    final accessResult = await _accessRequest(authenToken);

    if (accessResult.isError || accessResult.data.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = accessResult.errorMessage;
        });
      }
      return;
    }


    try {
      final decoded = JwtDecoder.decode(accessResult.data);
      print("Decoded Payload ล่าสุด: $decoded");

      final realTable = (decoded['table_number'] ?? decoded['tableno'])?.toString() ?? '-';
      final statusId = decoded['table_status_id']?.toString();

      if (mounted) {
        setState(() {
          _currentTable = realTable;
          _tableStatusId = statusId;
          _errorMessage = '';
          _isLoading = false;
        });
      }

      
      if (realTable.isNotEmpty && realTable != '-') {
        joinTableRoom(realTable);
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการ decode token: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "ถอดรหัสข้อมูลสิทธิ์ไม่สำเร็จ";
        });
      }
    }
  }

  Future<(bool, String, String)> _authenRequest(String tableHash) async {
    try {
      DateTime now = DateTime.now();
      String formattedDateString = DateUtil().getFormattedDate(now);

      String dateHash = sha256
          .convert(utf8.encode(formattedDateString))
          .toString();

      String combinedString = "$tableHash&$dateHash";
      print(" ส่ง authen_request: $combinedString");

      final response = await http.post(
        Uri.parse("${AppConfig.apiBaseUri}/table/table_request"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'authen_request': combinedString}),
      );

      final json = jsonDecode(response.body);
      print(" ผลลัพธ์ table_request: $json");

      bool isError = json["isError"] is bool ? json["isError"] as bool : true;
      String data = json["data"] is String ? json["data"] as String : "";
      String errorMessage =
          json["errorMessage"]?.toString() ?? "เกิดข้อผิดพลาดในการตรวจสอบโต๊ะ";

      return (isError, data, errorMessage);
    } catch (e) {
      return (true, "", "เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว: $e");
    }
  }

  Future<({bool isError, String data, String errorMessage})> _accessRequest(
  String authenToken,
) async {
  try {
    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUri}/table/access_request"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'authen_token': authenToken}),
    );

    final json = jsonDecode(response.body);
    print("ผลลัพธ์ access_request: $json");

    if (json["isError"] == false && json["data"] != null) {
      
      final accessToken = json["data"] is Map 
          ? json["data"]["access_token"]?.toString() ?? ""
          : json["data"]?.toString() ?? "";

      if (accessToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customer_table_token', accessToken);
        print(" บันทึก token สำเร็จ: $accessToken");

        return (isError: false, data: accessToken, errorMessage: "");
      }
    }

    return (
      isError: true,
      data: "",
      errorMessage: json["errorMessage"]?.toString() ?? "ขอสิทธิ์ไม่สำเร็จ",
    );
  } catch (e) {
    print(" Error ใน _accessRequest: $e");
    return (
      isError: true,
      data: "",
      errorMessage: "เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว: $e",
    );
  }
}

  Future<void> _checkTokenAndStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('customer_table_token');

      if (token == null || JwtDecoder.isExpired(token)) {
        setState(() {
          _errorMessage = 'ยังไม่ได้สแกน QR หรือ Session หมดอายุ';
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String? tableStatusId = decodedToken['table_status_id']?.toString();
      final String? tableNumber =
          (decodedToken['table_number'] ?? decodedToken['tableno'])?.toString();

      if (tableStatusId == null) {
        setState(() {
          _errorMessage = 'ข้อมูลไม่ถูกต้อง';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _currentTable = tableNumber ?? '-';
        _tableStatusId = tableStatusId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการอ่านข้อมูล: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markreq(String tableNumber) async {
    final messenger = ScaffoldMessenger.of(context);
    final tableno = int.tryParse(tableNumber) ?? 0;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("ยืนยันการขอเปิดโต๊ะ"),
        content: Text(
          'ต้องการยืนยันการขอเปิดโต๊ะ "$tableNumber" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF51A742),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'ยืนยันการขอเปิดโต๊ะแล้ว',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await AppAPICUS.post('/table/cus-req-table', {
          'table_number': tableno,
        });

        final jsonRes = jsonDecode(response.body);

        if (response.statusCode == 200 && !jsonRes['isError']) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('จัดการรายการของโต๊ะ $tableNumber เรียบร้อยแล้ว'),
            ),
          );
          _initFlow();
        } else {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${jsonRes['errorMessage'] ?? 'ไม่สามารถอัปเดตได้'}',
              ),
            ),
          );
        }
      } catch (e) {
        print("Error updating advice status: $e");
      }
    }
  }

  @override
  void dispose() {
    _approvedSub.cancel();
    _rejectedSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_tableStatusId == 'Y') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, color: Colors.orange, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'กรุณากดปุ่มเพื่อส่งคำขอเปิดโต๊ะให้พนักงาน',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    _markreq(_currentTable);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('ส่งคำขอเปิดโต๊ะ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_tableStatusId == 'C') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 249, 166, 32),
                    strokeWidth: 4,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'ส่งคำขอแล้ว กรุณารอสักครู่...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 249, 166, 32),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_tableStatusId == 'N') {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/menucus');
    }
  });

  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

    // Fallback กรณีไม่ตรงกับเงื่อนไขใดเลย
    return const Scaffold(
      body: Center(child: Text('ไม่พบข้อมูลสถานะโต๊ะที่ถูกต้อง')),
    );
  }
}

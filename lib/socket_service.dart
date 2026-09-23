import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cafa_boardgame/config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _currentJoinedTable;

  // Stream สำหรับ Broadcast เหตุการณ์ต่างๆ
  final _tableRequestStreamController = StreamController<dynamic>.broadcast();
  final _tableApprovedStreamController = StreamController<dynamic>.broadcast();
  final _tableRejectedStreamController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get onTableRequest => _tableRequestStreamController.stream;
  Stream<dynamic> get onTableApproved => _tableApprovedStreamController.stream;
  Stream<dynamic> get onTableRejected => _tableRejectedStreamController.stream;

  bool get isConnected => _socket?.connected ?? false;
  IO.Socket? get socket => _socket;

  void initSocket() {
    if (_socket != null) return;

    _socket = IO.io(
      AppConfig.socketUri,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print(" Connected to Socket Server: ${_socket!.id}");
      if (_currentJoinedTable != null && _currentJoinedTable!.isNotEmpty) {
        _emitJoin(_currentJoinedTable!);
      }
    });

    _socket!.onReconnect((_) {
      print(" Reconnected to Socket Server: ${_socket!.id}");
      if (_currentJoinedTable != null && _currentJoinedTable!.isNotEmpty) {
        _emitJoin(_currentJoinedTable!);
      }
    });

    _socket!.onDisconnect((_) {
      print(" Disconnected from Socket Server");
    });


    _socket!.on('new_table_request', (data) {
      print(" SocketService ได้รับคำขอใหม่: $data");
      _tableRequestStreamController.add(data);
    });

   
    _socket!.on('table_approved', (data) {
      print(" SocketService ได้รับสัญญาณอนุมัติ: $data");
      _tableApprovedStreamController.add(data);
    });


    _socket!.on('table_rejected', (data) {
      print(" SocketService ได้รับสัญญาณปฏิเสธ: $data");
      _tableRejectedStreamController.add(data);
    });
  }

  void joinTableRoom(String tableNumber) {
    if (tableNumber.trim().isEmpty) return;
    _currentJoinedTable = tableNumber.trim();

    if (_socket != null && _socket!.connected) {
      _emitJoin(_currentJoinedTable!);
    } else {
      initSocket();
    }
  }

  void _emitJoin(String table) {
    _socket?.emit('join_table_room', table);
    print(" [SocketService] ส่งคำขอเข้าห้อง: table_$table");
  }

  void disconnect() {
    _currentJoinedTable = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
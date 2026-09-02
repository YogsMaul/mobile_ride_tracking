import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class WebSocketManager {
  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  String? _rideId;
  int _reconnectAttempts = 0;

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<void> connect({String? rideId}) async {
    if (_isConnecting || _channel != null) return;
    _isConnecting = true;
    _rideId = rideId;

    try {
      final token = await _storage.read(key: 'access_token');
      final baseWs = rideId != null
          ? '${ApiConstants.wsUrl}/rides/$rideId'
          : ApiConstants.wsUrl;
      final uri = Uri.parse(baseWs);
      
      _channel = WebSocketChannel.connect(uri);
      
      send({'type': 'auth', 'token': token});
      
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _controller.add(data);
          _reconnectAttempts = 0;
        },
        onError: (_) => _reconnect(),
        onDone: _reconnect,
      );
    } catch (e) {
      _reconnect();
    } finally {
      _isConnecting = false;
    }

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      send({'type': 'ping', 'ride_id': _rideId});
    });
  }

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void _reconnect() {
    _channel = null;
    _reconnectTimer?.cancel();
    
    _reconnectAttempts++;
    final delaySeconds = min(pow(2, _reconnectAttempts - 1).toInt() * 2, 60);
    final jitter = Random().nextInt(1000);
    final delay = Duration(seconds: delaySeconds, milliseconds: jitter);
    
    _reconnectTimer = Timer(delay, connect);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}

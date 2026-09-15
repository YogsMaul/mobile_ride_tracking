import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../storage/secure_storage_service.dart';
import '../constants/api_constants.dart';

class WebSocketManager {
  WebSocketChannel? _channel;
  final SecureStorageService _storage = const SecureStorageService();
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  String? _rideId;
  int _reconnectAttempts = 0;

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<void> connect({String? rideId}) async {
    final effectiveRideId =
        (rideId != null && rideId.trim().isNotEmpty) ? rideId.trim() : _rideId;

    if (effectiveRideId == null || effectiveRideId.isEmpty) {
      // Backend hanya menerima koneksi dengan ID ride: /ws/rides/:id
      // Mencegah koneksi tanpa rideId yang menyebabkan 404 /ws
      return;
    }

    if (_isConnecting || _channel != null) return;
    _isConnecting = true;
    _rideId = effectiveRideId;

    try {
      final token = await _storage.getAccessToken();
      final targetWs = '${ApiConstants.wsUrl}/rides/$effectiveRideId';
      final uri = Uri.parse(targetWs);

      _channel = WebSocketChannel.connect(uri);

      send({'type': 'auth', 'token': token});

      _channel!.stream.listen(
        (message) {
          // Backend menggabungkan beberapa pesan dalam satu frame,
          // dipisah newline (lihat WritePump hub.go) — decode per baris.
          for (final line in const LineSplitter().convert(message as String)) {
            if (line.trim().isEmpty) continue;
            try {
              final data = jsonDecode(line) as Map<String, dynamic>;
              _controller.add(data);
            } catch (_) {
              // Skip baris korup, jangan matikan koneksi.
            }
          }
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
    _pingTimer?.cancel();

    if (_rideId == null || _rideId!.isEmpty) return;

    _reconnectAttempts++;
    final delaySeconds = min(pow(2, _reconnectAttempts - 1).toInt() * 2, 60);
    final jitter = Random().nextInt(1000);
    final delay = Duration(seconds: delaySeconds, milliseconds: jitter);

    _reconnectTimer = Timer(delay, () => connect(rideId: _rideId));
  }

  /// Memutuskan koneksi aktif dan membersihkan timer (ping & reconnect).
  /// Controller stream tetap dibiarkan terbuka agar dapat digunakan kembali
  /// untuk sesi ride berikutnya.
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnecting = false;
    _rideId = null;
    _reconnectAttempts = 0;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}

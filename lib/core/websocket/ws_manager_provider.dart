import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../websocket/ws_manager.dart';

final wsManagerProvider = Provider<WebSocketManager>((ref) => WebSocketManager());
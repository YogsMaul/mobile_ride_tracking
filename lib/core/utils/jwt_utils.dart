import 'dart:convert';

/// Helper ekstrak claim JWT tanpa library pihak ketiga.
class JwtUtils {
  JwtUtils._();

  static String? extractUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map && payload['user_id'] is String) {
        return payload['user_id'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

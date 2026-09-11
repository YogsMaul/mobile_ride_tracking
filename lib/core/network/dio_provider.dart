import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

/// Satu instance [DioClient] untuk seluruh app.
final dioClientProvider = Provider<DioClient>((ref) => DioClient());

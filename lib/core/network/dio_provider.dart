import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

/// Satu instance [DioClient] untuk seluruh app.
///
/// Sebelumnya provider ini dideklarasikan dua kali — di `home_screen.dart` dan
/// `history_screen.dart` — jadi tiap halaman punya Dio + interceptor sendiri.
/// Selain mubazir, dua nama top-level yang sama juga bikin Dart menolak
/// compile begitu ada satu file yang mengimpor kedua screen itu sekaligus.
final dioClientProvider = Provider<DioClient>((ref) => DioClient());

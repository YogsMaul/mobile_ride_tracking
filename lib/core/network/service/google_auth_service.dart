import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In helper untuk Flutter — cukup sampai `id_token`.
///
/// `id_token`-nya DIKIRIM ke backend `/auth/google` (AuthRepository.loginWithGoogle)
/// biar backend yang verifikasi. Sesi app tetap pakai JWT dari backend,
/// bukan credential Google.
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  /// Buka sheet picker Google, dapatkan `id_token` buat ditukar di backend.
  /// Return `null` kalau user batal pilih akun.
  Future<String?> signInAndGetIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // best-effort — revoke gagal gak boleh gagalkan flow
    }
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

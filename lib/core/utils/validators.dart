class AppValidators {
  static String? email(String? value, {bool gmailOnly = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Format email tidak valid';
    }
    if (gmailOnly && !value.trim().toLowerCase().endsWith('@gmail.com')) {
      return 'Pendaftaran hanya menerima alamat @gmail.com';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < minLength) {
      return 'Minimal $minLength karakter';
    }
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasLower = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    if (!hasUpper || !hasLower || !hasDigits) {
      return 'Harus mengandung huruf besar, huruf kecil, dan angka';
    }
    return null;
  }

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }
}

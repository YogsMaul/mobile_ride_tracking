import 'package:flutter/material.dart';

import '../../../../core/network/repository/ride_repository.dart';
import '../../../../core/theme/app_theme.dart';

Future<String?> showConfirmBackDialog(
  BuildContext context, {
  required String leaveLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kembali ke Beranda?'),
      content: const Text(
        'Room tetap berjalan dan kamu bisa masuk lagi kapan saja lewat '
        'banner di beranda. Selama di luar halaman, posisimu tidak '
        'dibagikan ke rider lain.',
        style: TextStyle(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.warn),
          onPressed: () => Navigator.pop(ctx, 'leave'),
          child: Text(leaveLabel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
            minimumSize: const Size(0, 40),
          ),
          onPressed: () => Navigator.pop(ctx, 'home'),
          icon: const Icon(Icons.home_outlined, size: 18),
          label: const Text('Ke Beranda'),
        ),
      ],
    ),
  );
}

Future<bool> showConfirmLeaveOrEndDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Kembali'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.warn),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Flow keluar/selesaikan room: dialog konfirmasi + panggil API yang tepat.
/// Return true kalau room boleh ditutup (caller tinggal Navigator.pop).
Future<bool> runLeaveOrEndFlow({
  required BuildContext context,
  required RideRepository repo,
  required String rideId,
  required bool isHost,
  required bool isPlanned,
  double? currentLat,
  double? currentLng,
  double? currentSpeed,
  double? currentHeading,
}) async {
  String title;
  String content;
  String confirmLabel;

  if (isHost) {
    if (isPlanned) {
      title = 'Batalkan Room?';
      content = 'Room akan dibatalkan dan semua peserta akan dikeluarkan.';
      confirmLabel = 'Batalkan Room';
    } else {
      title = 'Selesaikan Perjalanan?';
      content = 'Perjalanan akan diselesaikan dan tracking konvoi diakhiri.';
      confirmLabel = 'Selesaikan';
    }
  } else {
    title = 'Keluar dari Room?';
    content = 'Kamu akan keluar dari sesi perjalanan ini.';
    confirmLabel = 'Keluar';
  }

  final ok = await showConfirmLeaveOrEndDialog(
    context,
    title: title,
    content: content,
    confirmLabel: confirmLabel,
  );
  if (ok != true) return false;

  try {
    if (isHost) {
      if (isPlanned) {
        await repo.cancelRide(rideId);
      } else {
        await repo.endRide(
          rideId,
          lat: currentLat,
          lng: currentLng,
          speed: currentSpeed,
          heading: currentHeading,
        );
      }
    } else {
      await repo.leaveRide(rideId);
    }
  } catch (_) {
    // Abaikan error jaringan saat keluar
  }
  return true;
}

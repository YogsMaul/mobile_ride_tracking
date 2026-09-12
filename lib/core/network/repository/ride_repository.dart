import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/app_exception.dart';
import '../dio_provider.dart';
import '../models/ride_model.dart';
import '../service/ride_service.dart';
import '../../../features/history/ride_history_item.dart';

class RideRepository {
  final RideService service;

  RideRepository(this.service);

  Future<RideModel> createRide({String? name}) async {
    try {
      final response = await service.createRide(name: name);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Gagal membuat ride: data tidak valid.');
      }
      final ride = RideModel.fromJson(data);
      if (ride.id.isEmpty) {
        throw const AppException('Server tidak mengirim ID ride.');
      }
      return ride;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<RideModel> joinRide({required String inviteCode}) async {
    try {
      final response = await service.joinRide(inviteCode: inviteCode);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Gagal join ride: data tidak valid.');
      }
      final ride = RideModel.fromJson(data);
      if (ride.id.isEmpty) {
        throw const AppException('Server tidak mengirim ID ride.');
      }
      return ride;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<RideModel> getRideDetail(String rideId) async {
    try {
      final response = await service.getRideDetail(rideId);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Data detail ride tidak valid.');
      }
      return RideModel.fromJson(data);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> startRide(String rideId) async {
    try {
      await service.startRide(rideId);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// GET /rides/me — ambil riwayat ride user.
  /// Backend mengembalikan array MyRideSummary yang sudah termasuk
  /// participant_count dan role (host/joined).
  Future<List<RideHistoryItem>> getMyRides({String? status}) async {
    try {
      final response = await service.getMyRides(status: status);
      final data = response.data;
      if (data is! List) {
        return [];
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => RideHistoryItem.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// POST /rides/:id/end — owner selesaikan ride.
  Future<void> endRide(String rideId) async {
    try {
      await service.endRide(rideId);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// POST /rides/:id/cancel — owner batalkan ride.
  Future<void> cancelRide(String rideId) async {
    try {
      await service.cancelRide(rideId);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// DELETE /rides/:id/leave — member keluar dari ride.
  Future<void> leaveRide(String rideId) async {
    try {
      await service.leaveRide(rideId);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final dio = ref.watch(dioClientProvider).instance;
  return RideRepository(RideService(dio));
});

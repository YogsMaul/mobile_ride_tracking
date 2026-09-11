import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/app_exception.dart';
import '../dio_provider.dart';
import '../models/ride_model.dart';
import '../service/ride_service.dart';

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
}

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final dio = ref.watch(dioClientProvider).instance;
  return RideRepository(RideService(dio));
});

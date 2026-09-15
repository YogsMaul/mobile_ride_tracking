import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

/// Service layer untuk endpoint rides.
/// Raw HTTP saja — mapping & error ada di RideRepository.
class RideService {
  final Dio dio;

  RideService(this.dio);

  Future<Response> createRide({String? name}) async {
    return await dio.post(
      ApiConstants.createRideEndpoint,
      data: name != null ? {'name': name} : null,
    );
  }

  Future<Response> joinRide({required String inviteCode}) async {
    return await dio.post(
      ApiConstants.joinRideEndpoint,
      data: {'invite_code': inviteCode},
    );
  }

  Future<Response> getRideDetail(String rideId) async {
    return await dio.get(ApiConstants.rideDetailEndpoint(rideId));
  }

  Future<Response> startRide(String rideId) async {
    return await dio.post(ApiConstants.startRideEndpoint(rideId));
  }

  /// GET /rides/me — list semua ride dimana user jadi member.
  /// [status] opsional: 'completed', 'cancelled', 'active', 'planned'
  /// (comma-separated untuk multiple).
  Future<Response> getMyRides({String? status, int limit = 50, int offset = 0}) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    return await dio.get(
      ApiConstants.myRidesEndpoint,
      queryParameters: params,
    );
  }

  /// POST /rides/:id/end — owner selesaikan ride (active → completed).
  Future<Response> endRide(String rideId) async {
    return await dio.post(ApiConstants.endRideEndpoint(rideId));
  }

  /// POST /rides/:id/cancel — owner batalkan ride (planned/active → cancelled).
  Future<Response> cancelRide(String rideId) async {
    return await dio.post(ApiConstants.cancelRideEndpoint(rideId));
  }

  /// DELETE /rides/:id/leave — member (bukan owner) keluar dari ride planned.
  Future<Response> leaveRide(String rideId) async {
    return await dio.delete(ApiConstants.leaveRideEndpoint(rideId));
  }

  /// GET /rides/:id/trail — daftar koordinat GPS rute (maks 300 titik).
  Future<Response> getRideTrail(String rideId) async {
    return await dio.get(ApiConstants.rideTrailEndpoint(rideId));
  }

  /// GET /rides/:id/members — daftar peserta konvoi (host + members).
  Future<Response> getRideMembers(String rideId) async {
    return await dio.get(ApiConstants.rideMembersEndpoint(rideId));
  }

  /// PATCH /rides/:id/destination — set titik tujuan (owner only).
  Future<Response> setDestination({
    required String rideId,
    required String name,
    required double lat,
    required double lng,
  }) async {
    return await dio.patch(
      ApiConstants.rideDestinationEndpoint(rideId),
      data: {'name': name, 'lat': lat, 'lng': lng},
    );
  }

  /// DELETE /rides/:id/destination — hapus titik tujuan (owner only).
  Future<Response> clearDestination(String rideId) async {
    return await dio.delete(ApiConstants.rideDestinationEndpoint(rideId));
  }
}

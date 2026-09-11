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
}

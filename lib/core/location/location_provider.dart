import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../location/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
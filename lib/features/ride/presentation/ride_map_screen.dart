import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/location/location_provider.dart';
import '../../../core/websocket/ws_manager_provider.dart';

class RiderLocation {

  final String userId;
  final LatLng position;
  final double heading;
  final double speed;

  RiderLocation({
    required this.userId,
    required this.position,
    required this.heading,
    required this.speed,
  });
}

class RideMapScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String? inviteCode;

  const RideMapScreen({
    super.key,
    required this.rideId,
    this.inviteCode,
  });

  @override
  ConsumerState<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends ConsumerState<RideMapScreen> {
  final MapController _mapController = MapController();
  final Map<String, RiderLocation> _otherRiders = {};
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initRide();
  }

  Future<void> _initRide() async {
    final locationService = ref.read(locationServiceProvider);
    final ws = ref.read(wsManagerProvider);

    final hasPermission = await locationService.checkPermission();
    if (!hasPermission) return;

    await ws.connect(rideId: widget.rideId);

    // Listen incoming websocket broadcast
    ws.stream.listen((data) {
      if (data['type'] == 'location_update' && data['user_id'] != null) {
        final userId = data['user_id'] as String;
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        final heading = ((data['heading'] as num?) ?? 0.0).toDouble();
        final speed = ((data['speed'] as num?) ?? 0.0).toDouble();

        setState(() {
          _otherRiders[userId] = RiderLocation(
            userId: userId,
            position: LatLng(lat, lng),
            heading: heading,
            speed: speed,
          );
        });
      }
    });

    // Stream user location
    locationService.getPositionStream().listen((position) {
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPos;
      });

      _mapController.move(newPos, _mapController.camera.zoom);

      ws.send({
        'type': 'location_update',
        'ride_id': widget.rideId,
        'lat': position.latitude,
        'lng': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
      });
    });
  }

  void _showInviteQr() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Invite Riders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: widget.inviteCode ?? widget.rideId,
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 16),
            Text(
              'Code: ${widget.inviteCode ?? widget.rideId}',
              style: const TextStyle(fontSize: 16, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // Current user marker (Blue)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 40,
          height: 40,
          child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 36),
        ),
      );
    }

    // Other riders markers (Orange/Green)
    _otherRiders.forEach((userId, rider) {
      markers.add(
        Marker(
          point: rider.position,
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  userId.substring(0, 4),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const Icon(Icons.two_wheeler, color: Colors.orange, size: 24),
            ],
          ),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Ride: ${widget.rideId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showInviteQr,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition ?? const LatLng(-6.2088, 106.8456),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ridetracking.app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Riders: ${_otherRiders.length + 1} online'),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              child: const Text('Leave Ride', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

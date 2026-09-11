import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_provider.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/websocket/ws_manager_provider.dart';
import '../ride_state.dart';
import 'rider_location.dart';
import 'widgets/ride_bottom_bar.dart';
import 'widgets/ride_invite_sheet.dart';
import 'widgets/ride_map_markers.dart';

class RideMapScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String? inviteCode;
  final String? rideName;

  const RideMapScreen({
    super.key,
    required this.rideId,
    this.inviteCode,
    this.rideName,
  });

  @override
  ConsumerState<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends ConsumerState<RideMapScreen> {
  static const _storage = SecureStorageService();
  final MapController _mapController = MapController();
  final Map<String, RiderLocation> _otherRiders = {};
  LatLng? _currentPosition;
  String? _myUserId;

  late final RideStateNotifier _rideNotifier;

  @override
  void initState() {
    super.initState();
    _rideNotifier = ref.read(rideStateProvider.notifier);
    _initRide();
  }

  @override
  void dispose() {
    _rideNotifier.clear();
    super.dispose();
  }

  Future<void> _initRide() async {
    final locationService = ref.read(locationServiceProvider);
    final ws = ref.read(wsManagerProvider);

    _myUserId = await _resolveCurrentUserId();

    final hasPermission = await locationService.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lokasi belum aktif. Hidupkan GPS & izinkan lokasi, '
              'lalu masuk ulang ride.',
            ),
          ),
        );
      }
      return;
    }

    final initial = await locationService.getCurrentPosition();
    if (initial != null && mounted) {
      final seed = LatLng(initial.latitude, initial.longitude);
      setState(() {
        _currentPosition = seed;
      });
      _mapController.move(seed, _mapController.camera.zoom);
    }

    await ws.connect(rideId: widget.rideId);

    if (initial != null) {
      _sendLocation(
        lat: initial.latitude,
        lng: initial.longitude,
        heading: initial.heading,
        speed: initial.speed,
      );
    }

    ws.stream.listen(_onWsMessage);

    locationService.getPositionStream().listen((position) {
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPos;
      });

      _mapController.move(newPos, _mapController.camera.zoom);

      _sendLocation(
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: position.speed,
      );
    });
  }

  void _onWsMessage(Map<String, dynamic> data) {
    if (data['type'] != 'location_update' || data['user_id'] == null) {
      return;
    }
    final userId = data['user_id'] as String;
    if (_myUserId != null && userId == _myUserId) return;

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

  void _sendLocation({
    required double lat,
    required double lng,
    required double heading,
    required double speed,
  }) {
    ref.read(wsManagerProvider).send({
      'type': 'location_update',
      'ride_id': widget.rideId,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
    });
  }

  void _showInviteQr() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => RideInviteSheet(
        qrData: widget.inviteCode ?? widget.rideId,
        displayName: _displayName(),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari ride?'),
        content: const Text('Posisi kamu akan berhenti dikirim.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final markers = buildRideMarkers(
      currentPosition: _currentPosition,
      otherRiders: _otherRiders,
    );
    final riderCount = _otherRiders.length + (_currentPosition != null ? 1 : 0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ride aktif',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _displayName(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Undang',
            icon: const Icon(Icons.qr_code_2, color: AppColors.ink),
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
      bottomNavigationBar: RideBottomBar(
        riderCount: riderCount,
        onLeave: _confirmLeave,
      ),
    );
  }

  Future<String?> _resolveCurrentUserId() async {
    final stored = await _storage.getUserId();
    if (stored != null && stored.isNotEmpty) return stored;

    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    return _userIdFromJwt(token);
  }

  String? _userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map && payload['user_id'] is String) {
        return payload['user_id'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _displayName() {
    final n = widget.rideName;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    final raw = widget.inviteCode ?? widget.rideId;
    return raw.replaceAll('-', '').substring(0, 8).toUpperCase();
  }
}

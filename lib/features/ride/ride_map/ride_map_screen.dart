import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/location/location_provider.dart';
import '../../../core/network/models/ride_member_model.dart';
import '../../../core/network/models/ride_model.dart';
import '../../../core/network/repository/ride_repository.dart';
import '../../../core/network/service/route_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/jwt_utils.dart';
import '../../../core/websocket/ws_manager.dart';
import '../../../core/websocket/ws_manager_provider.dart';
import '../../../core/widgets/app_toast.dart';
import '../../settings/settings_provider.dart';
import '../ride_state.dart';
import 'rider_location.dart';
import 'ride_destination_controller.dart';
import 'ride_smoothing_controller.dart';
import 'widgets/ride_bottom_bar.dart';
import 'widgets/ride_destination_sheet.dart';
import 'widgets/ride_invite_sheet.dart';
import 'widgets/ride_map_app_bar.dart';
import 'widgets/ride_map_controls.dart';
import 'widgets/ride_map_destination_card.dart';
import 'widgets/ride_map_dialogs.dart';
import 'widgets/ride_map_markers.dart';
import 'widgets/ride_map_pick_card.dart';
import 'widgets/ride_members_sheet.dart';
import 'widgets/ride_map_status_banner.dart';

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
  final RideSmoothingController _riders = RideSmoothingController();
  final RideDestinationController _dest = RideDestinationController();

  LatLng? _currentPosition;
  double _myHeading = 0;
  double _mySpeed = 0;
  String? _myUserId;
  double _targetMapRotation = 0;
  Timer? _mapRotationTimer;

  RideModel? _rideDetail;
  List<RideMember> _members = [];
  bool _isStarting = false;
  bool _followMe = true;
  bool _headingMode = false;
  Timer? _membersPollTimer;
  Timer? _heartbeatTimer;

  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  late final RideStateNotifier _rideNotifier;
  late final WebSocketManager _ws;
  bool _permanentLeave = false;

  bool get _isHost {
    if (_rideDetail?.ownerId != null && _myUserId != null) {
      return _rideDetail!.ownerId == _myUserId;
    }
    // Fallback: cek apakah ada di members sebagai host
    final hostMember = _members.where((m) => m.isHost).firstOrNull;
    if (hostMember != null && _myUserId != null) {
      return hostMember.userId == _myUserId;
    }
    return false;
  }

  String get _rideStatus => _rideDetail?.status ?? 'planned';

  @override
  void initState() {
    super.initState();
    _rideNotifier = ref.read(rideStateProvider.notifier);
    _ws = ref.read(wsManagerProvider);
    // Layar tetap menyala selama ride — sesuai preferensi user di Settings.
    final keepOn = ref.read(settingsProvider).keepScreenOn;
    if (keepOn) {
      WakelockPlus.enable();
    }
    _riders.addListener(_rebuild);
    _dest.addListener(_rebuild);
    _riders.start();

    // Loop animasi 60 FPS (16ms) untuk rotasi peta ultra-smooth ala Google Maps
    _mapRotationTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_followMe || !_headingMode || _currentPosition == null) return;
      final curRot = _mapController.camera.rotation;
      var diff = (_targetMapRotation - curRot + 180) % 360 - 180;
      if (diff.abs() > 0.1) {
        // LERP step 0.18 tiap 16ms untuk transisi kamera yang mengalir mulus tanpa patah-patah
        final nextRot = (curRot + diff * 0.18 + 360) % 360;
        _mapController.rotate(nextRot);
      }
    });

    _initRide();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mapRotationTimer?.cancel();
    _membersPollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _wsSubscription?.cancel();
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    _ws.disconnect();
    _riders.dispose();
    _dest.dispose();
    // Selalu matikan wakelock saat keluar dari peta.
    WakelockPlus.disable();

    if (_permanentLeave) {
      Future.microtask(_rideNotifier.clear);
    }
    super.dispose();
  }

  Future<void> _initRide() async {
    final locationService = ref.read(locationServiceProvider);
    final ws = _ws;

    _myUserId = await _resolveCurrentUserId();

    // Fetch initial detail & members in parallel
    await _fetchRideDetailAndMembers();

    // Start polling members as fallback while planned/lobby
    _startMembersPolling();

    final hasPermission = await locationService.checkPermission();
    if (!hasPermission && mounted) {
      AppToast.info(
        context,
        'Lokasi belum aktif. Hidupkan GPS & izinkan lokasi agar rider '
        'lain melihat posisimu.',
      );
    }

    // WS & event masuk dulu, tidak bergantung pada GPS — biar tetap terima
    // posisi rider lain & update status walau lokasi sendiri belum ada.
    await ws.connect(rideId: widget.rideId);
    _wsSubscription = ws.stream.listen(_onWsMessage);

    final initial = await locationService.getCurrentPosition();
    if (initial != null && mounted) {
      final seed = LatLng(initial.latitude, initial.longitude);
      setState(() {
        _currentPosition = seed;
        _myHeading = initial.heading;
        _mySpeed = initial.speed;
      });
      _mapController.move(seed, _mapController.camera.zoom);
      _sendLocation(
        lat: initial.latitude,
        lng: initial.longitude,
        heading: initial.heading,
        speed: initial.speed,
      );
    }

    // Rider diam (emulator / nunggu lobby) tidak memancarkan event stream,
    // jadi resend posisi terakhir berkala biar marker tetap hidup & tak
    // dianggap offline oleh throttle 250ms hub.
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _currentPosition == null) return;
      _sendLocation(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        heading: _myHeading,
        speed: _mySpeed,
      );
    });

    // Sensor Kompas Perangkat: Tangkap target arah hadap & rotasi peta
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final heading = event.heading;
      if (heading != null && _mySpeed < 1.0) {
        final targetHeading = (heading + 360) % 360;
        final diff = (targetHeading - _myHeading + 180) % 360 - 180;
        final absDiff = diff.abs();

        if (absDiff < 0.4) return;

        final factor = absDiff > 15 ? 0.90 : (absDiff > 5 ? 0.65 : 0.40);
        final smoothedHeading = (_myHeading + diff * factor + 360) % 360;

        _myHeading = smoothedHeading;
        _targetMapRotation = (-smoothedHeading + 360) % 360;
        setState(() {});
      }
    });

    _locationSubscription = locationService.getPositionStream().listen((
      position,
    ) {
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPos;
        _myHeading = position.heading;
        _mySpeed = position.speed;
        if (position.heading >= 0) {
          _targetMapRotation = (-position.heading + 360) % 360;
        }
      });

      if (_followMe) {
        _mapController.move(newPos, _mapController.camera.zoom);
      }

      // Re-route OSRM hanya jika melenceng > 500m dari awal rute saat ini.
      _autoReroute(newPos);

      _sendLocation(
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: position.speed,
      );
    });
  }

  void _autoReroute(LatLng newPos) {
    final route = _dest.routeResult;
    if (_dest.destPoint == null) return;

    if (route == null || route.points.isEmpty) {
      _dest.refreshRoute(newPos);
      return;
    }

    const distanceCalc = Distance();

    // 1. Cek jarak ke titik awal rute (kalau baru mulai jalan)
    final distFromStart = distanceCalc.as(
      LengthUnit.Meter,
      route.points.first,
      newPos,
    );

    // 2. Cek apakah posisi user menyimpang dari segmen jalur (ala off-route detection Google Maps)
    double minDistanceToRoute = double.infinity;
    for (int i = 0; i < route.points.length; i++) {
      final d = distanceCalc.as(LengthUnit.Meter, route.points[i], newPos);
      if (d < minDistanceToRoute) {
        minDistanceToRoute = d;
      }
    }

    // Jika user melenceng > 60 meter dari seluruh segmen jalur rute,
    // atau sudah bergerak > 100m dari titik awal perhitungan lama, hitung ulang rute terdekat.
    if (minDistanceToRoute > 60 || distFromStart > 100) {
      _dest.refreshRoute(newPos);
    }
  }

  void _startMembersPolling() {
    _membersPollTimer?.cancel();
    if (_rideStatus == 'planned') {
      _membersPollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (!mounted || _rideStatus != 'planned') {
          _membersPollTimer?.cancel();
          return;
        }
        _refreshMembers();
      });
    }
  }

  Future<void> _fetchRideDetailAndMembers() async {
    final repo = ref.read(rideRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.getRideDetail(widget.rideId),
        repo.getRideMembers(widget.rideId),
      ]);
      if (mounted) {
        final detail = results[0] as RideModel;
        setState(() {
          _rideDetail = detail;
          _members = results[1] as List<RideMember>;
          if (detail.destName != null &&
              detail.destLat != null &&
              detail.destLng != null) {
            _dest.applyDestination(
              detail.destName!,
              LatLng(detail.destLat!, detail.destLng!),
            );
          }
        });
        _dest.refreshRoute(_currentPosition);
      }
    } catch (_) {
      // Fallback jika salah satu endpoint gagal
      _refreshMembers();
    }
  }

  Future<void> _refreshMembers() async {
    try {
      final repo = ref.read(rideRepositoryProvider);
      final list = await repo.getRideMembers(widget.rideId);
      if (mounted) {
        setState(() {
          _members = list;
        });
      }
    } catch (_) {}
  }

  void _onWsMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    if (type == 'destination_set') {
      final name = data['dest_name'] as String?;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (name != null && lat != null && lng != null) {
        final point = LatLng(lat, lng);
        final before = _dest.destName;
        _dest.applyDestination(name, point);
        if (before != name) {
          _fitRouteBounds(point);
          _dest.refreshRoute(_currentPosition).then((_) {
            if (mounted) _fitRouteBounds(point);
          });
          if (mounted) AppToast.info(context, 'Tujuan diset ke: $name');
        }
      }
      return;
    }

    if (type == 'destination_cleared') {
      _dest.clear();
      if (mounted) {
        AppToast.info(context, 'Tujuan konvoi dihapus oleh Room Master');
      }
      return;
    }

    if (type == 'member_joined' || type == 'member_left') {
      if (type == 'member_left') {
        final gone = data['user_id'] as String?;
        if (gone != null) _riders.remove(gone);
      }
      _refreshMembers();
      if (mounted && type == 'member_joined') {
        final name = data['name'] as String? ?? 'Peserta baru';
        AppToast.info(context, '$name bergabung ke room!');
      }
      return;
    }

    if (type == 'ride_started') {
      if (mounted) {
        setState(() {
          if (_rideDetail != null) {
            _rideDetail = _rideDetail!.copyWith(status: 'active');
          }
        });
        _membersPollTimer?.cancel();
        AppToast.success(context, 'Perjalanan telah dimulai oleh Room Master!');
      }
      return;
    }

    if (type != 'location_update' || data['user_id'] == null) {
      return;
    }

    final userId = data['user_id'] as String;
    if (_myUserId != null && userId == _myUserId) return;

    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final heading = ((data['heading'] as num?) ?? 0.0).toDouble();
    final speed = ((data['speed'] as num?) ?? 0.0).toDouble();

    _riders.update(
      userId,
      RiderLocation(
        userId: userId,
        position: LatLng(lat, lng),
        heading: heading,
        speed: speed,
      ),
    );
  }

  Map<String, String> get _memberNames => {
    for (final m in _members) m.userId: m.name,
  };

  void _sendLocation({
    required double lat,
    required double lng,
    required double heading,
    required double speed,
  }) {
    _ws.send({
      'type': 'location_update',
      'ride_id': widget.rideId,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
    });
  }

  Future<void> _handleClearDestination() async {
    try {
      final repo = ref.read(rideRepositoryProvider);
      await repo.clearDestination(widget.rideId);
      _dest.clear();
      if (mounted) {
        AppToast.success(context, 'Tujuan berhasil dihapus');
      }
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal menghapus tujuan: $e');
    }
  }

  void _showDestinationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => RideDestinationSheet(
        isHost: _isHost,
        userLocation: _currentPosition,
        currentDestName: _dest.destName,
        currentLat: _dest.destPoint?.latitude,
        currentLng: _dest.destPoint?.longitude,
        routeDistance: _dest.routeResult?.distanceFormatted,
        routeDuration: _dest.routeResult?.durationFormatted,
        onSelectDestination: (name, lat, lng) async {
          await _handleSetDestination(name, LatLng(lat, lng));
        },
        onPickOnMap: _isHost ? _dest.startPick : null,
        onClearDestination: _isHost && _dest.destName != null
            ? _handleClearDestination
            : null,
      ),
    );
  }

  /// Hold (long-press) peta oleh host → langsung masuk mode pilih titik
  /// di lokasi yang ditekan, tanpa perlu buka sheet tujuan dulu.
  void _openDestinationPicker(LatLng point) {
    if (!_isHost) {
      AppToast.info(
        context,
        'Cuma Room Master yang bisa mengatur tujuan konvoi.',
      );
      return;
    }
    _dest.startPick();
    _onMapTap(point);
  }

  void _onMapTap(LatLng point) {
    if (!_dest.pickMode || !_isHost) return;
    _dest.tapPoint(point, _currentPosition);
  }

  Future<void> _applyPickedPoint() async {
    final point = _dest.pickedPoint;
    if (point == null) return;
    final name = _dest.pickedName?.isNotEmpty == true
        ? _dest.pickedName!
        : 'Titik Terpilih';
    final preview = _dest.previewRoute;
    _dest.confirmPick();
    await _handleSetDestination(name, point, previewRoute: preview);
  }

  Future<void> _handleSetDestination(
    String name,
    LatLng point, {
    RideRouteResult? previewRoute,
  }) async {
    try {
      final repo = ref.read(rideRepositoryProvider);
      await repo.setDestination(
        rideId: widget.rideId,
        name: name,
        lat: point.latitude,
        lng: point.longitude,
      );
      if (!mounted) return;
      if (previewRoute != null) {
        _dest.applyPreview(name, point, previewRoute);
        _fitRouteBounds(point);
      } else {
        _dest.applyDestination(name, point);
        _fitRouteBounds(point);
        _dest.refreshRoute(_currentPosition).then((_) {
          if (mounted) _fitRouteBounds(point);
        });
      }
      setState(() {
        if (_rideDetail != null) {
          _rideDetail = _rideDetail!.copyWith(
            destName: name,
            destLat: point.latitude,
            destLng: point.longitude,
          );
        }
      });
      AppToast.success(context, 'Tujuan berhasil diperbarui');
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal mengubah tujuan: $e');
    }
  }

  /// Fit camera agar posisi saat ini + seluruh rute + titik tujuan muat
  /// di layar seperti tampilan navigasi Google Maps / Gojek.
  void _fitRouteBounds(LatLng destination) {
    setState(() => _followMe = false);

    final start = _currentPosition;

    // Jika jarak terlalu jauh (> 150 km) atau GPS berada di negara lain,
    // langsung fokuskan kamera ke titik tujuan agar tidak zoom out ke seluruh dunia.
    if (start != null) {
      final directDistance = const Distance().as(
        LengthUnit.Kilometer,
        start,
        destination,
      );
      if (directDistance > 150) {
        _mapController.move(destination, 15.0);
        return;
      }
    }

    final routePoints = _dest.routeResult?.points ?? _dest.previewRoute?.points;

    final points = <LatLng>[?start, destination, ...?routePoints];

    if (points.length < 2) {
      _mapController.move(destination, 16.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          top: 90,
          bottom: 140,
          left: 40,
          right: 40,
        ),
        maxZoom: 16.5,
      ),
    );
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
        displayCode: _displayCode(),
      ),
    );
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => RideMembersSheet(
        members: _members,
        roomName: _displayName(),
        inviteCode: _displayCode(),
        status: _rideStatus,
        myUserId: _myUserId,
        onLocate: _locateRider,
        onInvite: () {
          Navigator.pop(sheetContext);
          _showInviteQr();
        },
      ),
    );
  }

  void _locateRider(RideMember member) {
    final rider = _riders.smooth[member.userId];
    if (rider == null) {
      if (mounted) {
        AppToast.info(context, '${member.name} belum mengirim lokasi.');
      }
      return;
    }
    setState(() => _followMe = false);
    _mapController.move(
      rider.position,
      _mapController.camera.zoom.clamp(16.0, 17.0),
    );
  }

  Future<void> _startRide() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final repo = ref.read(rideRepositoryProvider);
      await repo.startRide(widget.rideId);

      if (mounted) {
        setState(() {
          if (_rideDetail != null) {
            _rideDetail = _rideDetail!.copyWith(status: 'active');
          }
        });
        _membersPollTimer?.cancel();
        AppToast.success(context, 'Perjalanan dimulai! Live tracking aktif.');
      }
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, 'Gagal memulai ride: ${e.message}');
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal memulai ride: $e');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  /// Tombol back: minimize ke beranda tanpa keluar room, atau keluar beneran.
  Future<void> _confirmBackAction() async {
    final leaveLabel = _isHost
        ? (_rideStatus == 'planned' ? 'Batalkan Room' : 'Selesaikan')
        : 'Keluar Room';
    final action = await showConfirmBackDialog(context, leaveLabel: leaveLabel);
    if (action == 'leave' && mounted) {
      _confirmLeaveOrEnd();
    } else if (action == 'home' && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmLeaveOrEnd() async {
    final ok = await runLeaveOrEndFlow(
      context: context,
      repo: ref.read(rideRepositoryProvider),
      rideId: widget.rideId,
      isHost: _isHost,
      isPlanned: _rideStatus == 'planned',
      currentLat: _currentPosition?.latitude,
      currentLng: _currentPosition?.longitude,
      currentSpeed: _mySpeed,
      currentHeading: _myHeading,
    );
    if (ok && mounted) {
      _permanentLeave = true;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = buildRideMarkers(
      currentPosition: _currentPosition,
      currentHeading: _myHeading,
      currentIsMoving: _mySpeed > 0.8,
      showHeadingBeam: _headingMode,
      otherRiders: _riders.smooth,
      names: _memberNames,
      destinationPoint: _dest.pickedPoint ?? _dest.destPoint,
      destinationName: _dest.pickedPoint != null
          ? _dest.pickedName
          : _dest.destName,
      destinationIsPreview: _dest.pickedPoint != null,
    );
    final riderCount = _members.isNotEmpty
        ? _members.length
        : (_riders.smooth.length + (_currentPosition != null ? 1 : 0));
    final isPlanned = _rideStatus == 'planned';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmBackAction();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: RideMapAppBar(
          isPlanned: isPlanned,
          title: _displayName(),
          memberCount: _members.length,
          onBack: _confirmBackAction,
          onShowMembers: _showMembersSheet,
          onShowInvite: _showInviteQr,
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    _currentPosition ?? const LatLng(-6.2088, 106.8456),
                initialZoom: 16,
                minZoom: 5,
                maxZoom: 18,
                onTap: (_, point) => _onMapTap(point),
                onLongPress: (_, point) {
                  if (_dest.pickMode && _isHost) {
                    _onMapTap(point);
                    return;
                  }
                  _openDestinationPicker(point);
                },
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && _followMe) {
                    setState(() => _followMe = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ridetracking.app',
                  keepBuffer: 3,
                  panBuffer: 1,
                ),
                if (_dest.previewRoute != null &&
                    _dest.previewRoute!.points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _dest.previewRoute!.points,
                        strokeWidth: 5.0,
                        color: AppColors.ink.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                if (_dest.routeResult != null &&
                    _dest.routeResult!.points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _dest.routeResult!.points,
                        strokeWidth: 5.5,
                        color: AppColors.brand,
                        borderColor: Colors.white.withValues(alpha: 0.8),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            // Lobby banner notice di bawah AppBar
            if (isPlanned) RideLobbyBanner(isHost: _isHost),
            if (_dest.pickMode)
              Positioned(
                left: 14,
                right: 72,
                bottom: 14,
                child: RideMapPickCard(
                  pickedPoint: _dest.pickedPoint,
                  pickedName: _dest.pickedName,
                  previewRoute: _dest.previewRoute,
                  previewUnavailable: _dest.previewUnavailable,
                  onCancel: _dest.cancelPick,
                  onApply: _applyPickedPoint,
                ),
              ),
            if (!isPlanned) RideLivePill(riderCount: riderCount),
            if (!_dest.pickMode && (_dest.destName != null || _isHost))
              Positioned(
                left: 14,
                right: 72,
                bottom: _dest.destName != null && _dest.routeResult != null
                    ? 56
                    : 14,
                child: SafeArea(
                  child: RideMapDestinationCard(
                    destName: _dest.destName,
                    routeResult: _dest.routeResult,
                    isCalculatingRoute: _dest.isCalculatingRoute,
                    isHost: _isHost,
                    onTap: () {
                      if (_dest.destPoint != null) {
                        _fitRouteBounds(_dest.destPoint!);
                      }
                    },
                    onClear: _handleClearDestination,
                    onShowSheet: _showDestinationSheet,
                  ),
                ),
              ),
            Positioned(
              right: 14,
              bottom: 14,
              child: RideMapControls(
                followMe: _followMe,
                headingMode: _headingMode,
                hasDestination: _dest.destName != null,
                destTooltip: _dest.destName != null
                    ? 'Tujuan konvoi'
                    : 'Atur tujuan',
                onFollowMe: () {
                  setState(() {
                    _followMe = true;
                  });
                  if (_currentPosition != null) {
                    final targetZoom = _mapController.camera.zoom.clamp(15.0, 17.5);
                    if (_headingMode && _myHeading >= 0) {
                      _mapController.moveAndRotate(_currentPosition!, targetZoom, -_myHeading);
                    } else {
                      _mapController.move(_currentPosition!, targetZoom);
                    }
                  }
                },
                onToggleHeadingMode: () {
                  setState(() {
                    _headingMode = !_headingMode;
                    if (_headingMode) {
                      _followMe = true;
                      if (_currentPosition != null && _myHeading >= 0) {
                        _mapController.moveAndRotate(
                          _currentPosition!,
                          _mapController.camera.zoom.clamp(15.0, 17.5),
                          -_myHeading,
                        );
                      }
                    } else {
                      _mapController.rotate(0);
                    }
                  });
                },
                onZoomIn: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom + 1).clamp(5.0, 18.0),
                ),
                onZoomOut: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom - 1).clamp(5.0, 18.0),
                ),
                onShowDestination: _showDestinationSheet,
              ),
            ),
          ],
        ),
        bottomNavigationBar: RideBottomBar(
          riderCount: riderCount,
          isHost: _isHost,
          status: _rideStatus,
          isStarting: _isStarting,
          onLeave: _confirmLeaveOrEnd,
          onStart: _startRide,
        ),
      ),
    );
  }

  Future<String?> _resolveCurrentUserId() async {
    final stored = await _storage.getUserId();
    if (stored != null && stored.isNotEmpty) return stored;

    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    return JwtUtils.extractUserId(token);
  }

  String _displayName() {
    final detailName = _rideDetail?.name;
    if (detailName != null && detailName.trim().isNotEmpty) {
      return detailName.trim();
    }
    final n = widget.rideName;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    return _displayCode();
  }

  String _displayCode() {
    final raw = (widget.inviteCode ?? _rideDetail?.inviteCode ?? widget.rideId)
        .replaceAll('-', '');
    return raw.length >= 8
        ? raw.substring(0, 8).toUpperCase()
        : raw.toUpperCase();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/location/location_provider.dart';
import '../../../core/network/models/ride_member_model.dart';
import '../../../core/network/models/ride_model.dart';
import '../../../core/network/repository/ride_repository.dart';
import '../../../core/network/service/route_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/websocket/ws_manager_provider.dart';
import '../../../core/widgets/app_toast.dart';
import '../ride_state.dart';
import 'rider_location.dart';
import 'widgets/ride_bottom_bar.dart';
import 'widgets/ride_destination_sheet.dart';
import 'widgets/ride_invite_sheet.dart';
import 'widgets/ride_map_markers.dart';
import 'widgets/ride_members_sheet.dart';

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
  final RouteService _routeService = RouteService();
  final Map<String, RiderLocation> _otherRiders = {};
  final Map<String, RiderLocation> _smoothRiders = {};
  LatLng? _currentPosition;
  double _myHeading = 0;
  double _mySpeed = 0;
  String? _myUserId;

  RideModel? _rideDetail;
  List<RideMember> _members = [];
  bool _isStarting = false;
  bool _followMe = true;
  Timer? _membersPollTimer;
  Timer? _smoothTimer;
  Timer? _heartbeatTimer;

  // Destination & Route State
  String? _destName;
  LatLng? _destPoint;
  RideRouteResult? _routeResult;
  bool _isCalculatingRoute = false;
  bool _pickMode = false;
  LatLng? _pickedPoint;
  String? _pickedName;
  RideRouteResult? _previewRoute;
  bool _previewUnavailable = false;
  Timer? _previewDebounce;

  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  StreamSubscription<Position>? _locationSubscription;

  late final RideStateNotifier _rideNotifier;
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
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _tickSmooth();
    });
    _initRide();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _membersPollTimer?.cancel();
    _smoothTimer?.cancel();
    _heartbeatTimer?.cancel();
    ref.read(wsManagerProvider).disconnect();
    _wsSubscription?.cancel();
    _locationSubscription?.cancel();

    if (_permanentLeave) {
      Future.microtask(_rideNotifier.clear);
    }
    super.dispose();
  }

  Future<void> _initRide() async {
    final locationService = ref.read(locationServiceProvider);
    final ws = ref.read(wsManagerProvider);

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

    _locationSubscription = locationService.getPositionStream().listen((
      position,
    ) {
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPos;
        _myHeading = position.heading;
        _mySpeed = position.speed;
      });

      if (_followMe) _mapController.move(newPos, _mapController.camera.zoom);

      // Re-route OSRM hanya jika melenceng > 500m dari awal rute saat ini.
      if (_destPoint != null &&
          _routeResult != null &&
          _routeResult!.points.isNotEmpty) {
        final dist = const Distance().as(
          LengthUnit.Meter,
          _routeResult!.points.first,
          newPos,
        );
        if (dist > 500) {
          _refreshRoute();
        }
      } else if (_destPoint != null && _routeResult == null) {
        _refreshRoute();
      }

      _sendLocation(
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
        speed: position.speed,
      );
    });
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
          _destName = detail.destName;
          if (detail.destLat != null && detail.destLng != null) {
            _destPoint = LatLng(detail.destLat!, detail.destLng!);
          }
        });
        _refreshRoute();
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
        _onDestinationReceived(name, LatLng(lat, lng));
      }
      return;
    }

    if (type == 'destination_cleared') {
      _onDestinationCleared(notify: true);
      return;
    }

    if (type == 'member_joined' || type == 'member_left') {
      if (type == 'member_left') {
        final gone = data['user_id'] as String?;
        if (gone != null) {
          _otherRiders.remove(gone);
          _smoothRiders.remove(gone);
        }
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

    _otherRiders[userId] = RiderLocation(
      userId: userId,
      position: LatLng(lat, lng),
      heading: heading,
      speed: speed,
    );
    _smoothRiders.putIfAbsent(userId, () => _otherRiders[userId]!);
  }

  void _tickSmooth() {
    if (!mounted || _otherRiders.isEmpty) return;
    var changed = false;
    final next = <String, RiderLocation>{};
    _otherRiders.forEach((id, target) {
      final cur = _smoothRiders[id];
      if (cur == null) {
        next[id] = target;
        changed = true;
        return;
      }
      final lat =
          cur.position.latitude +
          (target.position.latitude - cur.position.latitude) * 0.3;
      final lng =
          cur.position.longitude +
          (target.position.longitude - cur.position.longitude) * 0.3;
      final dLat = (target.position.latitude - lat).abs();
      final dLng = (target.position.longitude - lng).abs();
      if (dLat < 1e-7 && dLng < 1e-7) {
        next[id] = target;
      } else {
        next[id] = cur.copyWith(
          position: LatLng(lat, lng),
          heading: target.heading,
          speed: target.speed,
        );
        changed = true;
      }
      if ((cur.heading - target.heading).abs() > 0.5 ||
          (cur.speed - target.speed).abs() > 0.1) {
        changed = true;
      }
    });
    if (_smoothRiders.length != next.length) changed = true;
    if (changed) {
      setState(() {
        _smoothRiders
          ..clear()
          ..addAll(next);
      });
    }
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
    ref.read(wsManagerProvider).send({
      'type': 'location_update',
      'ride_id': widget.rideId,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': speed,
    });
  }

  void _onDestinationReceived(String name, LatLng point) {
    if (!mounted) return;
    // Skip kalau sama dengan yang sudah tampil (misal echo broadcast dari
    // device host sendiri setelah set tujuan).
    if (_destName == name &&
        _destPoint != null &&
        (_destPoint!.latitude - point.latitude).abs() < 1e-9 &&
        (_destPoint!.longitude - point.longitude).abs() < 1e-9) {
      return;
    }
    setState(() {
      _destName = name;
      _destPoint = point;
      if (_rideDetail != null) {
        _rideDetail = _rideDetail!.copyWith(
          destName: name,
          destLat: point.latitude,
          destLng: point.longitude,
        );
      }
    });
    _refreshRoute();
    AppToast.info(context, 'Tujuan diset ke: $name');
  }

  void _onDestinationCleared({bool notify = false}) {
    if (!mounted) return;
    setState(() {
      _destName = null;
      _destPoint = null;
      _routeResult = null;
      if (_rideDetail != null) {
        _rideDetail = RideModel(
          id: _rideDetail!.id,
          ownerId: _rideDetail!.ownerId,
          name: _rideDetail!.name,
          inviteCode: _rideDetail!.inviteCode,
          status: _rideDetail!.status,
        );
      }
    });
    if (notify) {
      AppToast.info(context, 'Tujuan konvoi dihapus oleh Room Master');
    }
  }

  Future<void> _handleClearDestination() async {
    try {
      final repo = ref.read(rideRepositoryProvider);
      await repo.clearDestination(widget.rideId);
      _onDestinationCleared();
      if (mounted) {
        AppToast.success(context, 'Tujuan berhasil dihapus');
      }
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal menghapus tujuan: $e');
    }
  }

  Future<void> _refreshRoute() async {
    final dest = _destPoint;
    final start = _currentPosition;
    if (dest == null || start == null || _isCalculatingRoute) return;

    setState(() => _isCalculatingRoute = true);
    final route = await _routeService.getRoute(
      start: start,
      destination: dest,
    );
    if (mounted) {
      setState(() {
        _routeResult = route;
        _isCalculatingRoute = false;
      });
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
        currentDestName: _destName,
        currentLat: _destPoint?.latitude,
        currentLng: _destPoint?.longitude,
        routeDistance: _routeResult?.distanceFormatted,
        routeDuration: _routeResult?.durationFormatted,
        onSelectDestination: (name, lat, lng) async {
          await _handleSetDestination(name, LatLng(lat, lng));
        },
        onPickOnMap: _isHost ? _startPickMode : null,
        onClearDestination: _isHost && _destName != null
            ? _handleClearDestination
            : null,
      ),
    );
  }

  void _startPickMode() {
    setState(() {
      _pickMode = true;
      _pickedPoint = null;
      _pickedName = null;
      _previewRoute = null;
      _previewUnavailable = false;
    });
  }

  Future<void> _onMapTap(LatLng point) async {
    if (!_pickMode || !_isHost) return;
    setState(() {
      _pickedPoint = point;
      _pickedName = 'Memuat nama lokasi…';
      _previewRoute = null;
      _previewUnavailable = false;
    });
    final name = await _routeService.reverseGeocode(point);
    if (!mounted || _pickedPoint != point) return;
    setState(() => _pickedName = name);
    _schedulePreviewFetch(point);
  }

  void _schedulePreviewFetch(LatLng point) {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 400), () async {
      final start = _currentPosition;
      if (!mounted || start == null) {
        if (mounted) setState(() => _previewUnavailable = true);
        return;
      }
      final route = await _routeService.getRoute(
        start: start,
        destination: point,
      );
      if (!mounted || _pickedPoint != point) return;
      setState(() {
        _previewRoute = route;
        _previewUnavailable = route == null || route.points.isEmpty;
      });
    });
  }

  void _cancelPick() {
    _previewDebounce?.cancel();
    setState(() {
      _pickMode = false;
      _pickedPoint = null;
      _pickedName = null;
      _previewRoute = null;
      _previewUnavailable = false;
    });
  }

  Future<void> _applyPickedPoint() async {
    final point = _pickedPoint;
    if (point == null) return;
    final name = _pickedName?.isNotEmpty == true
        ? _pickedName!
        : 'Titik Terpilih';
    final preview = _previewRoute;
    _previewDebounce?.cancel();
    setState(() {
      _pickMode = false;
      _pickedPoint = null;
      _pickedName = null;
      _previewRoute = null;
      _previewUnavailable = false;
    });
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
      if (mounted) {
        setState(() {
          _destName = name;
          _destPoint = point;
          if (previewRoute != null) {
            _routeResult = previewRoute;
          }
          if (_rideDetail != null) {
            _rideDetail = _rideDetail!.copyWith(
              destName: name,
              destLat: point.latitude,
              destLng: point.longitude,
            );
          }
        });
        if (previewRoute == null) {
          _refreshRoute();
        }
        AppToast.success(context, 'Tujuan berhasil diperbarui');
      }
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal mengubah tujuan: $e');
    }
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
    final rider = _smoothRiders[member.userId] ?? _otherRiders[member.userId];
    if (rider == null) {
      if (mounted) {
        AppToast.info(context, '${member.name} belum mengirim lokasi.');
      }
      return;
    }
    setState(() => _followMe = false);
    _mapController.move(rider.position, _mapController.camera.zoom.clamp(16.0, 17.0));
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
    final action = await showDialog<String>(
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
            onPressed: () {
              Navigator.pop(ctx);
              _confirmLeaveOrEnd();
            },
            child: Text(_isHost
                ? (_rideStatus == 'planned' ? 'Batalkan Room' : 'Selesaikan')
                : 'Keluar Room'),
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
    if (action == 'home' && mounted) Navigator.pop(context);
  }

  Future<void> _confirmLeaveOrEnd() async {
    final isHost = _isHost;
    final isPlanned = _rideStatus == 'planned';

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

    if (ok == true && mounted) {
      _permanentLeave = true;
      try {
        final repo = ref.read(rideRepositoryProvider);
        if (isHost) {
          if (isPlanned) {
            await repo.cancelRide(widget.rideId);
          } else {
            await repo.endRide(widget.rideId);
          }
        } else {
          await repo.leaveRide(widget.rideId);
        }
      } catch (_) {
        // Abaikan error jaringan saat keluar
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = buildRideMarkers(
      currentPosition: _currentPosition,
      currentHeading: _myHeading,
      currentIsMoving: _mySpeed > 0.8,
      otherRiders: _smoothRiders.isNotEmpty ? _smoothRiders : _otherRiders,
      names: _memberNames,
      destinationPoint: _pickedPoint ?? _destPoint,
      destinationName: _pickedPoint != null ? _pickedName : _destName,
      destinationIsPreview: _pickedPoint != null,
    );
    final riderCount = _members.isNotEmpty
        ? _members.length
        : (_otherRiders.length + (_currentPosition != null ? 1 : 0));
    final isPlanned = _rideStatus == 'planned';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmBackAction();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Kembali ke Beranda',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink,
              size: 20,
            ),
            onPressed: _confirmBackAction,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPlanned ? AppColors.accentSoft : AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusDot(live: !isPlanned),
                    const SizedBox(width: 5),
                    Text(
                      isPlanned ? 'LOBBY' : 'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isPlanned
                            ? AppColors.accent
                            : AppColors.brandDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _displayName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            // Button list peserta (kiri dari QR icon)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Daftar Peserta',
                  icon: const Icon(
                    Icons.people_alt_outlined,
                    color: AppColors.ink,
                  ),
                  onPressed: _showMembersSheet,
                ),
                if (_members.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_members.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              tooltip: 'Undang',
              icon: const Icon(Icons.qr_code_2, color: AppColors.ink),
              onPressed: _showInviteQr,
            ),
          ],
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
                ),
                if (_previewRoute != null && _previewRoute!.points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _previewRoute!.points,
                        strokeWidth: 5.0,
                        color: AppColors.ink.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                if (_routeResult != null && _routeResult!.points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routeResult!.points,
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
            if (isPlanned)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHost
                                    ? 'Semua rider siap?'
                                    : 'Menunggu Room Master',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                _isHost
                                    ? 'Tekan "Mulai Perjalanan" di bawah buat gas.'
                                    : 'Konvoi mulai otomatis pas host menekan tombol.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_pickMode)
              Positioned(
                left: 14,
                right: 72,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _pickedPoint != null
                                  ? AppColors.brandSoft
                                  : AppColors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              _pickedPoint != null
                                  ? Icons.place_rounded
                                  : Icons.touch_app_rounded,
                              color: _pickedPoint != null
                                  ? AppColors.brand
                                  : AppColors.muted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _pickedPoint != null
                                      ? (_pickedName ??
                                          'Memuat nama lokasi…')
                                      : 'Mode Pilih Tujuan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  _pickedPoint != null
                                      ? (_previewRoute != null
                                          ? '${_previewRoute!.distanceFormatted} • ${_previewRoute!.durationFormatted}'
                                          : (_previewUnavailable
                                              ? 'Jalan tidak terdeteksi'
                                              : 'Menghitung rute…'))
                                      : 'Ketuk sembarang titik di peta',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _previewRoute != null
                                        ? AppColors.brand
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.muted,
                                side: const BorderSide(color: AppColors.line),
                                minimumSize: const Size(0, 38),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                              onPressed: _cancelPick,
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brand,
                                disabledBackgroundColor:
                                    AppColors.surfaceMuted,
                                disabledForegroundColor: AppColors.muted,
                                minimumSize: const Size(0, 38),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                              onPressed: _pickedPoint != null
                                  ? _applyPickedPoint
                                  : null,
                              child: const Text(
                                'Jadikan Tujuan',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                         ],
                       ),
                     ],
                   ),
                 ),
               ),
             if (!isPlanned)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusDot(live: true, small: true),
                          const SizedBox(width: 7),
                          Text(
                            '$riderCount rider • live tracking',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!_pickMode && (_destName != null || _isHost))
              Positioned(
                left: 14,
                right: 72,
                bottom: _destName != null && _routeResult != null ? 56 : 14,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () {
                      if (_destPoint != null) {
                        setState(() => _followMe = false);
                        _mapController.move(
                          _destPoint!,
                          _mapController.camera.zoom.clamp(14.0, 16.0),
                        );
                      } else {
                        _showDestinationSheet();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            color: AppColors.warn,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _destName ?? 'Belum ada tujuan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  _routeResult != null
                                      ? '${_routeResult!.distanceFormatted} • ${_routeResult!.durationFormatted} dari posisimu'
                                      : (_isHost
                                          ? 'Ketuk untuk atur titik finish konvoi'
                                          : 'Tap pin untuk lacak arah tujuan'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _routeResult != null
                                        ? AppColors.brand
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isCalculatingRoute)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_isHost && _destName != null)
                            IconButton(
                              tooltip: 'Hapus tujuan',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.warn,
                                size: 20,
                              ),
                              onPressed: _handleClearDestination,
                            )
                          else
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapFab(
                    tooltip: _followMe ? 'Ikuti saya: ON' : 'Ikuti saya',
                    icon: _followMe
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    active: _followMe,
                    onTap: () {
                      setState(() => _followMe = true);
                      if (_currentPosition != null) {
                        _mapController.move(
                          _currentPosition!,
                          _mapController.camera.zoom.clamp(14.0, 17.0),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _MapFab(
                    tooltip: 'Zoom in',
                    icon: Icons.add_rounded,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      (_mapController.camera.zoom + 1).clamp(5.0, 18.0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MapFab(
                    tooltip: 'Zoom out',
                    icon: Icons.remove_rounded,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      (_mapController.camera.zoom - 1).clamp(5.0, 18.0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MapFab(
                    tooltip: _destName != null ? 'Tujuan konvoi' : 'Atur tujuan',
                    icon: Icons.flag_rounded,
                    active: _destName != null,
                    onTap: _showDestinationSheet,
                  ),
                ],
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

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.live, this.small = false});
  final bool live;
  final bool small;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween(
    begin: 1.0,
    end: 0.35,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.small ? 7 : 8,
      height: widget.small ? 7 : 8,
      decoration: BoxDecoration(
        color: widget.live ? AppColors.brand : AppColors.accent,
        shape: BoxShape.circle,
      ),
    );
    if (!widget.live) return dot;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(opacity: _opacity.value, child: dot),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.brand : Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: active ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

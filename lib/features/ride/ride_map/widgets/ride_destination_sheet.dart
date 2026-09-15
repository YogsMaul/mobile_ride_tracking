import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/service/route_service.dart';
import '../../../../core/theme/app_theme.dart';

class RideDestinationSheet extends StatefulWidget {
  final bool isHost;
  final String? currentDestName;
  final double? currentLat;
  final double? currentLng;
  final String? routeDistance;
  final String? routeDuration;
  final Future<void> Function(String name, double lat, double lng) onSelectDestination;
  final VoidCallback? onPickOnMap;
  final Future<void> Function()? onClearDestination;

  const RideDestinationSheet({
    super.key,
    required this.isHost,
    this.currentDestName,
    this.currentLat,
    this.currentLng,
    this.routeDistance,
    this.routeDuration,
    required this.onSelectDestination,
    this.onPickOnMap,
    this.onClearDestination,
  });

  @override
  State<RideDestinationSheet> createState() => _RideDestinationSheetState();
}

class _RideDestinationSheetState extends State<RideDestinationSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final RouteService _routeService = RouteService();
  Timer? _debounce;
  bool _isSearching = false;
  bool _isSubmitting = false;
  List<PlaceSearchResult> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final places = await _routeService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _results = places;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _pickPlace(PlaceSearchResult place) async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onSelectDestination(
        place.shortName,
        place.lat,
        place.lng,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      // Ditangani oleh caller
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrent = widget.currentDestName != null &&
        widget.currentDestName!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: AppColors.brand,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tujuan Konvoi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          widget.isHost
                              ? 'Cari atau atur lokasi akhir rute konvoi'
                              : 'Titik finish yang ditetapkan Room Master',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasCurrent) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        color: AppColors.warn,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.currentDestName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            if (widget.routeDistance != null ||
                                widget.routeDuration != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${widget.routeDistance ?? ''}${widget.routeDistance != null && widget.routeDuration != null ? ' • ' : ''}${widget.routeDuration ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.isHost && widget.onClearDestination != null)
                        IconButton(
                          tooltip: 'Hapus tujuan',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.warn,
                            size: 22,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await widget.onClearDestination?.call();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (widget.isHost) ...[
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'Ketik nama kota, jalan, tempat tujuan...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onQueryChanged('');
                                },
                              )
                            : null),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.onPickOnMap != null) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onPickOnMap?.call();
                    },
                    icon: const Icon(Icons.touch_app_rounded, size: 18),
                    label: const Text(
                      'Atau ketuk langsung di peta',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: BorderSide(
                        color: AppColors.brand.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_isSubmitting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_results.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = _results[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.brandSoft,
                            radius: 16,
                            child: Icon(
                              Icons.place_rounded,
                              size: 18,
                              color: AppColors.brand,
                            ),
                          ),
                          title: Text(
                            item.shortName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          subtitle: Text(
                            item.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          onTap: () => _pickPlace(item),
                        );
                      },
                    ),
                  )
                else if (_searchCtrl.text.length >= 3 && !_isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Tempat tidak ditemukan. Coba kata kunci lain.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                  ),
              ] else if (!hasCurrent) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Room Master belum menentukan titik tujuan konvoi.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

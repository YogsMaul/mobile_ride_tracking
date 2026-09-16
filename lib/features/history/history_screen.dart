import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/models/ride_model.dart';
import '../../core/network/repository/ride_repository.dart';
import '../../core/theme/app_theme.dart';
import '../ride/ride_state.dart';
import 'ride_history_filter.dart';
import 'ride_history_item.dart';
import 'widgets/history_card.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_filter_chips.dart';
import 'widgets/history_header.dart';

/// Tab Riwayat — dengan Pagination Infinite Scroll (20 item per request).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  RideHistoryFilter _filter = RideHistoryFilter.all;
  bool _isSearching = false;
  String _query = '';

  List<RideHistoryItem> _items = [];
  bool _isLoadingFirst = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    _searchDebounce?.cancel();
    setState(() {
      if (_isSearching) {
        final hadQuery = _query.isNotEmpty;
        _isSearching = false;
        _searchCtrl.clear();
        _query = '';
        // Query kosong = list yang tampil masih list penuh -> gak perlu fetch.
        if (hadQuery) _fetchFirstPage(silent: _items.isNotEmpty);
      } else {
        _isSearching = true;
      }
    });
  }

  void _onSearchQueryChanged(String q) {
    setState(() => _query = q);
    _searchDebounce?.cancel();
    // Debounce 450ms biar gak nembak API di tiap ketikan huruf
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetchFirstPage(silent: _items.isNotEmpty);
    });
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoadingFirst) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger load saat sisa 200px sebelum mentok bawah
    if (maxScroll - currentScroll <= 200) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchFirstPage({bool silent = false}) async {
    setState(() {
      // silent = refresh di belakang layar; list lama tetap tampil,
      // tanpa full-spinner. Dipakai saat query berubah atau search ditutup.
      _isLoadingFirst = !silent;
      _items = silent ? _items : [];
      _hasMore = true;
    });

    try {
      final repo = ref.read(rideRepositoryProvider);
      final newItems = await repo.getMyRides(
        search: _query.trim(),
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted) return;
      setState(() {
        _items = newItems;
        _isLoadingFirst = false;
        _hasMore = newItems.length >= _pageSize;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFirst = false;
        _hasMore = false;
      });
    }
  }

  Future<void> _fetchNextPage() async {
    setState(() => _isLoadingMore = true);

    try {
      final repo = ref.read(rideRepositoryProvider);
      final newItems = await repo.getMyRides(
        search: _query.trim(),
        limit: _pageSize,
        offset: _items.length,
      );

      if (!mounted) return;
      setState(() {
        _items.addAll(newItems);
        _isLoadingMore = false;
        _hasMore = newItems.length >= _pageSize;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  List<RideHistoryItem> _applyFilter(List<RideHistoryItem> items) {
    final q = _query.trim().toLowerCase();
    return items.where((it) {
      final matchFilter = switch (_filter) {
        RideHistoryFilter.all => true,
        RideHistoryFilter.host => it.role == RideRole.host,
        RideHistoryFilter.joined => it.role == RideRole.joined,
        RideHistoryFilter.completed => it.status == RideStatus.completed,
      };
      if (!matchFilter) return false;
      if (q.isEmpty) return true;
      final title = it.title.toLowerCase();
      final dest = (it.destName ?? '').toLowerCase();
      return title.contains(q) || dest.contains(q);
    }).toList();
  }

  Map<String, List<RideHistoryItem>> _groupByDate(List<RideHistoryItem> items) {
    final fmt = DateFormat('EEEE, d MMM yyyy', 'id_ID');
    final map = <String, List<RideHistoryItem>>{};
    for (final it in items) {
      final key = fmt.format(it.date);
      map.putIfAbsent(key, () => []).add(it);
    }
    return map;
  }

  void _handleCardTap(RideHistoryItem item) {
    final active =
        item.status == RideStatus.active || item.status == RideStatus.planned;
    if (active) {
      _showResumeDialog(item);
      return;
    }
    Navigator.pushNamed(context, '/ride-detail', arguments: item);
  }

  Future<void> _showResumeDialog(RideHistoryItem item) async {
    final statusLabel = item.status == RideStatus.active
        ? 'berjalan'
        : 'menunggu dimulai';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lanjutkan Ride?'),
        content: Text(
          '"${item.title}" masih $statusLabel. '
          'Balik ke peta dan lanjutkan perjalanan sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref
          .read(rideStateProvider.notifier)
          .setActive(RideModel(id: item.id, name: item.title));
      Navigator.pushNamed(
        context,
        '/ride',
        arguments: {
          'rideId': item.id,
          'inviteCode': null,
          'rideName': item.title,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background_history.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: (_isLoadingFirst && !_isSearching)
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      )
                    : (_items.isEmpty && !_isSearching)
                    ? _buildEmptyState()
                    : _buildDataState(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataState() {
    final filtered = _applyFilter(_items);
    final grouped = _groupByDate(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: HistoryHeader(
            isSearching: _isSearching,
            searchController: _searchCtrl,
            onToggleSearch: _toggleSearch,
            onQueryChanged: _onSearchQueryChanged,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: HistoryFilterChips(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _isLoadingFirst && _isSearching
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.brand),
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _query.trim().isEmpty
                          ? 'Tidak ada riwayat untuk filter ini.'
                          : 'Ride "$_query" tidak ditemukan.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: () => _fetchFirstPage(silent: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
                    itemCount: grouped.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Spinner loading more di bawah
                      if (index == grouped.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        );
                      }

                      final dateKey = grouped.keys.elementAt(index);
                      final itemsOnDate = grouped[dateKey]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateKey,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            for (int i = 0; i < itemsOnDate.length; i++) ...[
                              HistoryCard(
                                item: itemsOnDate[i],
                                onTap: () => _handleCardTap(itemsOnDate[i]),
                              ),
                              if (i < itemsOnDate.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: _fetchFirstPage,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 72),
                  HistoryEmptyState(),
                  Spacer(),
                  Text(
                    'v1.0 · Ride Tracking',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  SizedBox(height: 108),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

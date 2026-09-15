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
  RideHistoryFilter _filter = RideHistoryFilter.all;

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
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _fetchFirstPage() async {
    setState(() {
      _isLoadingFirst = true;
      _items = [];
      _hasMore = true;
    });

    try {
      final repo = ref.read(rideRepositoryProvider);
      final newItems = await repo.getMyRides(
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
    return items.where((it) {
      return switch (_filter) {
        RideHistoryFilter.all => true,
        RideHistoryFilter.host => it.role == RideRole.host,
        RideHistoryFilter.joined => it.role == RideRole.joined,
        RideHistoryFilter.completed => it.status == RideStatus.completed,
      };
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
    final statusLabel =
        item.status == RideStatus.active ? 'berjalan' : 'menunggu dimulai';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
      ref.read(rideStateProvider.notifier).setActive(
            RideModel(
              id: item.id,
              name: item.title,
            ),
          );
      Navigator.pushNamed(context, '/ride', arguments: {
        'rideId': item.id,
        'inviteCode': null,
        'rideName': item.title,
      });
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
                child: _isLoadingFirst
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      )
                    : _items.isEmpty
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
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: HistoryHeader(),
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
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Tidak ada riwayat untuk filter ini.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: _fetchFirstPage,
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import 'ride_history_filter.dart';
import 'ride_history_item.dart';
import 'ride_history_provider.dart';
import 'widgets/history_card.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_filter_chips.dart';
import 'widgets/history_header.dart';

/// Tab Riwayat — visual terikat `background_history.png`.
/// Data dari GET /rides/me (real API), fallback empty state kalau error/kosong.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  RideHistoryFilter _filter = RideHistoryFilter.all;

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

  /// Kelompokkan per tanggal: key = formatted string "Senin, 8 Sep 2026"
  Map<String, List<RideHistoryItem>> _groupByDate(List<RideHistoryItem> items) {
    final fmt = DateFormat('EEEE, d MMM yyyy', 'id_ID');
    final map = <String, List<RideHistoryItem>>{};
    for (final it in items) {
      final key = fmt.format(it.date);
      map.putIfAbsent(key, () => []).add(it);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(rideHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background asset (spec 5: BoxFit.cover, topCenter).
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
                child: historyAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  ),
                  error: (_, _) => _buildEmptyState(),
                  data: (items) =>
                      items.isEmpty ? _buildEmptyState() : _buildDataState(items),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataState(List<RideHistoryItem> allItems) {
    final filtered = _applyFilter(allItems);
    final grouped = _groupByDate(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed: header + filter tidak ikut scroll.
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
        // Scrollable: hanya daftar card.
        Expanded(
          child: grouped.isEmpty
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
                  onRefresh: () async {
                    ref.invalidate(rideHistoryProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
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
                                onTap: () => AppToast.info(
                                  context,
                                  'Detail "${itemsOnDate[i].title}" segera hadir.',
                                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 72),
          const HistoryEmptyState(),
          const Spacer(),
          Text(
            'v1.0 · Ride Tracking',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 108),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../ride_history_filter.dart';

class HistoryFilterChips extends StatelessWidget {
  const HistoryFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final RideHistoryFilter selected;
  final ValueChanged<RideHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final f in RideHistoryFilter.values) ...[
            _FilterChip(label: f.label, selected: f == selected, onTap: () => onChanged(f)),
            if (f != RideHistoryFilter.values.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.brand : AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13.5,
                  color: selected ? Colors.white : AppColors.brand,
                ),
          ),
        ),
      ),
    );
  }
}

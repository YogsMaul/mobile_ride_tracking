import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RideMapAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RideMapAppBar({
    super.key,
    required this.isPlanned,
    required this.title,
    required this.memberCount,
    required this.onBack,
    required this.onShowMembers,
    required this.onShowInvite,
  });

  final bool isPlanned;
  final String title;
  final int memberCount;
  final VoidCallback onBack;
  final VoidCallback onShowMembers;
  final VoidCallback onShowInvite;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
        onPressed: onBack,
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
                RideStatusDot(live: !isPlanned),
                const SizedBox(width: 5),
                Text(
                  isPlanned ? 'LOBBY' : 'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isPlanned ? AppColors.accent : AppColors.brandDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Daftar Peserta',
              icon: const Icon(Icons.people_alt_outlined, color: AppColors.ink),
              onPressed: onShowMembers,
            ),
            if (memberCount > 0)
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
                    '$memberCount',
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
          onPressed: onShowInvite,
        ),
      ],
    );
  }
}

class RideStatusDot extends StatefulWidget {
  const RideStatusDot({super.key, required this.live, this.small = false});
  final bool live;
  final bool small;

  @override
  State<RideStatusDot> createState() => _RideStatusDotState();
}

class _RideStatusDotState extends State<RideStatusDot>
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

import 'package:flutter/material.dart';

import '../../../../core/network/models/ride_member_model.dart';
import '../../../../core/theme/app_theme.dart';

class RideMembersSheet extends StatelessWidget {
  final List<RideMember> members;
  final String roomName;
  final String inviteCode;
  final String status;
  final VoidCallback onInvite;
  final String? myUserId;
  final void Function(RideMember member)? onLocate;

  const RideMembersSheet({
    super.key,
    required this.members,
    required this.roomName,
    required this.inviteCode,
    required this.status,
    required this.onInvite,
    this.myUserId,
    this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    final isPlanned = status == 'planned';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header room & status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kode Room: $inviteCode',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPlanned ? AppColors.accentSoft : AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isPlanned ? 'LOBBY' : 'AKTIF',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPlanned ? AppColors.accent : AppColors.brandDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section title: Daftar Peserta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peserta (${members.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Undang'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.brand,
                ),
              ),
            ],
          ),
          const Divider(height: 12),

          // List peserta
          Flexible(
            child: members.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada peserta lain.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final m = members[index];
                      final isRoomMaster = m.isHost;

                      final isMe = m.userId == myUserId;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        enabled: !isMe && onLocate != null,
                        onTap: (!isMe && onLocate != null)
                            ? () {
                                Navigator.pop(context);
                                onLocate!(m);
                              }
                            : null,
                        leading: CircleAvatar(
                          backgroundColor: isRoomMaster
                              ? AppColors.brand
                              : AppColors.surface,
                          foregroundColor: isRoomMaster
                              ? Colors.white
                              : AppColors.ink,
                          child: Text(
                            m.name.isNotEmpty
                                ? m.name.substring(0, 1).toUpperCase()
                                : 'R',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isRoomMaster) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSoft,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: AppColors.brand.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Text(
                                  'Room Master',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandDark,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          isRoomMaster
                              ? 'Pembuat room'
                              : 'Anggota ride',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        trailing: isMe
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.brand,
                                size: 16,
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: AppColors.brand,
                                size: 20,
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

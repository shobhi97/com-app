import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../invite/domain/invite_entities.dart';
import '../../../invite/presentation/providers/invite_providers.dart';

class ManageInvitesScreen extends ConsumerWidget {
  const ManageInvitesScreen({super.key});

  Color _statusColor(InviteStatus status) => switch (status) {
        InviteStatus.pending => AppColors.infoBlue,
        InviteStatus.redeemed => AppColors.bullGreen,
        InviteStatus.expired => AppColors.textSecondaryDark,
        InviteStatus.revoked => AppColors.bearRed,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(adminInvitesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Invites')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('New invite'),
        onPressed: () async {
          final repo = ref.read(inviteRepositoryProvider);
          final result = await repo.createInvite();
          result.fold(
            (failure) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(failure.message))),
            (invite) {
              ref.invalidate(adminInvitesListProvider);
              Share.share(
                'You\'re invited to TickBell 🔔\nUse code: ${invite.code}\n'
                'Valid until ${DateFormat('d MMM yyyy').format(invite.expiresAt)}.',
              );
            },
          );
        },
      ),
      body: invitesAsync.when(
        data: (invites) {
          if (invites.isEmpty) {
            return Center(
              child: Text('No invites created yet', style: Theme.of(context).textTheme.titleMedium),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: invites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final invite = invites[index];
              return Card(
                child: ListTile(
                  title: Text(invite.code, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                  subtitle: Text('Expires ${DateFormat('d MMM yyyy, hh:mm a').format(invite.expiresAt)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(invite.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          invite.status.name.toUpperCase(),
                          style: TextStyle(color: _statusColor(invite.status), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (invite.status == InviteStatus.pending)
                        IconButton(
                          icon: const Icon(Icons.block_rounded, size: 20),
                          onPressed: () async {
                            await ref.read(inviteRepositoryProvider).revokeInvite(invite.id);
                            ref.invalidate(adminInvitesListProvider);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load invites: $e')),
      ),
    );
  }
}

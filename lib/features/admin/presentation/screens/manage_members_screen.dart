import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../data/member_repository.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) => MemberRepositoryImpl());
final membersListProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final result = await ref.watch(memberRepositoryProvider).listMembers();
  return result.fold((f) => throw f, (list) => list);
});

class ManageMembersScreen extends ConsumerWidget {
  const ManageMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Members')),
      body: membersAsync.when(
        data: (members) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final m = members[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                  backgroundColor: AppColors.surfaceElevatedDark,
                  child: m.avatarUrl == null ? Text(m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?') : null,
                ),
                title: Text(m.displayName),
                subtitle: Text(m.email),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    final repo = ref.read(memberRepositoryProvider);
                    if (value == 'toggle_active') {
                      await repo.setActive(m.id, !m.isActive);
                    } else {
                      await repo.updateRole(m.id, UserRoleX.fromString(value));
                    }
                    ref.invalidate(membersListProvider);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'toggle_active', child: Text(m.isActive ? 'Deactivate' : 'Activate')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'member', child: Text('Set role: Member')),
                    const PopupMenuItem(value: 'moderator', child: Text('Set role: Moderator')),
                    const PopupMenuItem(value: 'admin', child: Text('Set role: Admin')),
                  ],
                  child: Chip(
                    label: Text(m.role.label),
                    backgroundColor: m.isActive
                        ? AppColors.accentGold.withOpacity(0.15)
                        : AppColors.bearRed.withOpacity(0.15),
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load members: $e')),
      ),
    );
  }
}

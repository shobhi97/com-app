import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surfaceElevatedDark,
                  backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(profile.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark)),
                const SizedBox(height: 12),
                Chip(
                  label: Text(profile.role.label),
                  backgroundColor: AppColors.accentGold.withOpacity(0.15),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Member since', value: DateFormat('d MMM yyyy').format(profile.createdAt)),
                        const Divider(height: 24, color: AppColors.divider),
                        _InfoRow(
                          label: 'Last active',
                          value: profile.lastSeenAt != null
                              ? DateFormat('d MMM yyyy, hh:mm a').format(profile.lastSeenAt!)
                              : '—',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (profile.role.canAccessAdminPanel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin panel'),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/profile/edit'),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit profile'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

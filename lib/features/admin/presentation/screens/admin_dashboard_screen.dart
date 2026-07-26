import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileStreamProvider).valueOrNull;
    final role = profile?.role ?? UserRole.member;

    final tiles = <_AdminTile>[
      _AdminTile(
        icon: Icons.person_rounded,
        title: 'My Profile',
        subtitle: 'View and edit your profile',
        route: '/profile',
      ),
      _AdminTile(
        icon: Icons.settings_rounded,
        title: 'Settings',
        subtitle: 'Security, legal, and account',
        route: '/settings',
      ),
      if (role.canManageSessions)
        _AdminTile(
          icon: Icons.add_alert_rounded,
          title: 'Ring a Bell',
          subtitle: 'Push a live trade alert to every member',
          route: '/admin/send-bell',
        ),
      if (role.canManageSessions)
        _AdminTile(
          icon: Icons.video_call_rounded,
          title: 'Schedule Session',
          subtitle: 'Create a Google Meet room for members',
          route: '/admin/schedule-session',
        ),
      if (role.canManageInvites)
        _AdminTile(
          icon: Icons.vpn_key_rounded,
          title: 'Manage Invites',
          subtitle: 'Generate and track invite codes',
          route: '/admin/invites',
        ),
      if (role.canManageInvites)
        _AdminTile(
          icon: Icons.group_rounded,
          title: 'Manage Members',
          subtitle: 'Roles, activation status, and removal',
          route: '/admin/members',
        ),
      if (role == UserRole.owner || role == UserRole.admin)
        _AdminTile(
          icon: Icons.campaign_rounded,
          title: 'Announcements',
          subtitle: 'Broadcast a general notice to the room',
          route: '/admin/announcements',
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = tiles[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(t.icon, color: AppColors.accentGold),
              ),
              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(t.subtitle, style: const TextStyle(color: AppColors.textSecondaryDark)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pushNamed(t.route),
            ),
          );
        },
      ),
    );
  }
}

class _AdminTile {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  _AdminTile({required this.icon, required this.title, required this.subtitle, required this.route});
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/secure_storage/secure_storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../legal/presentation/screens/legal_menu_screen.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());

final biometricEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final value = await storage.read(AppConstants.keyBiometricEnabled);
  return value == 'true';
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleBiometric(BuildContext context, WidgetRef ref, bool enable) async {
    final localAuth = LocalAuthentication();
    if (enable) {
      final canCheck = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
      if (!canCheck) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication is not available on this device.')),
          );
        }
        return;
      }
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Confirm it\'s you to enable app lock',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (!authenticated) return;
    }
    await ref.read(secureStorageProvider).write(AppConstants.keyBiometricEnabled, enable.toString());
    ref.invalidate(biometricEnabledProvider);
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your TickBell profile, bells history, and membership. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.bearRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref.read(authRepositoryProvider).deleteAccount();
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAsync = ref.watch(biometricEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Security'),
          Card(
            child: biometricAsync.when(
              data: (enabled) => SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('App lock (biometric)'),
                subtitle: const Text('Require Face/Fingerprint unlock to open TickBell'),
                value: enabled,
                onChanged: (v) => _toggleBiometric(context, ref, v),
              ),
              loading: () => const ListTile(title: Text('App lock'), trailing: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const ListTile(title: Text('App lock unavailable')),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.gavel_rounded),
                  title: const Text('Legal (Privacy, Terms, Risk)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LegalMenuScreen()),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) => ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('App version'),
                    trailing: Text(snapshot.hasData ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})' : '—'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () => ref.read(authControllerProvider.notifier).signOut(),
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.bearRed),
                  title: const Text('Delete account', style: TextStyle(color: AppColors.bearRed)),
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

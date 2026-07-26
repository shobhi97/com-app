import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/invite/presentation/screens/redeem_invite_screen.dart';
import 'features/profile/presentation/screens/profile_setup_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/legal/presentation/screens/legal_acceptance_flow_screen.dart';
import 'features/home/presentation/screens/home_shell.dart';
import 'features/home/presentation/screens/splash_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/send_bell_screen.dart';
import 'features/admin/presentation/screens/schedule_session_screen.dart';
import 'features/admin/presentation/screens/manage_invites_screen.dart';
import 'features/admin/presentation/screens/manage_members_screen.dart';
import 'features/admin/presentation/screens/announcements_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'core/services/secure_storage/secure_storage_service.dart';

class TickBellApp extends ConsumerStatefulWidget {
  const TickBellApp({super.key});

  @override
  ConsumerState<TickBellApp> createState() => _TickBellAppState();
}

class _TickBellAppState extends ConsumerState<TickBellApp> with WidgetsBindingObserver {
  bool _locked = false;
  bool _checkedLockOnLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock whenever the app returns from background, if the user has
    // enabled biometric app-lock in Settings.
    if (state == AppLifecycleState.resumed && _checkedLockOnLaunch) {
      _maybeLock();
    }
  }

  Future<void> _maybeLock() async {
    final storage = SecureStorageService();
    final enabled = await storage.read(AppConstants.keyBiometricEnabled) == 'true';
    if (enabled && mounted) {
      setState(() => _locked = true);
    }
  }

  Future<void> _unlock() async {
    final localAuth = LocalAuthentication();
    try {
      final ok = await localAuth.authenticate(
        localizedReason: 'Unlock TickBell',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {
      // Device may not support biometrics — fail safe by leaving it locked
      // and letting the user retry rather than silently bypassing the lock.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedLockOnLaunch) {
      _checkedLockOnLaunch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLock());
    }

    return MaterialApp(
      title: 'TickBell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: _locked ? _LockScreen(onUnlock: _unlock) : const _AuthGate(),
      routes: {
        '/profile/edit': (_) => const ProfileSetupScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/admin/send-bell': (_) => const SendBellScreen(),
        '/admin/schedule-session': (_) => const ScheduleSessionScreen(),
        '/admin/invites': (_) => const ManageInvitesScreen(),
        '/admin/members': (_) => const ManageMembersScreen(),
        '/admin/announcements': (_) => const AnnouncementsScreen(),
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimaryDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.accentGold, size: 48),
            const SizedBox(height: 16),
            const Text('TickBell is locked', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Central router based on live auth/profile state. Keeps navigation logic
/// declarative: as the profile stream changes (invite redeemed, legal
/// accepted, role changed) this rebuilds and swaps the screen automatically.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authStatusProvider);

    return switch (status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.signedOut => const LoginScreen(),
      AuthStatus.needsInvite => const RedeemInviteScreen(),
      AuthStatus.needsProfileSetup => const ProfileSetupScreen(),
      AuthStatus.needsLegalAcceptance => const LegalAcceptanceFlowScreen(),
      AuthStatus.ready => const HomeShell(),
    };
  }
}

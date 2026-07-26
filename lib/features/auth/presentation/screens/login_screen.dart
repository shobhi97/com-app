import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('AuthFailure(', '').replaceAll(')', '')),
              backgroundColor: AppColors.bearRed.withOpacity(0.15),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              _BellMark().animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'TickBell',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                'Invite-only room for live options discussions',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondaryDark),
              ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
              const Spacer(flex: 2),
              _FeatureRow(icon: Icons.notifications_active_rounded, label: 'Real-time bell alerts on every call'),
              const SizedBox(height: 14),
              _FeatureRow(icon: Icons.video_call_rounded, label: 'Live Google Meet rooms, one tap to join'),
              const SizedBox(height: 14),
              _FeatureRow(icon: Icons.lock_rounded, label: 'Private, invite-only membership'),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                        )
                      : const Icon(Icons.g_mobiledata_rounded, size: 26),
                  label: Text(isLoading ? 'Signing in...' : 'Continue with Google'),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15, end: 0),
              const SizedBox(height: 16),
              Text(
                'By continuing you agree to our Terms, Privacy Policy, and Risk Disclosure. '
                'TickBell does not provide investment advice.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentGold.withOpacity(0.4), width: 1.5),
      ),
      child: const Icon(Icons.notifications_active_rounded, color: AppColors.accentGold, size: 42),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.accentGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

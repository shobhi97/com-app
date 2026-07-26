import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/bell_providers.dart';
import '../widgets/bell_card.dart';

class BellFeedScreen extends ConsumerWidget {
  const BellFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bellsAsync = ref.watch(bellFeedProvider);
    final profileAsync = ref.watch(currentProfileStreamProvider);
    final canSendBell = profileAsync.valueOrNull?.role.canManageSessions ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bells'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(bellFeedProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: canSendBell
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed('/admin/send-bell'),
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Ring Bell'),
            )
          : null,
      body: bellsAsync.when(
        data: (bells) {
          if (bells.isEmpty) {
            return _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(bellFeedProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bells.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => BellCard(bell: bells[index], index: index),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(bellFeedProvider),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textSecondaryDark),
            const SizedBox(height: 16),
            Text(
              'No bells yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Live trade alerts from the room will appear here the moment they\'re rung.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.bearRed),
            const SizedBox(height: 16),
            Text('Could not load bells', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

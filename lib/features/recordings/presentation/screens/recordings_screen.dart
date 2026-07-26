import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../meet/presentation/providers/session_providers.dart';

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recording Library')),
      body: sessionsAsync.when(
        data: (sessions) {
          final recorded = sessions.where((s) => s.recordingUrl != null).toList()
            ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

          if (recorded.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.movie_filter_outlined, size: 56, color: AppColors.textSecondaryDark),
                  const SizedBox(height: 16),
                  Text('No recordings yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Recordings of past live sessions will show up here once uploaded by an admin.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recorded.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final s = recorded[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.accentGold),
                  ),
                  title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormat('EEE, d MMM yyyy').format(s.scheduledStart)),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: () async {
                    final uri = Uri.parse(s.recordingUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load recordings: $e')),
      ),
    );
  }
}

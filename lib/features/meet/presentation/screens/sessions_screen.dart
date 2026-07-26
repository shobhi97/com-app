import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/session_entities.dart';
import '../providers/session_providers.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  Future<void> _joinMeet(BuildContext context, LiveSession session) async {
    final uri = Uri.parse(session.meetLink);
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Meet. Install the Meet app or check the link.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Sessions')),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_call_outlined, size: 56, color: AppColors.textSecondaryDark),
                  const SizedBox(height: 16),
                  Text('No sessions scheduled', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = sessions[index];
              final isLive = s.status == SessionStatus.live;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.bearRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 8, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          if (isLive) const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (s.description != null) Text(s.description!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEE, d MMM · hh:mm a').format(s.scheduledStart),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
                          ),
                          const Spacer(),
                          Text('Host: ${s.hostName}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: s.isJoinable ? () => _joinMeet(context, s) : null,
                              icon: const Icon(Icons.video_call_rounded, size: 20),
                              label: Text(isLive ? 'Join now' : 'Join Meet'),
                            ),
                          ),
                          if (s.recordingUrl != null) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _joinMeet(context, LiveSession(
                                id: s.id, title: s.title, meetLink: s.recordingUrl!,
                                scheduledStart: s.scheduledStart, status: s.status,
                                hostUserId: s.hostUserId, hostName: s.hostName,
                              )),
                              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                              label: const Text('Recording'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load sessions: $e')),
      ),
    );
  }
}

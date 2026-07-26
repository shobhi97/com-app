import 'package:equatable/equatable.dart';

enum SessionStatus { scheduled, live, ended, cancelled }

class LiveSession extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String meetLink;
  final DateTime scheduledStart;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final SessionStatus status;
  final String hostUserId;
  final String hostName;
  final String? recordingUrl;

  const LiveSession({
    required this.id,
    required this.title,
    this.description,
    required this.meetLink,
    required this.scheduledStart,
    this.actualStart,
    this.actualEnd,
    required this.status,
    required this.hostUserId,
    required this.hostName,
    this.recordingUrl,
  });

  bool get isJoinable => status == SessionStatus.live || status == SessionStatus.scheduled;

  factory LiveSession.fromJson(Map<String, dynamic> json) => LiveSession(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        meetLink: json['meet_link'] as String,
        scheduledStart: DateTime.parse(json['scheduled_start'] as String),
        actualStart: json['actual_start'] != null ? DateTime.parse(json['actual_start'] as String) : null,
        actualEnd: json['actual_end'] != null ? DateTime.parse(json['actual_end'] as String) : null,
        status: SessionStatus.values.byName(json['status'] as String? ?? 'scheduled'),
        hostUserId: json['host_id'] as String,
        hostName: json['host_name'] as String? ?? 'Host',
        recordingUrl: json['recording_url'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'title': title,
        'description': description,
        'meet_link': meetLink,
        'scheduled_start': scheduledStart.toIso8601String(),
        'status': status.name,
      };

  @override
  List<Object?> get props => [id, title, meetLink, scheduledStart, status];
}

import 'package:equatable/equatable.dart';

enum InviteStatus { pending, redeemed, expired, revoked }

class Invite extends Equatable {
  final String id;
  final String code;
  final String createdByUserId;
  final String? redeemedByUserId;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final String? note;

  const Invite({
    required this.id,
    required this.code,
    required this.createdByUserId,
    this.redeemedByUserId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.redeemedAt,
    this.note,
  });

  bool get isUsable => status == InviteStatus.pending && DateTime.now().isBefore(expiresAt);

  factory Invite.fromJson(Map<String, dynamic> json) => Invite(
        id: json['id'] as String,
        code: json['code'] as String,
        createdByUserId: json['created_by'] as String,
        redeemedByUserId: json['redeemed_by'] as String?,
        status: InviteStatus.values.byName(json['status'] as String? ?? 'pending'),
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        redeemedAt: json['redeemed_at'] != null ? DateTime.parse(json['redeemed_at'] as String) : null,
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props => [id, code, status, createdAt, expiresAt, redeemedAt];
}

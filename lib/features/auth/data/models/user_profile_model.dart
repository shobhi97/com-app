import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.avatarUrl,
    required super.role,
    required super.isActive,
    required super.createdAt,
    super.lastSeenAt,
    super.privacyPolicyAcceptedVersion,
    super.termsAcceptedVersion,
    super.riskDisclosureAcceptedVersion,
    super.invitedByUserId,
    super.biometricLockEnabled,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: (json['display_name'] as String?) ?? (json['email'] as String).split('@').first,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRoleX.fromString(json['role'] as String? ?? 'member'),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at'] as String) : null,
      privacyPolicyAcceptedVersion: json['privacy_policy_accepted_version'] as int?,
      termsAcceptedVersion: json['terms_accepted_version'] as int?,
      riskDisclosureAcceptedVersion: json['risk_disclosure_accepted_version'] as int?,
      invitedByUserId: json['invited_by'] as String?,
      biometricLockEnabled: json['biometric_lock_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'role': role.name,
        'is_active': isActive,
        'biometric_lock_enabled': biometricLockEnabled,
      };
}

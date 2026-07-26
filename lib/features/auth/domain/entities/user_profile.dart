import 'package:equatable/equatable.dart';

enum UserRole { owner, admin, moderator, member }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.owner => 'Owner',
        UserRole.admin => 'Admin',
        UserRole.moderator => 'Moderator',
        UserRole.member => 'Member',
      };

  static UserRole fromString(String value) => switch (value) {
        'owner' => UserRole.owner,
        'admin' => UserRole.admin,
        'moderator' => UserRole.moderator,
        _ => UserRole.member,
      };

  bool get canManageInvites => this == UserRole.owner || this == UserRole.admin;
  bool get canManageSessions =>
      this == UserRole.owner || this == UserRole.admin || this == UserRole.moderator;
  bool get canAccessAdminPanel => this != UserRole.member;
}

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final int? privacyPolicyAcceptedVersion;
  final int? termsAcceptedVersion;
  final int? riskDisclosureAcceptedVersion;
  final String? invitedByUserId;
  final bool biometricLockEnabled;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastSeenAt,
    this.privacyPolicyAcceptedVersion,
    this.termsAcceptedVersion,
    this.riskDisclosureAcceptedVersion,
    this.invitedByUserId,
    this.biometricLockEnabled = false,
  });

  bool hasAcceptedAllLegal({
    required int privacyVersion,
    required int termsVersion,
    required int riskVersion,
  }) {
    return (privacyPolicyAcceptedVersion ?? 0) >= privacyVersion &&
        (termsAcceptedVersion ?? 0) >= termsVersion &&
        (riskDisclosureAcceptedVersion ?? 0) >= riskVersion;
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    UserRole? role,
    bool? isActive,
    DateTime? lastSeenAt,
    int? privacyPolicyAcceptedVersion,
    int? termsAcceptedVersion,
    int? riskDisclosureAcceptedVersion,
    bool? biometricLockEnabled,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      privacyPolicyAcceptedVersion: privacyPolicyAcceptedVersion ?? this.privacyPolicyAcceptedVersion,
      termsAcceptedVersion: termsAcceptedVersion ?? this.termsAcceptedVersion,
      riskDisclosureAcceptedVersion: riskDisclosureAcceptedVersion ?? this.riskDisclosureAcceptedVersion,
      invitedByUserId: invitedByUserId,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        role,
        isActive,
        createdAt,
        lastSeenAt,
        privacyPolicyAcceptedVersion,
        termsAcceptedVersion,
        riskDisclosureAcceptedVersion,
        biometricLockEnabled,
      ];
}

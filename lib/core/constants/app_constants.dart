class AppConstants {
  AppConstants._();

  static const String appName = 'TickBell';
  static const String appTagline = 'Live Options Room';

  // Supabase table names
  static const String tableProfiles = 'profiles';
  static const String tableInvites = 'invites';
  static const String tableSessions = 'live_sessions';
  static const String tableBells = 'bells';
  static const String tableBellReads = 'bell_reads';
  static const String tableRecordings = 'recordings';
  static const String tableDeviceTokens = 'device_tokens';
  static const String tableAuditLog = 'audit_log';
  static const String tableRoles = 'user_roles';
  static const String tableAnnouncements = 'announcements';

  // Storage buckets
  static const String bucketAvatars = 'avatars';
  static const String bucketRecordings = 'recordings';

  // Roles
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';
  static const String roleMember = 'member';

  // Shared prefs / secure storage keys
  static const String keyDeviceId = 'device_id';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyLastFcmToken = 'last_fcm_token';
  static const String keyOnboardingSeen = 'onboarding_seen';

  // Deep link scheme
  static const String deepLinkScheme = 'tickbell';
  static const String inviteHost = 'invite';

  // Legal doc versions — bump when content changes, forces re-acceptance
  static const int privacyPolicyVersion = 1;
  static const int termsVersion = 1;
  static const int riskDisclosureVersion = 1;

  static const Duration sessionTokenRefreshBuffer = Duration(minutes: 5);
  static const int maxInviteRedemptions = 1;
  static const Duration inviteDefaultValidity = Duration(days: 7);
}

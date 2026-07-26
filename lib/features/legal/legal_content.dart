/// Centralized legal copy. Replace with your reviewed legal text before
/// release — this is structurally complete but you MUST have counsel review
/// the actual wording, since TickBell touches financial discussion content.
class LegalContent {
  static const String privacyPolicy = '''
Last updated: [DATE]

TickBell ("we", "us") operates an invite-only community app for discussing
options trading ideas over live video calls.

1. Information we collect
   • Account data: name, email, and profile photo from Google Sign-In.
   • Usage data: bells you view, sessions you join, device push token.
   • Device data: device model and OS version for crash diagnostics.

2. How we use your information
   • To operate the invite system and verify membership.
   • To deliver push notifications ("bells") and session reminders.
   • To maintain audit logs of admin actions for community safety.

3. Data sharing
   We do not sell personal data. Data is processed by our infrastructure
   providers (Supabase, Firebase/Google Cloud) strictly to operate the app.

4. Data retention
   Account data is retained while your membership is active and for a
   limited period after deactivation for audit purposes, then deleted.

5. Your rights
   You may request account deletion at any time from Settings > Delete
   Account, which triggers permanent removal of your profile data.

6. Contact
   For privacy requests, contact the community admin via the app.
''';

  static const String termsAndConditions = '''
Last updated: [DATE]

By using TickBell you agree to the following terms:

1. Invite-only membership
   Access is granted solely via a valid invite code issued by an existing
   admin or member. TickBell may revoke membership at its discretion.

2. Nature of the community
   TickBell is a private discussion forum among members. Content shared —
   including "bells" (trade alerts) and live session commentary — reflects
   the personal opinions of the poster and is NOT investment advice issued
   by TickBell as a company.

3. Prohibited conduct
   • Sharing invite codes publicly or reselling access.
   • Redistributing session recordings outside the community.
   • Harassment, spam, or market manipulation schemes.

4. No guarantee of outcomes
   Options trading carries substantial risk. Nothing shared in this app
   guarantees any financial outcome. See the Risk Disclosure for details.

5. Termination
   We may suspend or remove any member who violates these terms.

6. Limitation of liability
   TickBell and its administrators are not liable for trading losses
   incurred based on discussions in this app.
''';

  static const String riskDisclosure = '''
Last updated: [DATE]

Options trading involves substantial risk of loss and is not suitable for
all investors.

1. This is not investment advice
   All "bells", charts, and commentary shared in TickBell are for
   educational and discussion purposes only. They do not constitute
   personalized investment advice, a recommendation, or a solicitation to
   buy or sell any security or derivative.

2. Leverage risk
   Options are leveraged instruments. Small price movements in the
   underlying can result in large, rapid, and total loss of premium paid.

3. Past performance
   Past results discussed by any member, including admins, are not
   indicative of future results.

4. Independent decision-making
   You are solely responsible for your own trading decisions. Consult a
   SEBI-registered investment advisor before acting on any information
   shared in this community.

5. No liability
   TickBell, its founders, and admins accept no liability for any
   financial loss arising from reliance on content shared in this app.

By tapping "I Agree" you confirm you understand and accept these risks.
''';
}

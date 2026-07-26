import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../legal_content.dart';

/// Forces sequential acceptance of Privacy Policy -> Terms -> Risk Disclosure
/// before a newly-activated member reaches the main app. Re-triggered
/// automatically if AppConstants version numbers are bumped after an update.
class LegalAcceptanceFlowScreen extends ConsumerStatefulWidget {
  const LegalAcceptanceFlowScreen({super.key});

  @override
  ConsumerState<LegalAcceptanceFlowScreen> createState() => _LegalAcceptanceFlowScreenState();
}

class _LegalAcceptanceFlowScreenState extends ConsumerState<LegalAcceptanceFlowScreen> {
  int _step = 0;
  bool _submitting = false;

  static const _docs = [
    (title: 'Privacy Policy', content: LegalContent.privacyPolicy),
    (title: 'Terms & Conditions', content: LegalContent.termsAndConditions),
    (title: 'Risk Disclosure', content: LegalContent.riskDisclosure),
  ];

  Future<void> _onAccept() async {
    if (_step < _docs.length - 1) {
      setState(() => _step++);
      return;
    }
    setState(() => _submitting = true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.acceptLegalDocuments(
      privacyVersion: AppConstants.privacyPolicyVersion,
      termsVersion: AppConstants.termsVersion,
      riskVersion: AppConstants.riskDisclosureVersion,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {}, // authStatusProvider will react to the profile stream and route forward automatically
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = _docs[_step];
    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: List.generate(_docs.length, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.accentGold : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(doc.content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _onAccept,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_step < _docs.length - 1 ? 'I Agree — Continue' : 'I Agree — Enter TickBell'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

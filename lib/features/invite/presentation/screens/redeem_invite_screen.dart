import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/invite_providers.dart';

class RedeemInviteScreen extends ConsumerStatefulWidget {
  const RedeemInviteScreen({super.key});

  @override
  ConsumerState<RedeemInviteScreen> createState() => _RedeemInviteScreenState();
}

class _RedeemInviteScreenState extends ConsumerState<RedeemInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inviteRedemptionControllerProvider);

    ref.listen(inviteRedemptionControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: AppColors.bearRed.withOpacity(0.2)),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter invite code'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.vpn_key_rounded, size: 48, color: AppColors.accentGold),
                const SizedBox(height: 16),
                Text(
                  'TickBell is invite-only',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask an existing member or admin for an invite code, then enter it below to '
                  'activate your account.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Invite code',
                    hintText: 'e.g. TICK-7F3K9Q',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'Enter a valid invite code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final success = await ref
                                .read(inviteRedemptionControllerProvider.notifier)
                                .redeem(_codeController.text);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Welcome to TickBell! 🔔')),
                              );
                            }
                          },
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Activate account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

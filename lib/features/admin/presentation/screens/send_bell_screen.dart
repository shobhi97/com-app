import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../bell/domain/bell_entities.dart';
import '../../../bell/presentation/providers/bell_providers.dart';

class SendBellScreen extends ConsumerStatefulWidget {
  const SendBellScreen({super.key});

  @override
  ConsumerState<SendBellScreen> createState() => _SendBellScreenState();
}

class _SendBellScreenState extends ConsumerState<SendBellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instrumentController = TextEditingController();
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  final _targetController = TextEditingController();
  final _slController = TextEditingController();

  BellType _type = BellType.buy;
  BellPriority _priority = BellPriority.high;

  @override
  void dispose() {
    _instrumentController.dispose();
    _messageController.dispose();
    _priceController.dispose();
    _targetController.dispose();
    _slController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sendBellControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ring a Bell')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BellType.values.map((t) {
                  final selected = _type == t;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.accentGold.withOpacity(0.25),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BellPriority.values.map((p) {
                  final selected = _priority == p;
                  return ChoiceChip(
                    label: Text(p.name.toUpperCase()),
                    selected: selected,
                    onSelected: (_) => setState(() => _priority = p),
                    selectedColor: AppColors.bearRed.withOpacity(0.25),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _instrumentController,
                decoration: const InputDecoration(labelText: 'Instrument', hintText: 'e.g. NIFTY 24500 CE'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Entry price'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Target'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _slController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Stop loss'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message', hintText: 'Rationale / context for members'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded),
                  onPressed: state.isLoading ? null : _submit,
                  label: state.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send bell to all members'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final bell = Bell(
      id: '',
      createdByUserId: '',
      createdByName: '',
      type: _type,
      priority: _priority,
      instrument: _instrumentController.text.trim(),
      price: double.tryParse(_priceController.text),
      targetPrice: double.tryParse(_targetController.text),
      stopLoss: double.tryParse(_slController.text),
      message: _messageController.text.trim(),
      createdAt: DateTime.now(),
    );
    final ok = await ref.read(sendBellControllerProvider.notifier).send(bell);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bell sent 🔔')));
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send bell. Please try again.')),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../meet/domain/session_entities.dart';
import '../../../meet/presentation/providers/session_providers.dart';

class ScheduleSessionScreen extends ConsumerStatefulWidget {
  const ScheduleSessionScreen({super.key});

  @override
  ConsumerState<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends ConsumerState<ScheduleSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _meetLinkController = TextEditingController();
  DateTime _scheduledStart = DateTime.now().add(const Duration(hours: 1));
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _meetLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStart,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledStart));
    if (time == null) return;
    setState(() {
      _scheduledStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Session title', hintText: 'e.g. Weekly options walkthrough'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _meetLinkController,
                decoration: const InputDecoration(
                  labelText: 'Google Meet link',
                  hintText: 'https://meet.google.com/xxx-xxxx-xxx',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('meet.google.com')) return 'Enter a valid Google Meet link';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scheduled start'),
                subtitle: Text(_scheduledStart.toString()),
                trailing: const Icon(Icons.edit_calendar_rounded),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create session'),
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
    setState(() => _submitting = true);
    final session = LiveSession(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      meetLink: _meetLinkController.text.trim(),
      scheduledStart: _scheduledStart,
      status: SessionStatus.scheduled,
      hostUserId: '',
      hostName: '',
    );
    final result = await ref.read(sessionRepositoryProvider).scheduleSession(session);
    setState(() => _submitting = false);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session scheduled')));
        Navigator.of(context).pop();
      },
    );
  }
}

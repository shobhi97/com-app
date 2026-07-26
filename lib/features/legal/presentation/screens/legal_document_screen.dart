import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onAccept;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
          ),
          if (onAccept != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: onAccept, child: const Text('I Agree')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

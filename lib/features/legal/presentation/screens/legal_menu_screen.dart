import 'package:flutter/material.dart';
import '../../legal_content.dart';
import 'legal_document_screen.dart';

class LegalMenuScreen extends StatelessWidget {
  const LegalMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docs = [
      ('Privacy Policy', LegalContent.privacyPolicy, Icons.privacy_tip_outlined),
      ('Terms & Conditions', LegalContent.termsAndConditions, Icons.gavel_rounded),
      ('Risk Disclosure', LegalContent.riskDisclosure, Icons.warning_amber_rounded),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final (title, content, icon) = docs[index];
          return Card(
            child: ListTile(
              leading: Icon(icon),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LegalDocumentScreen(title: title, content: content)),
              ),
            ),
          );
        },
      ),
    );
  }
}

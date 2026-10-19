import 'package:flutter/material.dart';
import 'package:prism_adaptive_dialog/prism_adaptive_dialog.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'prism_adaptive_dialog demo',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await PrismAdaptiveDialog.show<bool>(
      context,
      title: 'Delete item?',
      builder: (context) => const Text('This cannot be undone.'),
      actions: [
        AdaptiveDialogAction.cancel(context),
        AdaptiveDialogAction.destructive(
          context,
          label: 'Delete',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('prism_adaptive_dialog demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete item'),
            ),
            const SizedBox(height: 8),
            // Resize the window: sheet on phones, dialog on desktop.
            Text(
              'Resize the window to see the presentation adapt.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

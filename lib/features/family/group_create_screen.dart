import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/providers/family_group_providers.dart';

class GroupCreateScreen extends ConsumerStatefulWidget {
  const GroupCreateScreen({super.key});
  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final hubCtrl = TextEditingController();
  bool loading = false;

  Future<void> _create() async {
    setState(() => loading = true);
    try {
      final emails =
          emailCtrl.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      await dio.post(
        '/family-group/create',
        data: {
          'name': nameCtrl.text.trim(),
          'emails': emails,
          'hubId': hubCtrl.text.trim(),
        },
      );
      ref.invalidate(familyGroupsProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новая группа')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Название'),
              controller: nameCtrl,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Пригласить (email, через запятую)',
              ),
              controller: emailCtrl,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'HubId (опц.)'),
              controller: hubCtrl,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loading ? null : _create,
              icon: const Icon(Icons.check),
              label: Text(loading ? 'Создание…' : 'Создать'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({super.key});

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _form = GlobalKey<FormState>();
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Добавить друга',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _c,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email друга',
                  hintText: 'friend@example.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Укажите email';
                  final ok = RegExp(r'.+@.+\..+').hasMatch(v.trim());
                  return ok ? null : 'Неверный email';
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (_form.currentState?.validate() != true) return;
                  Navigator.pop(context, _c.text.trim());
                },
                icon: const Icon(Icons.send),
                label: const Text('Отправить заявку'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

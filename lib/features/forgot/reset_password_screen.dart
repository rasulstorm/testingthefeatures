import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ISS/core/network/dio_provider.dart';

final resetPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ResetPasswordController, AsyncValue<void>>(
  (ref) => ResetPasswordController(ref),
);

class ResetPasswordController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ResetPasswordController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> resetPassword(String phone, String password, String confirm) async {
    state = const AsyncValue.loading();
    try {
      await dio.post('/account-management/change-password', data: {
          "email": null,
          "phoneNumber": phone,
          "oldPassword": null,
          "newPassword": password,
          "confirmPassword": confirm
      });
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String phone;

  const ResetPasswordScreen({super.key, required this.phone});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Новый пароль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Новый пароль'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Повторите пароль'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      if (passwordController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пароли не совпадают')),
                        );
                        return;
                      }

                      final success = await ref
                          .read(resetPasswordControllerProvider.notifier)
                          .resetPassword(widget.phone, passwordController.text, confirmController.text);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пароль успешно изменён')),
                        );
                        await Future.delayed(const Duration(seconds: 2));
                        context.go('/');
                      }
                    },
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Сменить пароль'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String email;
  final String password;
  final String iin;
  final String phoneNumber;
  final String firstName;

  const OtpScreen({
    Key? key,
    required this.phone,
    required this.email,
    required this.password,
    required this.iin,
    required this.phoneNumber,
    required this.firstName,
  }) : super(key: key);

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> with CodeAutoFill {
  String _code = "";
  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _listenForCode();
    _startTimer();
    _sendCode();
  }

  void codeUpdated() {
    setState(() {
      _code = code ?? '';
    });
    print("Автоввод кода: $_code");
  }

  void _listenForCode() async {
    await SmsAutoFill().listenForCode();
    listenForCode();
  }

  void _sendCode() async {
    final phone = normalizePhoneNumber(widget.phone);

    try {
      final response = await Dio().post(
        'https://cms.iss-control.kz:8443/api/v1/account-management/send-otp',
        queryParameters: {
          'phoneNumber': phone,
          'verificationType': 'whatsapp',
          'forgotPassword': false,
        },
      );
      final message = response.data['message'];
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message ?? 'Код отправлен')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при отправке SMS')),
        );
      }
    }
  }

  void _submitCode() async {
    final phone = normalizePhoneNumber(widget.phone);
    final code = _code;

    try {
      final verifyResponse = await Dio().post(
        'https://cms.iss-control.kz:8443/api/v1/account-management/verify-otp',
        queryParameters: {'phoneNumber': phone, 'code': code},
      );

      final verifyData = verifyResponse.data;
      final message = verifyData['message'];

      if (verifyData['code'] == 0) {
        final registerResponse = await Dio().post(
          'https://cms.iss-control.kz:8443/api/v1/account-management/register',
          data: {
            'email': widget.email,
            'password': widget.password,
            'iin': widget.iin,
            'firstName': widget.firstName,
            'phoneNumber': widget.phoneNumber,
          },
        );

        final registerJson = registerResponse.data;
        final data = registerJson['data'];
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        if (accessToken != null && refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          await prefs.setString('refreshToken', refreshToken);
          await prefs.setString('saved_email', widget.email);
          await prefs.setString('saved_password', widget.password);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Регистрация успешна')),
            );
            context.go('/security-control');
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка: токены не получены')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message ?? 'Ошибка подтверждения')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при подтверждении или регистрации'),
          ),
        );
      }
    }
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Подтверждение кода")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Введите код, отправленный в WhatsApp"),
            const SizedBox(height: 24),
            PinFieldAutoFill(
              codeLength: 6,
              currentCode: _code,
              onCodeChanged: (val) => setState(() => _code = val ?? ""),
              onCodeSubmitted: (val) => print("Код отправлен: $val"),
              decoration: UnderlineDecoration(
                textStyle: const TextStyle(fontSize: 20, color: Colors.white),
                colorBuilder: FixedColorBuilder(Colors.grey),
                lineHeight: 2,
              ),
            ),
            const SizedBox(height: 16),
            if (_canResend)
              TextButton(
                onPressed: () {
                  _sendCode();
                  _startTimer();
                },
                child: const Text("Отправить код повторно"),
              )
            else
              Text("Повторная отправка через $_secondsRemaining сек"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _code.length == 6 ? _submitCode : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Подтвердить"),
            ),
          ],
        ),
      ),
    );
  }

  String normalizePhoneNumber(String rawPhone) {
    return rawPhone.replaceAll(RegExp(r'[^\d]'), '');
  }
}

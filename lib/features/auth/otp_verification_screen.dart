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
  final String? lastName;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.email,
    required this.password,
    required this.iin,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> with CodeAutoFill {
  String _code = "";
  bool _canResend = false;
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listenForCode();
    _startTimer();
    _sendCode();
  }

  @override
  void codeUpdated() {
    setState(() {
      _code = code ?? '';
    });
    print("Автоввод кода: $_code");
    if (_code.length == 6) {
      _submitCode();
    }
  }

  void _listenForCode() async {
    await SmsAutoFill().listenForCode();
    listenForCode();
  }

  // ИСПРАВЛЕНИЕ: Возвращаемся к оригинальной логике с queryParameters
  void _sendCode() async {
    final phone = normalizePhoneNumber(widget.phone);

    try {
      final response = await Dio().post(
        'https://stage-app.iss-control.kz/api/v1/account-management/send-otp',
        queryParameters: {
          // <-- ВОЗВРАЩАЕМ QUERY PARAMETERS
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
          SnackBar(content: Text('Ошибка при отправке кода: ${e.toString()}')),
        );
      }
    }
  }

  void _submitCode() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final phone = normalizePhoneNumber(widget.phone);
    final code = _code;

    try {
      // Для верификации также используем queryParameters, как в оригинале
      final verifyResponse = await Dio().post(
        'https://stage-app.iss-control.kz/api/v1/account-management/verify-otp',
        queryParameters: {'phoneNumber': phone, 'code': code},
      );

      final verifyData = verifyResponse.data;
      final message = verifyData['message'];

      if (verifyData['code'] == 0) {
        // А для регистрации, как и было, используем data
        final registerResponse = await Dio().post(
          'https://stage-app.iss-control.kz/api/v1/account-management/register',
          data: {
            'email': widget.email,
            'password': widget.password,
            'iin': widget.iin,
            'firstName': widget.firstName,
            'phoneNumber': widget.phoneNumber,
            'lastName': widget.lastName,
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
            context.go('/main');
          }
        } else {
          throw Exception('Ошибка: токены не получены');
        }
      } else {
        throw Exception(message ?? 'Ошибка подтверждения');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() => _canResend = true);
        }
      } else {
        if (mounted) {
          setState(() => _secondsRemaining--);
        }
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
            Text(
              "Введите код, отправленный в WhatsApp на номер ${widget.phone}",
            ),
            const SizedBox(height: 24),
            PinFieldAutoFill(
              codeLength: 6,
              currentCode: _code,
              onCodeChanged: (val) => setState(() => _code = val ?? ""),
              onCodeSubmitted: (val) {
                if (val.length == 6) _submitCode();
              },
              decoration: UnderlineDecoration(
                textStyle: const TextStyle(fontSize: 20, color: Colors.black),
                colorBuilder: const FixedColorBuilder(Colors.grey),
                lineHeight: 2,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child:
                  _canResend
                      ? TextButton(
                        onPressed: () {
                          _sendCode();
                          _startTimer();
                        },
                        child: const Text("Отправить код повторно"),
                      )
                      : Center(
                        child: Text(
                          "Повторная отправка через $_secondsRemaining сек",
                        ),
                      ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  (_code.length == 6 && !_isLoading) ? _submitCode : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text("Подтвердить"),
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

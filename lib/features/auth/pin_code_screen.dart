// lib/features/auth/pin_code_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/services/pin_code_service.dart';
import 'package:pinput/pinput.dart'; // Будем использовать эту библиотеку для ввода PIN
import 'package:ISS/l10n/app_localizations.dart'; // Для локализации

// Провайдер для PinCodeService
final pinCodeServiceProvider = Provider((ref) => PinCodeService());

enum PinCodeMode {
  create, // Создание нового PIN
  confirm, // Подтверждение созданного PIN
  verify, // Проверка существующего PIN
  changeOld, // Ввод старого PIN при смене
  changeNew, // Ввод нового PIN при смене
  changeConfirm, // Подтверждение нового PIN при смене
}

class PinCodeScreen extends ConsumerStatefulWidget {
  final PinCodeMode mode;
  final String? initialPin; // Для режимов confirm, changeNew, changeConfirm
  final VoidCallback? onPinVerified; // Вызывается при успешной проверке PIN
  final VoidCallback? onPinSet; // Вызывается при успешной установке PIN
  final VoidCallback?
  onAuthFailed; // Вызывается, если аутентификация не удалась (только для verify mode)

  const PinCodeScreen({
    super.key,
    required this.mode,
    this.initialPin,
    this.onPinVerified,
    this.onPinSet,
    this.onAuthFailed,
  });

  @override
  ConsumerState<PinCodeScreen> createState() => _PinCodeScreenState();
}

class _PinCodeScreenState extends ConsumerState<PinCodeScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String? _errorMessage;
  int _failedAttempts = 0; // Для режима verify

  @override
  void initState() {
    super.initState();
    if (widget.mode == PinCodeMode.verify) {
      _loadFailedAttempts();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  Future<void> _loadFailedAttempts() async {
    final pinCodeService = ref.read(pinCodeServiceProvider);
    _failedAttempts = await pinCodeService.getPinAttempts();
    if (_failedAttempts >= PinCodeService.maxPinAttempts) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).pinLockedOut;
      });
      if (widget.onAuthFailed != null) {
        widget.onAuthFailed!();
      }
    }
  }

  String get _title {
    final localizations = AppLocalizations.of(context);
    switch (widget.mode) {
      case PinCodeMode.create:
        return localizations.createPinTitle;
      case PinCodeMode.confirm:
        return localizations.confirmPinTitle;
      case PinCodeMode.verify:
        return localizations.enterPinTitle;
      case PinCodeMode.changeOld:
        return localizations.enterOldPinTitle;
      case PinCodeMode.changeNew:
        return localizations.createNewPinTitle;
      case PinCodeMode.changeConfirm:
        return localizations.confirmNewPinTitle;
    }
  }

  String get _description {
    final localizations = AppLocalizations.of(context);
    switch (widget.mode) {
      case PinCodeMode.create:
        return localizations.createPinDescription;
      case PinCodeMode.confirm:
        return localizations.confirmPinDescription;
      case PinCodeMode.verify:
        return localizations.enterPinDescription;
      case PinCodeMode.changeOld:
        return localizations.enterOldPinDescription;
      case PinCodeMode.changeNew:
        return localizations.createNewPinDescription;
      case PinCodeMode.changeConfirm:
        return localizations.confirmNewPinDescription;
    }
  }

  Future<void> _handlePinInput(String pin) async {
    setState(() {
      _errorMessage = null;
    });

    final pinCodeService = ref.read(pinCodeServiceProvider);
    final localizations = AppLocalizations.of(context);

    if (widget.mode == PinCodeMode.create) {
      context.pushReplacement(
        '/pin_code',
        extra: {
          'mode': PinCodeMode.confirm,
          'initialPin': pin,
          'onPinSet': widget.onPinSet,
        },
      );
    } else if (widget.mode == PinCodeMode.confirm) {
      if (pin == widget.initialPin) {
        await pinCodeService.setPinCode(pin);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.pinSetSuccess)));
        if (widget.onPinSet != null) {
          widget.onPinSet!(); // Уведомляем о том, что пин установлен
        }
        context.pop(); // Закрываем экран пин-кода
      } else {
        setState(() {
          _errorMessage = localizations.pinMismatch;
        });
        _pinController.clear();
      }
    } else if (widget.mode == PinCodeMode.verify) {
      if (await pinCodeService.isPinLockedOut()) {
        setState(() {
          _errorMessage = localizations.pinLockedOut;
        });
        if (widget.onAuthFailed != null) {
          widget.onAuthFailed!();
        }
        return;
      }

      final bool verified = await pinCodeService.verifyPinCode(pin);
      if (verified) {
        if (widget.onPinVerified != null) {
          widget.onPinVerified!(); // Уведомляем о том, что пин успешно проверен
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.pinVerifiedSuccess)),
        );
        context.go(
          '/main',
        ); // Переходим на главный экран после успешной верификации
      } else {
        _failedAttempts = await pinCodeService.getPinAttempts();
        String errorText = localizations.incorrectPin;
        if (_failedAttempts < PinCodeService.maxPinAttempts) {
          errorText += ' ${localizations.attemptsRemaining(_failedAttempts)}';
        }
        setState(() {
          _errorMessage = errorText;
        });
        _pinController.clear();

        if (_failedAttempts >= PinCodeService.maxPinAttempts) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.pinLockedOutRedirect),
              backgroundColor: AppColors.error,
            ),
          );
          if (widget.onAuthFailed != null) {
            widget.onAuthFailed!();
          }
          context.go(
            '/login',
          ); // Принудительный выход на логин после блокировки
        }
      }
    } else if (widget.mode == PinCodeMode.changeOld) {
      final bool verified = await pinCodeService.verifyPinCode(pin);
      if (verified) {
        context.pushReplacement(
          '/pin_code',
          extra: {'mode': PinCodeMode.changeNew},
        );
      } else {
        setState(() {
          _errorMessage = localizations.incorrectOldPin;
        });
        _pinController.clear();
      }
    } else if (widget.mode == PinCodeMode.changeNew) {
      context.pushReplacement(
        '/pin_code',
        extra: {
          'mode': PinCodeMode.changeConfirm,
          'initialPin': pin,
          'onPinSet': widget.onPinSet,
        },
      );
    } else if (widget.mode == PinCodeMode.changeConfirm) {
      if (pin == widget.initialPin) {
        await pinCodeService.setPinCode(pin);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.pinChangedSuccess)),
        );
        if (widget.onPinSet != null) {
          widget.onPinSet!();
        }
        context.pop(); // Закрываем экран пин-кода
      } else {
        setState(() {
          _errorMessage = localizations.pinMismatch;
        });
        _pinController.clear();
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: AppStyles.headline2(
        context,
      ).copyWith(color: AppColors.getTextColor(context)),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.getBorderGrayColor(context)),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryAccent),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: AppColors.getCardBackgroundColor(context),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _description,
                textAlign: TextAlign.center,
                style: AppStyles.bodyText1(
                  context,
                ).copyWith(color: AppColors.getSecondaryTextColor(context)),
              ),
              const SizedBox(height: 40),
              Pinput(
                length: 4, // Длина пин-кода
                controller: _pinController,
                focusNode: _pinFocusNode,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                obscureText: true, // Скрывать вводимые символы
                showCursor: true,
                onCompleted: _handlePinInput,
                errorText: _errorMessage,
                errorTextStyle: AppStyles.bodyText2(
                  context,
                ).copyWith(color: AppColors.error),
                validator: (pin) {
                  if (widget.mode == PinCodeMode.verify &&
                      _failedAttempts >= PinCodeService.maxPinAttempts) {
                    return AppLocalizations.of(context).pinLockedOut;
                  }
                  if (pin == null || pin.length < 4) {
                    return 'Введите 4-значный PIN-код'; // Замените на локализованную строку
                  }
                  return null;
                },
              ),
              if (widget.mode == PinCodeMode.verify &&
                  _failedAttempts > 0 &&
                  _failedAttempts < PinCodeService.maxPinAttempts)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).attemptsRemaining(_failedAttempts),
                    style: AppStyles.bodyText2(
                      context,
                    ).copyWith(color: AppColors.error),
                  ),
                ),
              const SizedBox(height: 20),
              if (widget.mode == PinCodeMode.verify &&
                  _failedAttempts >= PinCodeService.maxPinAttempts)
                ElevatedButton(
                  onPressed: () {
                    if (widget.onAuthFailed != null) {
                      widget.onAuthFailed!();
                    }
                    context.go('/login'); // Принудительный выход на логин
                  },
                  style: AppStyles.primaryButtonStyle.copyWith(
                    backgroundColor: WidgetStateProperty.all(AppColors.error),
                  ),
                  child: Text(AppLocalizations.of(context).loginWithPassword),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/services/picovoice_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';
import 'package:rhino_flutter/rhino.dart';
import 'package:picovoice_flutter/picovoice_error.dart';

enum PicovoiceState { stopped, listeningForWakeWord, listeningForCommand }

class PicovoiceService extends StateNotifier<PicovoiceState> {
  PicovoiceManager? _picovoiceManager;
  final String accessKey =
      "VgeNp9nCiZq2s5/NVh870BEUtLkVNtlztzKkSBYLQAwcp2bNZWgO0Q==";
  final String keywordPath = "assets/picovoice/rasul.ppn";
  final String contextPath = "assets/picovoice/iss_assistant_en.rhn";

  Timer? _commandTimeout;

  PicovoiceService() : super(PicovoiceState.stopped);

  Future<void> toggleListening() async {
    if (state == PicovoiceState.stopped) {
      await _start();
    } else {
      await _stop();
    }
  }

  Future<void> _start() async {
    if (state != PicovoiceState.stopped) return;

    if (await _checkPermission()) {
      try {
        _picovoiceManager = await PicovoiceManager.create(
          accessKey,
          keywordPath,
          _wakeWordCallback,
          contextPath,
          _inferenceCallback,
          processErrorCallback: _errorCallback,
        );
        await _picovoiceManager?.start();
        state = PicovoiceState.listeningForWakeWord;
        if (kDebugMode) {
          print("PICOVOICE: Начал слушать ключевое слово.");
        }
      } on PicovoiceException catch (e) {
        if (kDebugMode) print("PICOVOICE: Ошибка инициализации: $e");
        await _stop();
      }
    }
  }

  Future<void> _stop() async {
    if (state == PicovoiceState.stopped) return;

    await _picovoiceManager?.stop();
    await _picovoiceManager?.delete();
    _picovoiceManager = null;
    _commandTimeout?.cancel();
    state = PicovoiceState.stopped;
    if (kDebugMode) {
      print("PICOVOICE: Сервис остановлен.");
    }
  }

  void _wakeWordCallback() {
    if (state == PicovoiceState.listeningForCommand) {
      if (kDebugMode) print("PICOVOICE: Повторное ключевое слово. Выключаюсь.");
      _stop();
      return;
    }

    if (kDebugMode) {
      print("PICOVOICE: Ключевое слово обнаружено! Слушаю команду...");
    }
    state = PicovoiceState.listeningForCommand;

    _commandTimeout?.cancel();
    _commandTimeout = Timer(const Duration(seconds: 5), () {
      if (state == PicovoiceState.listeningForCommand) {
        if (kDebugMode) {
          print(
            "PICOVOICE: Таймаут команды. Возвращаюсь к ожиданию wake word.",
          );
        }
        state = PicovoiceState.listeningForWakeWord;
      }
    });
  }

  // --- ИСПРАВЛЕНИЕ: Удалена вызов inference.toJson() ---
  void _inferenceCallback(RhinoInference inference) {
    if (kDebugMode) {
      // Вместо toJson(), выводим intent и slots
      print("PICOVOICE: Распознана команда:");
      print("  Intent: ${inference.intent ?? 'N/A'}");
      print("  Slots: ${inference.slots ?? {}}");
    }

    if (inference.isUnderstood!) {
      // >>> ЗДЕСЬ ВАША ЛОГИКА ОБРАБОТКИ КОМАНД <<<
      // Например, доступ к intent и slots:
      // String? intent = inference.intent;
      // Map<String, String?>? slots = inference.slots;
      // if (intent == 'turnLightsOn' && slots?['device'] == 'kitchen') { ... }
    }

    state = PicovoiceState.listeningForWakeWord;
    _commandTimeout?.cancel();
  }
  // -------------------------------------------------------

  void _errorCallback(PicovoiceException error) {
    if (kDebugMode) {
      print("PICOVOICE: Произошла ошибка во время работы: $error");
    }
    _stop();
  }

  Future<bool> _checkPermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (kDebugMode) {
        print("PICOVOICE: Разрешение на микрофон не предоставлено.");
      }
      return false;
    }
    return true;
  }
}

final picovoiceProvider =
    StateNotifierProvider.autoDispose<PicovoiceService, PicovoiceState>((ref) {
      return PicovoiceService();
    });

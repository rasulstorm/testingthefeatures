import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:ISS/providers/openai_nlu_provider.dart';
import 'package:ISS/main.dart'; // localeProvider
import 'package:ISS/providers/hubs_provider.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/utils/device_utils.dart';
import 'package:ISS/models/device_models.dart';
import 'package:flutter/material.dart'; // <-- добавь это

class VoiceCommandState {
  final bool initialized;
  final bool listening;
  final String lastTranscript;
  final String lastActionMessage; // для UI "что сделали"

  const VoiceCommandState({
    this.initialized = false,
    this.listening = false,
    this.lastTranscript = '',
    this.lastActionMessage = '',
  });

  VoiceCommandState copyWith({
    bool? initialized,
    bool? listening,
    String? lastTranscript,
    String? lastActionMessage,
  }) {
    return VoiceCommandState(
      initialized: initialized ?? this.initialized,
      listening: listening ?? this.listening,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      lastActionMessage: lastActionMessage ?? this.lastActionMessage,
    );
  }
}

class VoiceCommandController extends StateNotifier<VoiceCommandState> {
  final Ref ref;
  final stt.SpeechToText _stt = stt.SpeechToText();

  VoiceCommandController(this.ref) : super(const VoiceCommandState());

  Future<void> init() async {
    if (state.initialized) return;
    final ok = await _stt.initialize();
    state = state.copyWith(initialized: ok);
  }

  Future<void> startListening() async {
    if (!state.initialized) await init();
    if (!state.initialized) return;

    state = state.copyWith(listening: true, lastTranscript: '');

    await _stt.listen(
      onResult: (r) {
        state = state.copyWith(lastTranscript: r.recognizedWords);
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
    );
  }

  Future<void> stopAndProcess() async {
    if (!state.listening) return;
    await _stt.stop();
    state = state.copyWith(listening: false);

    final text = state.lastTranscript.trim();
    if (text.isEmpty) {
      state = state.copyWith(lastActionMessage: 'Не распознано.');
      return;
    }

    final locale = ref.read(localeProvider).languageCode;
    final nlu = ref.read(openAiNluProvider);
    final map = await nlu.extractIntent(text, locale: locale);

    final intent = (map['intent'] ?? 'unknown') as String;

    switch (intent) {
      case 'change_language':
        final lang = (map['language'] ?? '').toString();
        await _applyChangeLanguage(lang);
        break;
      case 'toggle_light':
        final deviceName = (map['device_name'] ?? '').toString();
        final stateStr = (map['state'] ?? '').toString().toLowerCase();
        final isOn =
            stateStr == 'on' || stateStr == 'вкл' || stateStr == 'включи';
        await _applyToggleLight(deviceName, isOn);
        break;
      default:
        state = state.copyWith(lastActionMessage: 'Команда не распознана.');
    }
  }

  Future<void> _applyChangeLanguage(String lang) async {
    final allowed = {'ru', 'en', 'kk'};
    final normalized = allowed.contains(lang) ? lang : _closestLang(lang);
    if (normalized == null) {
      state = state.copyWith(lastActionMessage: 'Язык не поддерживается.');
      return;
    }
    ref.read(localeProvider.notifier).setLocale(Locale(normalized));
    state = state.copyWith(lastActionMessage: 'Язык переключён: $normalized');
  }

  String? _closestLang(String raw) {
    final s = raw.toLowerCase();
    if (s.startsWith('ru') || s.contains('рус')) return 'ru';
    if (s.startsWith('en') || s.contains('англ')) return 'en';
    if (s.startsWith('kk') || s.contains('каз')) return 'kk';
    return null;
  }

  Future<void> _applyToggleLight(String deviceName, bool turnOn) async {
    // Находим первый доступный хаб и устройство по имени (friendlyName).
    final hubsAsync = await ref.read(hubsProvider.future);
    if (hubsAsync.isEmpty) {
      state = state.copyWith(lastActionMessage: 'Нет хабов.');
      return;
    }
    // можно сделать умнее (активный хаб и т.п.). Пока — первый.
    final hub = hubsAsync.first;

    // ищем управляемые девайсы
    final devices = DeviceUtils.getControllableDevices(hub.devices);
    BaseDevice? found;

    final target = deviceName.toLowerCase().trim();
    if (target.isEmpty) {
      state = state.copyWith(lastActionMessage: 'Не названо устройство.');
      return;
    }

    for (final d in devices) {
      final title = d.friendlyName.toLowerCase();
      if (title.contains(target)) {
        found = d;
        break;
      }
    }

    if (found == null) {
      state = state.copyWith(lastActionMessage: 'Устройство не найдено.');
      return;
    }

    final ws = ref.read(webSocketNotifierProvider.notifier);
    final payload = {"state": turnOn ? "ON" : "OFF"};
    ws.sendDeviceCommand(hub.commandHubId, found.id, payload);
    ws.updateDeviceLocalState(found.id, payload);

    state = state.copyWith(
      lastActionMessage:
          '${turnOn ? "Включаю" : "Выключаю"}: ${found.friendlyName}',
    );
  }
}

final voiceControllerProvider =
    StateNotifierProvider<VoiceCommandController, VoiceCommandState>((ref) {
      return VoiceCommandController(ref);
    });

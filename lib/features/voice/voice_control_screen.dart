// lib/features/voice/voice_control_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';

// ТОЛЬКО личные хабы
import 'package:ISS/providers/hubs_provider.dart' as hprov;
import 'package:ISS/models/hub_models.dart';

/// Экран голосового управления: отправляет распознанный текст на /voice-assistant
class VoiceControlScreen extends ConsumerStatefulWidget {
  const VoiceControlScreen({super.key});

  @override
  ConsumerState<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends ConsumerState<VoiceControlScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _status = 'Не слушаю';
  String _lastHeard = 'Нажми 🎤 чтобы начать говорить';

  HubObject? _selectedHub;
  final List<_LogEntry> _history = <_LogEntry>[];
  bool _busyAction = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  // === ГОЛОС ===
  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _status = 'Остановлено';
      });
      await _speech.stop();
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (s) => setState(() => _status = s),
        onError: (e) {
          setState(() => _status = 'Ошибка: ${e.errorMsg}');
          _pushHistory('SpeechError', 'Ошибка: ${e.errorMsg}', false);
        },
      );
      if (!available) {
        setState(() => _status = 'Speech недоступен');
        _pushHistory('SpeechInit', 'Speech API недоступен', false);
        return;
      }

      setState(() {
        _isListening = true;
        _status = 'Слушаю…';
        _lastHeard = 'Говорите…';
      });

      await _speech.listen(
        localeId: 'ru-RU', // при необходимости: 'en-US', 'kk-KZ'
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: (double _) {}, // сигнатура корректная
        onResult: (res) async {
          final text = res.recognizedWords.trim();
          if (text.isEmpty) return;

          setState(() => _lastHeard = text);

          if (res.finalResult) {
            if (_selectedHub == null) {
              _pushHistory('Voice', 'Не выбран Hub', false);
              return;
            }
            final hubId =
                _selectedHub!.commandHubId.isNotEmpty
                    ? _selectedHub!.commandHubId
                    : _selectedHub!.hubNumber;

            _pushHistory('Распознано', text, true);
            await _sendVoiceCommandToBackend(hubId: hubId, text: text);
          }
        },
      );
    } on PlatformException catch (e) {
      setState(() => _status = 'Platform error: ${e.code}');
      _pushHistory('Speech', 'Platform error: ${e.message ?? e.code}', false);
    } catch (e) {
      setState(() => _status = 'Listen failed');
      _pushHistory('Speech', 'Listen failed: $e', false);
    }
  }

  // === API ===
  Future<void> _sendVoiceCommandToBackend({
    required String hubId,
    required String text,
  }) async {
    setState(() => _busyAction = true);
    try {
      final res = await dio.post(
        '/voice-assistant',
        data: {'hubId': hubId, 'text': text},
      );
      _pushHistory(
        'Voice → API',
        '✔ ${res.statusCode}: ${res.data is Map ? (res.data['message'] ?? 'OK') : 'OK'}',
        true,
      );
    } catch (e) {
      _pushHistory('Voice → API', 'Ошибка отправки: $e', false);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  void _pushHistory(String title, String message, bool success) {
    setState(() {
      _history.insert(
        0,
        _LogEntry(
          title: title,
          message: message,
          success: success,
          time: DateTime.now(),
        ),
      );
    });
  }

  // === UI ===
  @override
  Widget build(BuildContext context) {
    final hubsAsync = ref.watch(hprov.hubsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Голосовое управление')),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Column(
        children: [
          // Выбор Hub (ТОЛЬКО личные)
          Padding(
            padding: const EdgeInsets.all(12),
            child: hubsAsync.when(
              data: (hubs) {
                final items =
                    hubs
                        .map(
                          (h) => DropdownMenuItem<HubObject>(
                            value: h,
                            child: Text(
                              h.facilityName.isEmpty
                                  ? h.hubNumber
                                  : h.facilityName,
                            ),
                          ),
                        )
                        .toList();

                _selectedHub ??= hubs.isNotEmpty ? hubs.first : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Куда отправлять команды',
                      style: AppStyles.headline4(context),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<HubObject>(
                      isExpanded: true,
                      value: _selectedHub,
                      items: items,
                      onChanged: (v) => setState(() => _selectedHub = v),
                      decoration: const InputDecoration(labelText: 'Hub'),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Ошибка загрузки хабов: $e'),
            ),
          ),

          // Быстрые примеры (шлют сразу на /voice-assistant)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip('Включи свет', () => _sendQuick('Включи свет')),
                _quickChip('Выключи свет', () => _sendQuick('Выключи свет')),
                _quickChip(
                  'Закрыть ворота',
                  () => _sendQuick('Закрыть ворота'),
                ),
                _quickChip(
                  'Открыть ворота',
                  () => _sendQuick('Открыть ворота'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Слушатель + статус
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _listenCard(context),
          ),

          const SizedBox(height: 8),

          // История
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: AppStyles.cardDecoration(context),
              child:
                  _history.isEmpty
                      ? Center(
                        child: Text(
                          'История пуста',
                          style: AppStyles.bodyText2(context),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _history.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              color: AppColors.getBorderGrayColor(context),
                              height: 1,
                            ),
                        itemBuilder:
                            (_, i) => _historyTile(context, _history[i]),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendQuick(String text) async {
    if (_selectedHub == null) {
      _pushHistory('Быстрая команда', 'Не выбран Hub', false);
      return;
    }
    final hubId =
        _selectedHub!.commandHubId.isNotEmpty
            ? _selectedHub!.commandHubId
            : _selectedHub!.hubNumber;
    _pushHistory('Быстрая команда', text, true);
    await _sendVoiceCommandToBackend(hubId: hubId, text: text);
  }

  Widget _quickChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: AppColors.getCardBackgroundColor(context),
          shape: StadiumBorder(
            side: BorderSide(color: AppColors.getBorderGrayColor(context)),
          ),
        ),
        child: Text(label, style: AppStyles.bodyText1(context)),
      ),
    );
  }

  Widget _listenCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        children: [
          Text(
            _lastHeard,
            textAlign: TextAlign.center,
            style: AppStyles.bodyText1(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text('Статус: $_status', style: AppStyles.caption(context)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _busyAction ? null : _toggleListening,
            icon: Icon(_isListening ? Icons.stop : Icons.mic),
            label: Text(_isListening ? 'Стоп' : 'Говори'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor:
                  _isListening
                      ? (isDark ? Colors.redAccent.shade200 : Colors.redAccent)
                      : AppColors.primaryAccent,
              foregroundColor: AppColors.textColorDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTile(BuildContext context, _LogEntry e) {
    final color = e.success ? Colors.green : Colors.redAccent;
    final icon = e.success ? Icons.check_circle : Icons.error_outline;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(e.title, style: AppStyles.bodyText1(context)),
      subtitle: Text(e.message, style: AppStyles.bodyText2(context)),
      trailing: Text(_formatTime(e.time), style: AppStyles.caption(context)),
    );
  }

  String _formatTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

class _LogEntry {
  final String title;
  final String message;
  final bool success;
  final DateTime time;
  _LogEntry({
    required this.title,
    required this.message,
    required this.success,
    required this.time,
  });
}

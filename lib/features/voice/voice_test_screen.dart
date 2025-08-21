// lib/features/voice/voice_test_screen.dart
import 'package:flutter/material.dart';
import 'voice_command_service.dart';

class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({super.key});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final _voiceService = VoiceCommandService();
  String _status = "Нажми кнопку и скажи команду";

  Future<void> _startListening() async {
    setState(() => _status = "🎤 Слушаю...");
    final result = await _voiceService.listenAndProcess();
    setState(() => _status = "🤖 Результат: $result");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voice Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.mic),
              label: const Text("Говорить"),
            ),
          ],
        ),
      ),
    );
  }
}

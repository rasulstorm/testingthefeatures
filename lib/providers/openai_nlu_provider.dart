// lib/services/openai_nlu_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/services/openai_nlu_service.dart';

final openAiNluProvider = Provider<OpenAiNluService>((ref) {
  return OpenAiNluService();
});

import 'package:equatable/equatable.dart';

/// Элемент истории диалога с бэка.
class AiChatItem extends Equatable {
  final String id;
  final String request;
  final String response;
  final DateTime createdAt;

  const AiChatItem({
    required this.id,
    required this.request,
    required this.response,
    required this.createdAt,
  });

  factory AiChatItem.fromJson(Map<String, dynamic> json) {
    return AiChatItem(
      id: (json['id'] ?? json['chatId'] ?? '').toString(),
      request: (json['request'] ?? json['input'] ?? '').toString(),
      response: (json['response'] ?? json['output'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request': request,
    'response': response,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Для истории: старые сверху, новые снизу.
  static int compareAsc(AiChatItem a, AiChatItem b) =>
      a.createdAt.compareTo(b.createdAt);

  @override
  List<Object?> get props => [id, request, response, createdAt];
}

/// Статус сообщения в UI.
enum PendingKind { none, sending }

/// Сообщение в ленте UI.
class UiMessage extends Equatable {
  final String id;
  final String text;
  final bool isUser; // true — пользователь (справа), false — ассистент (слева)
  final DateTime createdAt;
  final PendingKind pending;

  const UiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.pending = PendingKind.none,
  });

  UiMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? createdAt,
    PendingKind? pending,
  }) {
    return UiMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      pending: pending ?? this.pending,
    );
  }

  @override
  List<Object?> get props => [id, text, isUser, createdAt, pending];
}

/// ISO или timestamp (sec/ms)
DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.now();

  final iso = DateTime.tryParse(v.toString());
  if (iso != null) return iso;

  int? n;
  if (v is num) {
    n = v.toInt();
  } else {
    n = int.tryParse(v.toString());
  }
  if (n != null) {
    if (n > 10000000000) {
      // миллисекунды
      return DateTime.fromMillisecondsSinceEpoch(n);
    } else {
      // секунды
      return DateTime.fromMillisecondsSinceEpoch(n * 1000);
    }
  }
  return DateTime.now();
}

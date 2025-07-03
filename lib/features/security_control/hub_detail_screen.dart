// lib/features/security_control/hub_detail_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/models/hub_models.dart'; // Убедитесь, что HubObject и Device корректно определены здесь
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status; // Изменено на status.dart

class HubDetailsScreen extends StatelessWidget {
  final HubObject hub;

  const HubDetailsScreen({Key? key, required this.hub}) : super(key: key);

  IconData _getIconForParameter(String key) {
    switch (key.toLowerCase()) {
      case 'temperature':
      case 'temp':
        return Icons.thermostat_outlined;
      case 'humidity':
        return Icons.opacity;
      case 'state':
      case 'status':
        return Icons.info_outline;
      case 'battery':
      case 'battery_level':
        return Icons.battery_full;
      case 'motion':
        return Icons.directions_run;
      case 'light':
        return Icons.lightbulb_outline;
      case 'pressure':
        return Icons.speed;
      case 'contact': // Для датчика двери
        return Icons.sensor_door;
      case 'occupancy': // Для датчика присутствия
        return Icons.person_search;
      case 'power': // Для умных розеток
        return Icons.power;
      case 'brightness': // Для света
        return Icons.brightness_medium;
      case 'linkquality': // Качество связи
        return Icons.network_wifi;
      case 'tamper': // Вскрытие
        return Icons.warning_amber_outlined;
      default:
        return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(hub.facilityName),
        backgroundColor: AppColors.secodnBg,
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Информация по хабу
          Card(
            color: AppColors.secodnBg,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hub.facilityName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hub.address,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Статус: ${hub.statusNameRus} (${hub.connected ? "Онлайн" : "Оффлайн"})',
                    style: TextStyle(color: hub.connected ? Colors.green : Colors.redAccent),
                  ),
                  const SizedBox(height: 8),
                  // Отображаем hubNumber (3C40FR)
                  Text(
                    'ID хаба: ${hub.hubNumber}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  // Отображаем commandHubId (isshub_ccc2ddbc) для подтверждения
                  Text(
                    'Hub ID (для команд): ${hub.commandHubId}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Список устройств
          if (hub.devices.isEmpty)
            const Center(
              child: Text('Нет устройств', style: TextStyle(color: Colors.white54)),
            )
          else
            ...hub.devices.map(
              (device) => Card(
                color: AppColors.secodnBg,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onDoubleTap: () {
                    // Разрешаем переход только для управляемых типов устройств
                    final String? deviceTypeName = device.parameters['type']?.toString().toLowerCase();
                    if (deviceTypeName == 'light' || deviceTypeName == 'switch') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeviceControlScreen(
                            device: device,
                            // *** ИСПОЛЬЗУЕМ НОВОЕ ПОЛЕ commandHubId ***
                            hubId: hub.commandHubId, // <-- Это должно быть "isshub_ccc2ddbc"
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Для ${device.name} нет подробного управления.', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.blueGrey,
                        ),
                      );
                    }
                  },
                  child: ExpansionTile(
                    iconColor: AppColors.primary,
                    collapsedIconColor: Colors.white,
                    backgroundColor: AppColors.secodnBg,
                    collapsedBackgroundColor: AppColors.secodnBg,
                    title: Text(
                      // Отображаем type, если есть, иначе name
                      (device.parameters['type']?.toString().isNotEmpty == true)
                          ? _capitalizeFirstLetter(device.parameters['type'].toString())
                          : device.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Название: ${device.name}', // Всегда показываем device.name
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Последнее обновление: ${dateFormat.format(device.lastUpdate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: device.parameters.entries.map((entry) {
                      final key = entry.key;
                      final value = entry.value;

                      // Исключаем 'name' и 'type' из списка параметров, так как они уже в заголовке/подзаголовке
                      if (key.toLowerCase() == 'name' || key.toLowerCase() == 'type') {
                        return const SizedBox.shrink(); // Не отображаем
                      }

                      return ListTile(
                        leading: Icon(_getIconForParameter(key), color: AppColors.primary),
                        title: Text(
                          _capitalizeFirstLetter(key), // Капитализируем ключ для читабельности
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          value.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Вспомогательная функция для преобразования первой буквы в заглавную
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Пример простого экрана управления устройством
class DeviceControlScreen extends StatefulWidget {
  final Device device;
  final String hubId; // Этот hubId теперь ДОЛЖЕН быть "isshub_ccc2ddbc"

  const DeviceControlScreen({Key? key, required this.device, required this.hubId}) : super(key: key);

  @override
  _DeviceControlScreenState createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late WebSocketChannel channel;
  bool isConnected = false;
  bool isOn = false;
  int brightness = 0;

  // Вспомогательный метод для безопасного преобразования в int
  // Улучшенная версия для обработки строк, double и округления до int
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.round(); // Округляем double до ближайшего int
    } else if (value is String) {
      // Пытаемся парсить как int
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return intValue;
      }
      // Если не int, пытаемся парсить как double и округляем
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        return doubleValue.round();
      }
    }
    return 0; // Возвращаем 0, если не удалось распарсить
  }

  @override
  void initState() {
    super.initState();
    // Безопасное чтение 'state' и 'brightness' из параметров устройства
    // 'state' может быть 'true'/'false' (boolean) или "ON"/"OFF" (String)
    final dynamic deviceState = widget.device.parameters['state'];
    if (deviceState is bool) {
      isOn = deviceState;
    } else if (deviceState is String) {
      isOn = deviceState.toUpperCase() == 'ON';
    } else {
      isOn = false; // Значение по умолчанию
    }

    brightness = _safeParseInt(widget.device.parameters['brightness']);
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    if (token != null && token.startsWith('Bearer ')) {
      token = token.substring(7);
    }
    if (token == null || token.isEmpty) {
      print('Ошибка: Токен доступа не найден или пуст.');
      setState(() => isConnected = false);
      return;
    }

    final url = 'wss://cms.iss-control.kz:8443/ws?token=$token';
    try {
      channel = WebSocketChannel.connect(Uri.parse(url));

      channel.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'DEVICE_STATE_UPDATE' && data['details'] != null) {
            final details = data['details'];
            // Проверяем по deviceId (который является widget.device.id для получения обновлений)
            if (details['deviceId'] == widget.device.id) { // Используем device.id для идентификации обновлений
              setState(() {
                final dynamic payloadState = details['payload']['state'];
                if (payloadState is bool) {
                  isOn = payloadState;
                } else if (payloadState is String) {
                  isOn = payloadState.toUpperCase() == 'ON';
                }
                brightness = _safeParseInt(details['payload']['brightness']);
              });
            }
          }
        },
        onDone: () {
          setState(() => isConnected = false);
          print('WebSocket соединение закрыто.');
        },
        onError: (error) {
          setState(() => isConnected = false);
          print('WebSocket ошибка: $error');
        },
      );

      setState(() {
        isConnected = true;
      });
    } catch (e) {
      print('Ошибка при подключении к WebSocket: $e');
      setState(() => isConnected = false);
    }
  }

  void _sendCommand(Map<String, dynamic> payload) {
    if (channel.sink != null) {
      final command = {
        "type": "DEVICE_COMMAND",
        "hubId": widget.hubId, // Это должно быть "isshub_ccc2ddbc"
        "details": {
          "deviceId": widget.device.name, // Это "0x187a3efffec75c30" или "0xa4c13813c18af0fc"
          "payload": payload,
        }
      };
      print('Отправка команды: ${jsonEncode(command)}'); // Для отладки
      channel.sink.add(jsonEncode(command));
    } else {
      print('WebSocket канал не инициализирован. Не удалось отправить команду.');
    }
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Определяем тип устройства для условного отображения элементов управления
    final String? deviceTypeName = widget.device.parameters['type']?.toString().toLowerCase();
    bool showBrightnessControl = deviceTypeName == 'light';
    bool showOnOffSwitch = deviceTypeName == 'light' || deviceTypeName == 'switch'; // 'switch' для умных розеток

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: AppColors.secodnBg,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (showOnOffSwitch) ...[
              SwitchListTile(
                title: const Text('Вкл/Выкл', style: TextStyle(color: Colors.white)),
                value: isOn,
                onChanged: (value) {
                  setState(() => isOn = value);
                  _sendCommand({"state": value ? "ON" : "OFF"});
                },
                activeColor: AppColors.primary,
                inactiveTrackColor: Colors.white24,
              ),
            ],
            if (showBrightnessControl) ...[
              const SizedBox(height: 20),
              Text('Яркость: $brightness', style: const TextStyle(color: Colors.white)),
              Slider(
                value: brightness.toDouble(),
                min: 0,
                max: 255,
                divisions: 255,
                activeColor: AppColors.primary,
                inactiveColor: Colors.white24,
                onChanged: (value) {
                  setState(() => brightness = value.toInt());
                  _sendCommand({"brightness": brightness});
                },
              ),
            ],
            if (!showOnOffSwitch && !showBrightnessControl)
              const Text(
                'Для этого типа устройства нет доступных элементов управления.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            isConnected
                ? const Text('Соединение активно', style: TextStyle(color: Colors.green))
                : const Text('Соединение отсутствует', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}
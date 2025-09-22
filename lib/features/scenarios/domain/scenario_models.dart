// lib/features/scenarios/domain/scenario_models.dart
import 'dart:convert';

class Scenario {
  final String id;
  final ScenarioJson json;
  final DateTime createdAt;
  final DateTime updatedAt;

  Scenario({
    required this.id,
    required this.json,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
    id: j['id'] as String,
    json: ScenarioJson.fromJson(j['jsonData'] as Map<String, dynamic>),
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );
}

class ScenarioJson {
  final String name;
  final String hubId;
  final bool enabled;
  final List<ScenarioBlock> triggers;
  final List<ScenarioBlock> conditions;
  final List<ScenarioBlock> actions;

  ScenarioJson({
    required this.name,
    required this.hubId,
    required this.enabled,
    required this.triggers,
    required this.conditions,
    required this.actions,
  });

  factory ScenarioJson.fromJson(Map<String, dynamic> j) => ScenarioJson(
    name: j['name'] as String? ?? '',
    hubId: j['hubId'] as String? ?? '',
    enabled: j['enabled'] as bool? ?? true,
    triggers:
        (j['triggers'] as List? ?? [])
            .map((e) => ScenarioBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
    conditions:
        (j['conditions'] as List? ?? [])
            .map((e) => ScenarioBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
    actions:
        (j['actions'] as List? ?? [])
            .map((e) => ScenarioBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'hubId': hubId,
    'enabled': enabled,
    'triggers': triggers.map((e) => e.toJson()).toList(),
    'conditions': conditions.map((e) => e.toJson()).toList(),
    'actions': actions.map((e) => e.toJson()).toList(),
  };

  String toRaw() => jsonEncode(toJson());
}

class ScenarioBlock {
  final String type; // e.g. 'device.attribute', 'time.range', 'device.set'
  final Map<String, dynamic> params;

  ScenarioBlock({required this.type, required this.params});

  factory ScenarioBlock.fromJson(Map<String, dynamic> j) => ScenarioBlock(
    type: j['type'] as String,
    params: (j['params'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (params.isNotEmpty) 'params': params,
  };
}

class ScenarioTemplate {
  final String id;
  final String key;
  final String name;
  final String? description;
  final String triggerDeviceType; // e.g. MOTION
  final String actionDeviceType; // e.g. SWITCH
  final int? version;
  final String? scenarioJsonTemplateRaw; // приходит как строка

  ScenarioTemplate({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    required this.triggerDeviceType,
    required this.actionDeviceType,
    this.version,
    this.scenarioJsonTemplateRaw,
  });

  Map<String, dynamic>? get scenarioJsonTemplate =>
      scenarioJsonTemplateRaw == null
          ? null
          : jsonDecode(scenarioJsonTemplateRaw!);

  factory ScenarioTemplate.fromJson(Map<String, dynamic> j) => ScenarioTemplate(
    id: j['id']?.toString() ?? '',
    key: j['key'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    triggerDeviceType: j['triggerDeviceType'] as String,
    actionDeviceType: j['actionDeviceType'] as String,
    version: j['version'] as int?,
    scenarioJsonTemplateRaw: j['scenarioJsonTemplate']?.toString(),
  );
}

class DeviceSummary {
  final String id; // внутренний UUID
  final String name; // ieee/friendly, ЭТО отправляем как deviceId/deviceName
  final String? title; // может быть null/пустой
  final String deviceCategory;
  final String? roomId;
  final String? roomName;
  final DateTime? lastUpdate;

  DeviceSummary({
    required this.id,
    required this.name,
    required this.title,
    required this.deviceCategory,
    this.roomId,
    this.roomName,
    this.lastUpdate,
  });

  String get displayTitle =>
      (title != null && title!.trim().isNotEmpty) ? title!.trim() : name;

  factory DeviceSummary.fromJson(Map<String, dynamic> j) {
    DateTime? lu;
    final raw = j['lastUpdate'];
    if (raw is String && raw.isNotEmpty) {
      try {
        lu = DateTime.parse(raw);
      } catch (_) {}
    }
    final room = j['room'] as Map?;
    return DeviceSummary(
      id: j['id'] as String,
      name: (j['name'] as String?)?.trim() ?? '',
      title: (j['title'] as String?),
      deviceCategory: (j['deviceCategory'] as String?) ?? '',
      roomId: room?['id'] as String?,
      roomName: room?['name'] as String?,
      lastUpdate: lu,
    );
  }
}

/// Маппинг типов шаблонов → категорий API
String mapTemplateTypeToDeviceCategory(String t) {
  switch (t.toUpperCase()) {
    case 'MOTION':
      return 'MOTION_SENSOR';
    case 'CONTACT':
      return 'CONTACT_SENSOR';
    case 'TEMPERATURE':
      return 'TEMPERATURE_SENSOR';
    case 'HUMIDITY':
      return 'HUMIDITY_SENSOR';
    case 'ILLUMINANCE':
      return 'ILLUMINANCE_SENSOR';
    case 'LEAK':
      return 'LEAK_SENSOR';
    case 'SMOKE':
      return 'SMOKE_SENSOR';
    case 'CO2':
      return 'CO2_SENSOR';
    case 'VIBRATION':
      return 'VIBRATION_SENSOR';
    case 'BUTTON':
      return 'BUTTON';
    case 'PRESENCE':
      return 'PRESENCE_SENSOR';
    case 'SWITCH':
    case 'LIGHT':
    case 'SMART_PLUG':
    case 'RELAY':
    case 'LIGHT_SWITCH':
      return 'LIGHT_SWITCH';
    default:
      return t.toUpperCase();
  }
}

class CreateFromTemplateRequest {
  final String hubId;
  final List<String> triggerDevices;
  final List<String> actionDevices;

  CreateFromTemplateRequest({
    required this.hubId,
    required this.triggerDevices,
    required this.actionDevices,
  });

  Map<String, dynamic> toJson() => {
    'hubId': hubId,
    'triggerDevices': triggerDevices,
    'actionDevices': actionDevices,
  };
}

class CreateFromTemplateResult {
  final String scenarioId;
  final String hubId;
  final String templateKey;
  final String name;
  final ScenarioJson scenario;

  CreateFromTemplateResult({
    required this.scenarioId,
    required this.hubId,
    required this.templateKey,
    required this.name,
    required this.scenario,
  });

  factory CreateFromTemplateResult.fromJson(Map<String, dynamic> j) =>
      CreateFromTemplateResult(
        scenarioId: j['scenarioId'] as String,
        hubId: j['hubId'] as String,
        templateKey: j['templateKey'] as String,
        name: j['name'] as String,
        scenario: ScenarioJson.fromJson(j['scenario'] as Map<String, dynamic>),
      );
}

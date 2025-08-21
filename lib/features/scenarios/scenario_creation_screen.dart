// lib/features/scenarios/scenario_creation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/providers/hubs_provider.dart';
import 'package:ISS/features/scenarios/scenario_service.dart';
// --- 1. ДОБАВЛЯЕМ ИМПОРТ НОВЫХ МОДЕЛЕЙ ---
import 'package:ISS/models/device_models.dart';

// --- Модели данных для сценария ---
// (Они остаются без изменений, так как определяют структуру JSON для сервера)
class ScenarioTrigger {
  String type;
  String deviceName; // На сервере это ID устройства
  String attribute;
  String op;
  String value;
  ScenarioTrigger({
    required this.type,
    required this.deviceName,
    required this.attribute,
    required this.op,
    required this.value,
  });
  Map<String, dynamic> toJson() => {
    "type": type,
    "deviceName": deviceName,
    "attribute": attribute,
    "op": op,
    "value": value,
  };
}

class ScenarioCondition {
  String deviceName;
  String attribute;
  String op;
  String value;
  ScenarioCondition({
    required this.deviceName,
    required this.attribute,
    required this.op,
    required this.value,
  });
  Map<String, dynamic> toJson() => {
    "deviceName": deviceName,
    "attribute": attribute,
    "op": op,
    "value": value,
  };
}

class ScenarioAction {
  String deviceName;
  String commandJson;
  ScenarioAction({required this.deviceName, required this.commandJson});
  Map<String, dynamic> toJson() => {
    "deviceName": deviceName,
    "commandJson": commandJson,
  };
}

class ScenarioCreationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialScenario;
  const ScenarioCreationScreen({super.key, this.initialScenario});

  @override
  ConsumerState<ScenarioCreationScreen> createState() =>
      _ScenarioCreationScreenState();
}

class _ScenarioCreationScreenState
    extends ConsumerState<ScenarioCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scenarioNameController = TextEditingController();

  HubObject? _selectedHub;
  bool _isEnabled = true;
  bool _isLoading = false;

  final List<ScenarioTrigger> _triggers = [];
  final List<ScenarioCondition> _conditions = [];
  final List<ScenarioAction> _actions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialScenario != null) {
      _parseInitialScenario();
    }
  }

  // --- ЛОГИКА ПАРСИНГА СЦЕНАРИЯ ОСТАЕТСЯ БЕЗ ИЗМЕНЕНИЙ ---
  void _parseInitialScenario() {
    final jsonData =
        widget.initialScenario!['jsonData'] ?? widget.initialScenario;
    if (jsonData == null) return;
    _scenarioNameController.text = jsonData['name'] ?? '';
    _isEnabled = jsonData['enabled'] ?? true;
    if (jsonData['triggers'] is List) {
      _triggers.addAll(
        (jsonData['triggers'] as List).map(
          (e) => ScenarioTrigger(
            type: e['type'] ?? '',
            deviceName: e['deviceName'] ?? '',
            attribute: e['attribute'] ?? '',
            op: e['op'] ?? '',
            value: e['value'] ?? '',
          ),
        ),
      );
    }
    if (jsonData['conditions'] is List) {
      _conditions.addAll(
        (jsonData['conditions'] as List).map(
          (e) => ScenarioCondition(
            deviceName: e['deviceName'] ?? '',
            attribute: e['attribute'] ?? '',
            op: e['op'] ?? '',
            value: e['value'] ?? '',
          ),
        ),
      );
    }
    if (jsonData['actions'] is List) {
      _actions.addAll(
        (jsonData['actions'] as List).map(
          (e) => ScenarioAction(
            deviceName: e['deviceName'] ?? '',
            commandJson: e['commandJson'] ?? '',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scenarioNameController.dispose();
    super.dispose();
  }

  void _addTrigger() => setState(
    () => _triggers.add(
      ScenarioTrigger(
        type: 'device',
        deviceName: '',
        attribute: 'occupancy',
        op: '==',
        value: 'true',
      ),
    ),
  );
  void _addCondition() => setState(
    () => _conditions.add(
      ScenarioCondition(deviceName: '', attribute: '', op: '==', value: ''),
    ),
  );
  void _addAction() => setState(
    () => _actions.add(
      ScenarioAction(deviceName: '', commandJson: '{"state":"ON"}'),
    ),
  );

  Future<void> _saveScenario() async {
    final localizations = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseSelectHub),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final scenarioService = ref.read(scenarioServiceProvider);
    final success = await scenarioService.saveScenario(
      name: _scenarioNameController.text.trim(),
      hubId: _selectedHub!.commandHubId,
      enabled: _isEnabled,
      triggers: _triggers,
      conditions: _conditions,
      actions: _actions,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.scenarioSavedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.scenarioSaveFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final hubsAsyncValue = ref.watch(hubsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialScenario == null
              ? localizations.createScenarioTitle
              : localizations.editScenarioTitle,
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child:
                _isLoading
                    ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: localizations.saveScenarioButton,
                      onPressed: _saveScenario,
                    ),
          ),
        ],
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: hubsAsyncValue.when(
        data: (hubs) {
          if (_selectedHub == null && hubs.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedHub = hubs.first);
            });
          }
          if (_selectedHub == null && hubs.isEmpty) {
            return Center(child: Text(localizations.noHubsFound));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _scenarioNameController,
                    decoration: _commonInputDecoration(
                      labelText: localizations.scenarioNameLabel,
                      hintText: localizations.scenarioNameHint,
                      context: context,
                    ),
                    style: AppStyles.bodyText1(context),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? localizations.scenarioNameCannotBeEmpty
                                : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<HubObject>(
                    initialValue: _selectedHub,
                    decoration: _commonInputDecoration(
                      labelText: localizations.selectHubLabel,
                      context: context,
                    ),
                    items:
                        hubs
                            .map(
                              (hub) => DropdownMenuItem(
                                value: hub,
                                child: Text(hub.facilityName),
                              ),
                            )
                            .toList(),
                    onChanged: (hub) => setState(() => _selectedHub = hub),
                    validator:
                        (value) =>
                            value == null
                                ? localizations.pleaseSelectHub
                                : null,
                    dropdownColor: AppColors.getCardBackgroundColor(context),
                    style: AppStyles.bodyText1(context),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    context,
                    localizations.triggersTitle,
                    _addTrigger,
                    localizations.addTriggerButton,
                  ),
                  const SizedBox(height: 10),
                  ..._triggers.asMap().entries.map(
                    (entry) =>
                        _buildTriggerCard(context, entry.value, entry.key),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    context,
                    localizations.conditionsTitle,
                    _addCondition,
                    localizations.addConditionButton,
                  ),
                  const SizedBox(height: 10),
                  ..._conditions.asMap().entries.map(
                    (entry) =>
                        _buildConditionCard(context, entry.value, entry.key),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    context,
                    localizations.actionsTitle,
                    _addAction,
                    localizations.addActionbutton,
                  ),
                  const SizedBox(height: 10),
                  ..._actions.asMap().entries.map(
                    (entry) =>
                        _buildActionCard(context, entry.value, entry.key),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading hubs: $err')),
      ),
    );
  }

  // --- 2. ЭТОТ ГЕТТЕР ТЕПЕРЬ ВОЗВРАЩАЕТ ПРАВИЛЬНЫЙ ТИП ---
  List<BaseDevice> get _devicesForSelectedHub => _selectedHub?.devices ?? [];

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onAdd,
    String addButtonLabel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppStyles.headline4(context)),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: Text(addButtonLabel),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryAccent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  // --- 3. ИЗМЕНЕНЫ DROPDOWNMENUITEM В КАРТОЧКАХ ---
  Widget _buildTriggerCard(
    BuildContext context,
    ScenarioTrigger trigger,
    int index,
  ) {
    final localizations = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.getCardBackgroundColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(
              context,
              localizations.triggerLabel(index + 1),
              () => setState(() => _triggers.removeAt(index)),
            ),
            DropdownButtonFormField<String>(
              initialValue: trigger.deviceName.isEmpty ? null : trigger.deviceName,
              hint: Text(localizations.selectDevice),
              decoration: _commonInputDecoration(
                labelText: localizations.deviceNameLabel,
                context: context,
              ),
              items:
                  _devicesForSelectedHub
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.friendlyName),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) => setState(() => trigger.deviceName = value ?? ''),
              style: AppStyles.bodyText1(context),
              dropdownColor: AppColors.getCardBackgroundColor(context),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: trigger.attribute,
              decoration: _commonInputDecoration(
                labelText: localizations.attributeLabel,
                context: context,
              ),
              onChanged: (value) => trigger.attribute = value,
              style: AppStyles.bodyText1(context),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: trigger.op,
              decoration: _commonInputDecoration(
                labelText: localizations.operatorLabel,
                context: context,
              ),
              onChanged: (value) => trigger.op = value,
              style: AppStyles.bodyText1(context),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: trigger.value,
              decoration: _commonInputDecoration(
                labelText: localizations.valueLabel,
                context: context,
              ),
              onChanged: (value) => trigger.value = value,
              style: AppStyles.bodyText1(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(
    BuildContext context,
    ScenarioCondition condition,
    int index,
  ) {
    final localizations = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.getCardBackgroundColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(
              context,
              localizations.conditionLabel(index + 1),
              () => setState(() => _conditions.removeAt(index)),
            ),
            DropdownButtonFormField<String>(
              // --- ИЗМЕНЕНО ---
              initialValue: condition.deviceName.isEmpty ? null : condition.deviceName,
              hint: Text(localizations.selectDevice),
              decoration: _commonInputDecoration(
                labelText: localizations.deviceNameLabel,
                context: context,
              ),
              items:
                  _devicesForSelectedHub
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.friendlyName),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) => setState(() => condition.deviceName = value ?? ''),
              style: AppStyles.bodyText1(context),
              dropdownColor: AppColors.getCardBackgroundColor(context),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: condition.attribute,
              decoration: _commonInputDecoration(
                labelText: localizations.attributeLabel,
                context: context,
              ),
              onChanged: (value) => condition.attribute = value,
              style: AppStyles.bodyText1(context),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: condition.op,
              decoration: _commonInputDecoration(
                labelText: localizations.operatorLabel,
                context: context,
              ),
              onChanged: (value) => condition.op = value,
              style: AppStyles.bodyText1(context),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: condition.value,
              decoration: _commonInputDecoration(
                labelText: localizations.valueLabel,
                context: context,
              ),
              onChanged: (value) => condition.value = value,
              style: AppStyles.bodyText1(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ScenarioAction action,
    int index,
  ) {
    final localizations = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.getCardBackgroundColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(
              context,
              localizations.actionLabel(index + 1),
              () => setState(() => _actions.removeAt(index)),
            ),
            DropdownButtonFormField<String>(
              initialValue: action.deviceName.isEmpty ? null : action.deviceName,
              hint: Text(localizations.selectDevice),
              decoration: _commonInputDecoration(
                labelText: localizations.deviceNameLabel,
                context: context,
              ),
              items:
                  _devicesForSelectedHub
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.friendlyName),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) => setState(() => action.deviceName = value ?? ''),
              style: AppStyles.bodyText1(context),
              dropdownColor: AppColors.getCardBackgroundColor(context),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: action.commandJson,
              decoration: _commonInputDecoration(
                labelText: localizations.commandLabel,
                hintText: '{"state":"ON"}',
                context: context,
              ),
              onChanged: (value) => action.commandJson = value,
              style: AppStyles.bodyText1(context),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    String title,
    VoidCallback onDelete,
  ) {
    final localizations = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppStyles.headline5(context)),
        IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
          tooltip: localizations.delete,
        ),
      ],
    );
  }

  InputDecoration _commonInputDecoration({
    required String labelText,
    String? hintText,
    required BuildContext context,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: AppStyles.bodyText2(context),
      hintStyle: AppStyles.caption(context),
      filled: true,
      fillColor: AppColors.getCardBackgroundColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide(
          color: AppColors.getBorderGrayColor(context),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide(color: AppColors.primaryAccent, width: 2.0),
      ),
    );
  }
}

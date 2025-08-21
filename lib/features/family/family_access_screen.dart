import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/l10n/app_localizations.dart';

// ВАЖНО: провайдеры семейного доступа — из providers/*
import 'package:ISS/providers/family_group_providers.dart' as fprov;
// Твои хабы (личные) — как были
import 'package:ISS/providers/hubs_provider.dart' as hprov;

class FamilyAccessScreen extends ConsumerStatefulWidget {
  const FamilyAccessScreen({super.key});

  @override
  ConsumerState<FamilyAccessScreen> createState() => _FamilyAccessScreenState();
}

class _FamilyAccessScreenState extends ConsumerState<FamilyAccessScreen> {
  // --- создание группы ---
  final _groupNameCtrl = TextEditingController();
  final _inviteEmailCtrl = TextEditingController();
  String _selectedHubForCreate = ''; // hubId (опционально при создании)

  // --- временные контроллеры для действий внутри группы ---
  final _renameCtrl = TextEditingController();
  final _memberEmailCtrl = TextEditingController();
  String _newRole = 'USER'; // ADMIN/USER
  final _transferUserIdCtrl = TextEditingController();
  final _attachHubIdCtrl = TextEditingController();

  bool _busy = false;

  Future<void> _createGroup() async {
    if (_busy) return;
    final name = _groupNameCtrl.text.trim();
    final email = _inviteEmailCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);
    try {
      final body = {
        'name': name,
        'emails': email.isNotEmpty ? [email] : [],
        if (_selectedHubForCreate.isNotEmpty) 'hubId': _selectedHubForCreate,
      };
      await dio.post('/family-group/create', data: body);

      if (!mounted) return;
      _groupNameCtrl.clear();
      _inviteEmailCtrl.clear();
      _selectedHubForCreate = '';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Группа создана')));
      ref.invalidate(fprov.familyGroupsProvider);
      // список хабов подтянем уже при раскрытии конкретной группы
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка создания: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // --- действия по группе (id) ---
  Future<void> _updateGroupName(String groupId, String newName) async {
    if (newName.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await dio.put(
        '/family-group/$groupId/update-group-name',
        queryParameters: {'name': newName.trim()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Имя группы изменено')));
      ref.invalidate(fprov.familyGroupsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addMember(String groupId, String email, String role) async {
    if (email.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await dio.post(
        '/family-group/add-member/$groupId',
        data: {'email': email.trim(), 'role': role}, // ADMIN / USER
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Участник добавлен')));
      // состав группы обычно приходит вместе с /family-group
      ref.invalidate(fprov.familyGroupsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteMember(String groupId, String memberId) async {
    setState(() => _busy = true);
    try {
      // твой текущий бекенд может ожидать другой маршрут (например: /family-group/{memberId}/delete-member)
      // оставляю как у тебя — через query memberId
      await dio.delete(
        '/family-group/$groupId/delete-member',
        queryParameters: {'memberId': memberId},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Участник удалён')));
      ref.invalidate(fprov.familyGroupsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateRole(String groupId, String memberId, String role) async {
    setState(() => _busy = true);
    try {
      // у тебя в описании было /family-group/{memberId}/update-member-role,
      // но в исходном коде ты дергал /family-group/$groupId/update-member-role?memberId=...
      // Оставляю как в твоём коде, чтобы не ломать текущий бекенд.
      await dio.put(
        '/family-group/$groupId/update-member-role',
        queryParameters: {'memberId': memberId, 'role': role},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Роль изменена на $role')));
      ref.invalidate(fprov.familyGroupsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transferOwner(String groupId, String newOwnerUserId) async {
    if (newOwnerUserId.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await dio.post(
        '/family-group/$groupId/transfer-ownership/$newOwnerUserId',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Владение передано')));
      ref.invalidate(fprov.familyGroupsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attachHub(String groupId, String hubId) async {
    if (hubId.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await dio.post('/family-group/$groupId/hub/$hubId/attach');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Хаб прикреплён')));
      ref.invalidate(
        fprov.familyHubsProvider(groupId),
      ); // ТОЛЬКО для этой группы
      ref.invalidate(hprov.hubsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _detachHub(String groupId, String hubId) async {
    setState(() => _busy = true);
    try {
      await dio.post('/family-group/$groupId/hub/$hubId/dettach');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Хаб откреплён')));
      ref.invalidate(fprov.familyHubsProvider(groupId));
      ref.invalidate(hprov.hubsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _armSecurity(String groupId, String hubId) async {
    setState(() => _busy = true);
    try {
      await dio.post('/family-group/$groupId/arm-security/$hubId');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Поставлено на охрану')));
      ref.invalidate(fprov.familyHubsProvider(groupId));
      ref.invalidate(hprov.hubsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disarmSecurity(String groupId, String hubId) async {
    setState(() => _busy = true);
    try {
      await dio.post('/family-group/$groupId/disarm-security/$hubId');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Снято с охраны')));
      ref.invalidate(fprov.familyHubsProvider(groupId));
      ref.invalidate(hprov.hubsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final groupsAsync = ref.watch(fprov.familyGroupsProvider);
    final ownHubsAsync = ref.watch(hprov.hubsProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(title: const Text('Семейный доступ')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fprov.familyGroupsProvider);
          ref.invalidate(hprov.hubsProvider);
          await Future.wait([
            ref.read(fprov.familyGroupsProvider.future),
            ref.read(hprov.hubsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // === 1. Создание группы ===
            Text('Создать группу', style: AppStyles.headline3(context)),
            const SizedBox(height: 8),
            Container(
              decoration: AppStyles.cardDecoration(context),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _groupNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Название группы',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inviteEmailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Пригласить (email, опционально)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ownHubsAsync.when(
                    data: (hubs) {
                      return DropdownButtonFormField<String>(
                        initialValue:
                            _selectedHubForCreate.isEmpty
                                ? null
                                : _selectedHubForCreate,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Прикрепить хаб (опционально)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('— не прикреплять —'),
                          ),
                          ...hubs.map(
                            (h) => DropdownMenuItem(
                              value: h.commandHubId,
                              child: Text(h.facilityName),
                            ),
                          ),
                        ],
                        onChanged:
                            (v) =>
                                setState(() => _selectedHubForCreate = v ?? ''),
                      );
                    },
                    error: (_, __) => const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _createGroup,
                      child:
                          _busy
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Создать'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // === 2. Мои группы ===
            Text('Мои группы', style: AppStyles.headline3(context)),
            const SizedBox(height: 8),
            groupsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return _emptyBox(context, 'Групп нет');
                }
                return Column(
                  children:
                      list.map((g) {
                        final groupId = (g['id'] ?? '').toString();
                        final name = (g['name'] ?? 'Без имени').toString();
                        final members = (g['members'] as List?) ?? const [];

                        return _groupCard(context, groupId, name, members);
                      }).toList(),
                );
              },
              loading: () => _loadingCard(context),
              error: (e, _) => _errorCard(context, e),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI helpers for groups ---

  Widget _groupCard(
    BuildContext context,
    String groupId,
    String name,
    List members,
  ) {
    final hubsAsync = ref.watch(fprov.familyHubsProvider(groupId));

    return Card(
      color: AppColors.getCardBackgroundColor(context),
      child: ExpansionTile(
        title: Text(
          name,
          style: AppStyles.bodyText1(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('ID: $groupId'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // Переименование
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _renameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Новое имя группы',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _busy
                        ? null
                        : () => _updateGroupName(groupId, _renameCtrl.text),
                child: const Text('Переименовать'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Добавить участника
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _memberEmailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email участника',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _newRole,
                items: const [
                  DropdownMenuItem(value: 'USER', child: Text('USER')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                ],
                onChanged: (v) => setState(() => _newRole = v ?? 'USER'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _busy
                        ? null
                        : () => _addMember(
                          groupId,
                          _memberEmailCtrl.text,
                          _newRole,
                        ),
                child: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Участники
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Участники', style: AppStyles.bodyText1(context)),
          ),
          const SizedBox(height: 8),
          ...members.map((m) {
            final userId = (m['id'] ?? '').toString();
            final uname = (m['name'] ?? '—').toString();
            final role = (m['role'] ?? 'USER').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: AppStyles.cardDecoration(context),
              child: ListTile(
                title: Text(uname, style: AppStyles.bodyText1(context)),
                subtitle: Text('id: $userId • role: $role'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    PopupMenuButton<String>(
                      itemBuilder:
                          (ctx) => const [
                            PopupMenuItem(
                              value: 'USER',
                              child: Text('Сделать USER'),
                            ),
                            PopupMenuItem(
                              value: 'ADMIN',
                              child: Text('Сделать ADMIN'),
                            ),
                          ],
                      onSelected: (r) => _updateRole(groupId, userId, r),
                      child: const Icon(Icons.admin_panel_settings_outlined),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteMember(groupId, userId),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Управление хабами группы (attach/detach/arm/disarm)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Хабы группы', style: AppStyles.bodyText1(context)),
          ),
          const SizedBox(height: 8),

          // Список хабов (по провайдеру familyHubsProvider(groupId))
          hubsAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
            error:
                (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Ошибка загрузки хабов: $e',
                    style: AppStyles.bodyText2(
                      context,
                    ).copyWith(color: Colors.red),
                  ),
                ),
            data: (hubs) {
              if (hubs.isEmpty) {
                return _emptyBox(context, 'Хабов нет');
              }
              return Column(
                children:
                    hubs.map<Widget>((h) {
                      final hid = (h['id'] ?? h['hubId'] ?? '').toString();
                      final hname =
                          (h['facilityName'] ?? h['name'] ?? 'Без имени')
                              .toString();
                      final isConnected = (h['isConnected'] ?? false) == true;
                      final isOnMon = (h['isOnMonitoring'] ?? false) == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: AppStyles.cardDecoration(context),
                        child: ListTile(
                          title: Text(
                            hname,
                            style: AppStyles.bodyText1(context),
                          ),
                          subtitle: Text(
                            'id: $hid • conn: ${isConnected ? "online" : "offline"} • mon: ${isOnMon ? "on" : "off"}',
                            style: AppStyles.bodyText2(context),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'ARM',
                                icon: const Icon(Icons.security_rounded),
                                onPressed:
                                    _busy
                                        ? null
                                        : () => _armSecurity(groupId, hid),
                              ),
                              IconButton(
                                tooltip: 'DISARM',
                                icon: const Icon(Icons.lock_open_rounded),
                                onPressed:
                                    _busy
                                        ? null
                                        : () => _disarmSecurity(groupId, hid),
                              ),
                              IconButton(
                                tooltip: 'Detach',
                                icon: const Icon(Icons.link_off_rounded),
                                onPressed:
                                    _busy
                                        ? null
                                        : () => _detachHub(groupId, hid),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),

          const SizedBox(height: 8),

          // Быстрые действия по введённому hubId
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _attachHubIdCtrl,
                  decoration: const InputDecoration(labelText: 'HubId'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _busy
                        ? null
                        : () => _attachHub(groupId, _attachHubIdCtrl.text),
                child: const Text('Attach'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _busy
                        ? null
                        : () => _detachHub(groupId, _attachHubIdCtrl.text),
                child: const Text('Detach'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.security_rounded),
                onPressed:
                    _busy
                        ? null
                        : () => _armSecurity(groupId, _attachHubIdCtrl.text),
                label: const Text('ARM'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open_rounded),
                onPressed:
                    _busy
                        ? null
                        : () => _disarmSecurity(groupId, _attachHubIdCtrl.text),
                label: const Text('DISARM'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Передача владения
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _transferUserIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'UserId нового владельца',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _busy
                        ? null
                        : () =>
                            _transferOwner(groupId, _transferUserIdCtrl.text),
                child: const Text('Передать'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(context),
      child: Center(child: Text(text, style: AppStyles.bodyText2(context))),
    );
  }

  Widget _loadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(context),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorCard(BuildContext context, Object e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(context),
      child: Center(
        child: Text(
          'Ошибка: $e',
          style: AppStyles.bodyText2(context).copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

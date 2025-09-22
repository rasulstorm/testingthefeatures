import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/providers/family_group_providers.dart';
import 'package:ISS/providers/hubs_provider.dart' as hubs;
import 'package:ISS/services/family_group_service.dart';

class FamilyAccessScreen extends ConsumerStatefulWidget {
  const FamilyAccessScreen({super.key});

  @override
  ConsumerState<FamilyAccessScreen> createState() => _FamilyAccessScreenState();
}

class _FamilyAccessScreenState extends ConsumerState<FamilyAccessScreen> {
  String? _selectedGroupId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final groupsAsync = ref.watch(familyGroupsProvider);
    final activeState = ref.watch(activeFamilyGroupStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.familyAccess),
        actions: [
          if (activeState.isActive)
            TextButton(
              onPressed:
                  _isProcessing
                      ? null
                      : () {
                          ref.read(activeFamilyGroupStateProvider.notifier).clear();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.familyAccessPersonalModeActivated)),
                          );
                        },
              child: Text(
                loc.familyAccessSwitchToPersonal,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      floatingActionButton: groupsAsync.maybeWhen(
        data: (_) => FloatingActionButton(
          mini: true,
          tooltip: loc.familyAccessCreateGroup,
          onPressed: _isProcessing ? null : _showCreateGroupDialog,
          child: const Icon(Icons.group_add_outlined),
        ),
        orElse: () => null,
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(familyGroupsProvider),
        ),
        data: (groups) => _buildDataBody(context, loc, groups, activeState),
      ),
    );
  }

  Widget _buildDataBody(
    BuildContext context,
    AppLocalizations loc,
    List<FamilyGroup> groups,
    ActiveFamilyGroupState activeState,
  ) {
    if (groups.isEmpty) {
      return _EmptyState(
        title: loc.familyAccessNoGroupsTitle,
        message: loc.familyAccessNoGroupsMessage,
        onCreate: _isProcessing ? null : _showCreateGroupDialog,
      );
    }

    _ensureSelection(groups, activeState);
    final selectedId = _selectedGroupId;
    if (selectedId == null) {
      return const SizedBox.shrink();
    }

    final detailsAsync = ref.watch(familyGroupDetailsProvider(selectedId));
    final hubsAsync = ref.watch(familyHubsProvider(selectedId));

    return RefreshIndicator(
      onRefresh: () async => _refreshAll(selectedId),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: _GroupSelector(
                loc: loc,
                groups: groups,
                selectedGroupId: selectedId,
                onSelect: (id) => setState(() => _selectedGroupId = id),
              ),
            ),
          ),
          detailsAsync.when(
            data: (group) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _GroupSummaryCard(
                    loc: loc,
                    group: group,
                    isProcessing: _isProcessing,
                    isActive: activeState.groupId == group.id,
                    role: group.currentUserRole ?? activeState.role,
                    membersCountLabel: loc.familyAccessMembersCount(group.members.length),
                    onActivate: () => _setActiveGroup(group, loc),
                    onRename: () => _renameGroup(group, loc),
                    onTransfer: () => _transferOwnership(group, loc),
                  ),
                  const SizedBox(height: 16),
                  _MembersCard(
                    loc: loc,
                    group: group,
                    isProcessing: _isProcessing,
                    role: group.currentUserRole ?? activeState.role,
                    onAddMember: () => _addMember(group, loc),
                    onChangeRole: (member, role) => _changeMemberRole(group, member, role, loc),
                    onRemoveMember: (member) => _removeMember(group, member, loc),
                  ),
                  if (group.invitations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InvitationsCard(
                      loc: loc,
                      invitations: group.invitations,
                    ),
                  ],
                  const SizedBox(height: 16),
                  hubsAsync.when(
                    data: (items) => _HubsCard(
                      loc: loc,
                      hubs: items,
                      isProcessing: _isProcessing,
                      role: group.currentUserRole ?? activeState.role,
                      allowUserDisarm: group.allowUserDisarm || activeState.allowUserDisarm,
                      onAttach: () => _attachHub(group, items, loc),
                      onDetach: (hub) => _detachHub(group, hub, loc),
                      onArm: (hub) => _armHub(group, hub, loc),
                      onDisarm: (hub) => _disarmHub(group, hub, loc),
                    ),
                    loading: () => const _ShadowCard(child: Center(child: CircularProgressIndicator())),
                    error: (error, _) => _ShadowCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.familyAccessHubsTitle,
                            style: AppStyles.bodyText1(context).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(error.toString()),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(familyGroupDetailsProvider(selectedId)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _ensureSelection(List<FamilyGroup> groups, ActiveFamilyGroupState activeState) {
    if (groups.isEmpty) return;
    final activeId = activeState.groupId;
    final current = _selectedGroupId;
    final desired =
        (activeId != null && groups.any((g) => g.id == activeId))
            ? activeId
            : (current != null && groups.any((g) => g.id == current))
                ? current
                : groups.first.id;
    if (desired != current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedGroupId = desired);
      });
    }
  }

  Future<void> _refreshAll([String? groupId]) async {
    ref.invalidate(familyGroupsProvider);
    if (groupId != null && groupId.isNotEmpty) {
      ref.invalidate(familyGroupDetailsProvider(groupId));
      ref.invalidate(familyHubsProvider(groupId));
    }
  }

  Future<void> _showCreateGroupDialog() async {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final emailsCtrl = TextEditingController();
    List<HubObject> ownedHubs;
    try {
      ownedHubs = await ref.read(hubs.hubsProvider.future);
    } catch (_) {
      ownedHubs = const [];
    }
    if (!mounted) return;

    String selectedHubId = '';
    bool busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: viewInsets > 0 ? viewInsets : 24,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.familyAccessCreateGroup, style: AppStyles.headline3(ctx)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: loc.familyAccessGroupNameLabel),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailsCtrl,
                      decoration: InputDecoration(labelText: loc.familyAccessInviteEmailsHint),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedHubId),
                      decoration: InputDecoration(labelText: loc.familyAccessAttachHubOptional),
                      initialValue: selectedHubId,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(loc.familyAccessAttachHubNone),
                        ),
                        ...ownedHubs.map(
                          (hub) => DropdownMenuItem(
                            value: hub.commandHubId,
                            child: Text(hub.facilityName.isEmpty ? hub.hubNumber : hub.facilityName),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedHubId = value ?? ''),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            busy
                                ? null
                                : () async {
                                    final name = nameCtrl.text.trim();
                                    if (name.isEmpty) return;
                                    setState(() => busy = true);
                                    try {
                                      final emails = emailsCtrl.text
                                          .split(',')
                                          .map((e) => e.trim())
                                          .where((element) => element.isNotEmpty)
                                          .toList();
                                      await familyGroupService.createGroup(
                                        name: name,
                                        emails: emails,
                                        hubId: selectedHubId.isEmpty ? null : selectedHubId,
                                      );
                                      if (!mounted || !sheetContext.mounted) return;
                                      Navigator.of(sheetContext).pop();
                                      await _refreshAll();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(loc.familyAccessGroupCreated)),
                                      );
                                    } catch (e) {
                                      setState(() => busy = false);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(_formatError(loc, e))),
                                      );
                                    }
                                  },
                        child: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(loc.familyAccessCreateAction),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _setActiveGroup(FamilyGroup group, AppLocalizations loc) async {
    ref.read(activeFamilyGroupStateProvider.notifier).setActiveGroup(
          groupId: group.id,
          role: group.currentUserRole,
          allowUserDisarm: group.allowUserDisarm,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.familyAccessGroupActivated(group.name))),
    );
  }

  Future<void> _renameGroup(FamilyGroup group, AppLocalizations loc) async {
    final controller = TextEditingController(text: group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.familyAccessRenameGroupTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: loc.familyAccessGroupNameLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(loc.save)),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == group.name) return;
    await _executeAction(
      () => familyGroupService.renameGroup(group.id, newName),
      group.id,
      success: loc.familyAccessGroupRenamed,
    );
  }

  Future<void> _addMember(FamilyGroup group, AppLocalizations loc) async {
    final emailCtrl = TextEditingController();
    FamilyRole role = FamilyRole.user;
    bool busy = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(loc.familyAccessInviteMemberTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: loc.familyAccessInviteEmailLabel),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FamilyRole>(
                key: ValueKey(role),
                initialValue: role,
                decoration: InputDecoration(labelText: loc.familyAccessRoleLabel),
                items: [
                  DropdownMenuItem(
                    value: FamilyRole.admin,
                    child: Text(loc.familyRoleAdmin),
                  ),
                  DropdownMenuItem(
                    value: FamilyRole.user,
                    child: Text(loc.familyRoleUser),
                  ),
                  DropdownMenuItem(
                    value: FamilyRole.guest,
                    child: Text(loc.familyRoleGuest),
                  ),
                ],
                onChanged: (value) => setState(() => role = value ?? FamilyRole.user),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
            TextButton(
              onPressed:
                  busy
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty) return;
                          setState(() => busy = true);
                          try {
                            await familyGroupService.addMember(
                              group.id,
                              email: email,
                              role: role,
                            );
                            if (!mounted || !ctx.mounted) return;
                            Navigator.pop(ctx);
                            await _refreshAll(group.id);
                            if (!mounted) return;
                            _showSnack(loc.familyAccessInvitationSent);
                          } catch (e) {
                            setState(() => busy = false);
                                _showSnack(_formatError(loc, e));
                          }
                        },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.familyAccessInviteAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeMemberRole(
    FamilyGroup group,
    FamilyMember member,
    FamilyRole role,
    AppLocalizations loc,
  ) async {
    if (member.role == role) return;
    await _executeAction(
      () => familyGroupService.updateMemberRole(member.id, role),
      group.id,
      success: loc.familyAccessRoleUpdated,
    );
  }

  Future<void> _removeMember(
    FamilyGroup group,
    FamilyMember member,
    AppLocalizations loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.familyAccessRemoveMemberTitle(member.name)),
        content: Text(loc.familyAccessRemoveMemberMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _executeAction(
      () => familyGroupService.deleteMember(member.id),
      group.id,
      success: loc.familyAccessMemberRemoved,
    );
  }

  Future<void> _transferOwnership(FamilyGroup group, AppLocalizations loc) async {
    final candidates = group.members.where((m) => !m.isOwner && m.isActive).toList();
    if (candidates.isEmpty) {
      _showSnack(loc.familyAccessNoTransferCandidates);
      return;
    }

    String selectedId = candidates.first.id;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.familyAccessTransferOwnershipTitle),
        content: DropdownButtonFormField<String>(
          key: ValueKey(selectedId),
          initialValue: selectedId,
          decoration: InputDecoration(labelText: loc.familyAccessSelectMemberLabel),
          items: candidates
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name),
                ),
              )
              .toList(),
          onChanged: (value) => selectedId = value ?? selectedId,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, selectedId), child: Text(loc.familyAccessTransferAction)),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await _executeAction(
      () => familyGroupService.transferOwnership(group.id, result),
      group.id,
      success: loc.familyAccessOwnershipTransferred,
    );
  }

  Future<void> _attachHub(
    FamilyGroup group,
    List<HubObject> attached,
    AppLocalizations loc,
  ) async {
    List<HubObject> available;
    try {
      available = await ref.read(hubs.hubsProvider.future);
    } catch (_) {
      available = const [];
    }
    if (!mounted) return;

    final used = attached.map((e) => e.commandHubId).toSet();
    final options = available.where((hub) => !used.contains(hub.commandHubId)).toList();
    if (options.isEmpty) {
      _showSnack(loc.familyAccessNoAttachableHubs);
      return;
    }

    String selectedId = options.first.commandHubId;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.familyAccessAttachHubTitle),
        content: DropdownButtonFormField<String>(
          key: ValueKey(selectedId),
          initialValue: selectedId,
          onChanged: (value) => selectedId = value ?? selectedId,
          decoration: InputDecoration(labelText: loc.familyAccessSelectHubLabel),
          items: options
              .map(
                (hub) => DropdownMenuItem(
                  value: hub.commandHubId,
                  child: Text(hub.facilityName.isEmpty ? hub.hubNumber : hub.facilityName),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, selectedId), child: Text(loc.familyAccessAttachAction)),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await _executeAction(
      () => familyGroupService.attachHub(group.id, result),
      group.id,
      success: loc.familyAccessHubAttached,
    );
  }

  Future<void> _detachHub(
    FamilyGroup group,
    HubObject hub,
    AppLocalizations loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.familyAccessDetachHubTitle(hub.facilityName.isEmpty ? hub.hubNumber : hub.facilityName)),
        content: Text(loc.familyAccessDetachHubMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.familyAccessDetachAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _executeAction(
      () => familyGroupService.detachHub(group.id, hub.commandHubId),
      group.id,
      success: loc.familyAccessHubDetached,
    );
  }

  Future<void> _armHub(
    FamilyGroup group,
    HubObject hub,
    AppLocalizations loc,
  ) async {
    final pin = await _askPin(loc.familyAccessArmPinTitle, loc);
    if (pin == null) return;
    await _executeAction(
      () => familyGroupService.arm(group.id, hub.commandHubId, pin: pin),
      group.id,
      success: loc.familyAccessHubArmed(hub.facilityName.isEmpty ? hub.hubNumber : hub.facilityName),
    );
  }

  Future<void> _disarmHub(
    FamilyGroup group,
    HubObject hub,
    AppLocalizations loc,
  ) async {
    final pin = await _askPin(loc.familyAccessDisarmPinTitle, loc);
    if (pin == null) return;
    await _executeAction(
      () => familyGroupService.disarm(group.id, hub.commandHubId, pin: pin),
      group.id,
      success: loc.familyAccessHubDisarmed(hub.facilityName.isEmpty ? hub.hubNumber : hub.facilityName),
    );
  }

  Future<String?> _askPin(String title, AppLocalizations loc) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: loc.familyAccessPinLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(loc.ok)),
        ],
      ),
    );
    if (result == null || result.isEmpty) {
      return null;
    }
    return result;
  }

  Future<void> _executeAction(
    Future<void> Function() action,
    String groupId, {
    String? success,
  }) async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    setState(() => _isProcessing = true);
    try {
      await action();
      if (success != null) {
        _showSnack(success);
      }
      await _refreshAll(groupId);
    } catch (e) {
      _showSnack(_formatError(loc, e));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatError(AppLocalizations loc, Object error) {
    final description = error.toString();
    return '${loc.error}: $description';
  }
}

class _GroupSelector extends StatelessWidget {
  const _GroupSelector({
    required this.loc,
    required this.groups,
    required this.selectedGroupId,
    required this.onSelect,
  });

  final AppLocalizations loc;
  final List<FamilyGroup> groups;
  final String selectedGroupId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.familyAccessMyGroups, style: AppStyles.headline4(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups
              .map(
                (group) => ChoiceChip(
                  label: Text(group.name),
                  selected: group.id == selectedGroupId,
                  onSelected: (_) => onSelect(group.id),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          loc.familyAccessSelectGroupHint,
          style: AppStyles.caption(context),
        ),
      ],
    );
  }
}

class _GroupSummaryCard extends StatelessWidget {
  const _GroupSummaryCard({
    required this.loc,
    required this.group,
    required this.isProcessing,
    required this.isActive,
    required this.role,
    required this.membersCountLabel,
    required this.onActivate,
    required this.onRename,
    required this.onTransfer,
  });

  final AppLocalizations loc;
  final FamilyGroup group;
  final bool isProcessing;
  final bool isActive;
  final FamilyRole? role;
  final String membersCountLabel;
  final VoidCallback onActivate;
  final VoidCallback onRename;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: AppStyles.headline4(context).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: loc.familyAccessRenameGroupTooltip,
                onPressed: isProcessing ? null : onRename,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(label: membersCountLabel),
              if (role != null)
                _InfoChip(label: _roleLabel(role!, loc)),
              if (isActive)
                _InfoChip(label: loc.familyAccessActiveChip),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (isProcessing || isActive) ? null : onActivate,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(isActive ? loc.familyAccessGroupActive : loc.familyAccessUseGroup),
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onTransfer,
            icon: const Icon(Icons.swap_horiz),
            label: Text(loc.familyAccessTransferOwnershipTitle),
          ),
        ],
      ),
    );
  }

  String _roleLabel(FamilyRole role, AppLocalizations loc) {
    switch (role) {
      case FamilyRole.owner:
        return loc.familyRoleOwner;
      case FamilyRole.admin:
        return loc.familyRoleAdmin;
      case FamilyRole.user:
        return loc.familyRoleUser;
      case FamilyRole.guest:
        return loc.familyRoleGuest;
    }
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.loc,
    required this.group,
    required this.isProcessing,
    required this.role,
    required this.onAddMember,
    required this.onChangeRole,
    required this.onRemoveMember,
  });

  final AppLocalizations loc;
  final FamilyGroup group;
  final bool isProcessing;
  final FamilyRole? role;
  final VoidCallback onAddMember;
  final void Function(FamilyMember member, FamilyRole role) onChangeRole;
  final void Function(FamilyMember member) onRemoveMember;

  @override
  Widget build(BuildContext context) {
    final canManage = role != null && FamilyPermissions.canManageMembers(role!);
    final canChange = role != null && FamilyPermissions.canChangeRoles(role!);

    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.familyAccessMembersTitle,
                  style: AppStyles.bodyText1(context).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (canManage)
                TextButton.icon(
                  onPressed: isProcessing ? null : onAddMember,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(loc.familyAccessInviteAction),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...group.members.map((member) {
            final subtitle = member.email?.isNotEmpty == true
                ? '${_roleLabel(member.role)} · ${member.email}'
                : _roleLabel(member.role);
            final isOwner = member.isOwner;
            final showActions = canManage && !isOwner && member.isActive;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(member.name),
                subtitle: Text(subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showActions && canChange)
                      PopupMenuButton<FamilyRole>(
                        icon: const Icon(Icons.manage_accounts_outlined),
                        tooltip: loc.familyAccessChangeRoleTooltip,
                        onSelected: (value) => onChangeRole(member, value),
                        itemBuilder: (ctx) => [
                          FamilyRole.admin,
                          FamilyRole.user,
                          FamilyRole.guest,
                        ]
                            .map(
                              (r) => PopupMenuItem(
                                value: r,
                                enabled: member.role != r,
                                child: Text(_roleLabel(r)),
                              ),
                            )
                            .toList(),
                      ),
                    if (showActions)
                      IconButton(
                        tooltip: loc.familyAccessRemoveMemberTooltip,
                        onPressed: isProcessing ? null : () => onRemoveMember(member),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _roleLabel(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return loc.familyRoleOwner;
      case FamilyRole.admin:
        return loc.familyRoleAdmin;
      case FamilyRole.user:
        return loc.familyRoleUser;
      case FamilyRole.guest:
        return loc.familyRoleGuest;
    }
  }
}

class _InvitationsCard extends StatelessWidget {
  const _InvitationsCard({required this.loc, required this.invitations});

  final AppLocalizations loc;
  final List<FamilyInvitation> invitations;

  @override
  Widget build(BuildContext context) {
    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.familyAccessInvitationsTitle,
            style: AppStyles.bodyText1(context).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...invitations.map(
            (inv) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(inv.email),
                subtitle: Text('${_roleLabel(inv.role)} · ${inv.status}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return loc.familyRoleOwner;
      case FamilyRole.admin:
        return loc.familyRoleAdmin;
      case FamilyRole.user:
        return loc.familyRoleUser;
      case FamilyRole.guest:
        return loc.familyRoleGuest;
    }
  }
}

class _HubsCard extends StatelessWidget {
  const _HubsCard({
    required this.loc,
    required this.hubs,
    required this.isProcessing,
    required this.role,
    required this.allowUserDisarm,
    required this.onAttach,
    required this.onDetach,
    required this.onArm,
    required this.onDisarm,
  });

  final AppLocalizations loc;
  final List<HubObject> hubs;
  final bool isProcessing;
  final FamilyRole? role;
  final bool allowUserDisarm;
  final VoidCallback onAttach;
  final void Function(HubObject hub) onDetach;
  final void Function(HubObject hub) onArm;
  final void Function(HubObject hub) onDisarm;

  @override
  Widget build(BuildContext context) {
    final canManage = role != null && FamilyPermissions.canAttachDetachHubs(role!);
    final canArm = role != null && FamilyPermissions.canArm(role!);
    final canDisarm = role != null && FamilyPermissions.canDisarm(role!, allowUser: allowUserDisarm);

    return _ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.familyAccessHubsTitle,
                  style: AppStyles.bodyText1(context).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (canManage)
                TextButton.icon(
                  onPressed: isProcessing ? null : onAttach,
                  icon: const Icon(Icons.add_link),
                  label: Text(loc.familyAccessAttachAction),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hubs.isEmpty)
            Text(loc.familyAccessNoHubsLabel, style: AppStyles.caption(context))
          else
            ...hubs.map((hub) {
              final name = hub.facilityName.isEmpty ? hub.hubNumber : hub.facilityName;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppStyles.bodyText1(context).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (canManage)
                            IconButton(
                              tooltip: loc.familyAccessDetachAction,
                              onPressed: isProcessing ? null : () => onDetach(hub),
                              icon: const Icon(Icons.link_off_outlined, color: Colors.redAccent),
                            ),
                        ],
                      ),
                      if (hub.address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(hub.address, style: AppStyles.caption(context)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatusDot(isActive: hub.connected),
                          const SizedBox(width: 8),
                          Text(hub.connected ? loc.online : loc.offline),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (!canArm || isProcessing) ? null : () => onArm(hub),
                              icon: const Icon(Icons.security_outlined),
                              label: Text(loc.arm),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (!canDisarm || isProcessing) ? null : () => onDisarm(hub),
                              icon: const Icon(Icons.lock_open_outlined),
                              label: Text(loc.disarm),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ShadowCard extends StatelessWidget {
  const _ShadowCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(context).copyWith(
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppStyles.caption(context).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.redAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message, required this.onCreate});

  final String title;
  final String message;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppStyles.headline3(context), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, style: AppStyles.bodyText2(context), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.group_add_outlined),
              label: Text(AppLocalizations.of(context).familyAccessCreateAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.error, style: AppStyles.headline4(context)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: Text(loc.retry)),
          ],
        ),
      ),
    );
  }
}

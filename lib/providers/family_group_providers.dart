import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/group_context.dart';
import 'package:ISS/models/family_group_models.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/services/family_group_service.dart';

export 'package:ISS/models/family_group_models.dart'
    show FamilyGroup, FamilyMember, FamilyInvitation, FamilyRole, FamilyPermissions;

class ActiveFamilyGroupState {
  final String? groupId;
  final FamilyRole? role;
  final bool allowUserDisarm;

  const ActiveFamilyGroupState({
    this.groupId,
    this.role,
    this.allowUserDisarm = false,
  });

  bool get isActive => groupId != null;
}

class ActiveFamilyGroupNotifier extends StateNotifier<ActiveFamilyGroupState> {
  ActiveFamilyGroupNotifier() : super(const ActiveFamilyGroupState());

  void setActiveGroup({
    String? groupId,
    FamilyRole? role,
    bool? allowUserDisarm,
  }) {
    if (groupId == null || groupId.isEmpty) {
      state = const ActiveFamilyGroupState();
      FamilyGroupContext.clear();
      return;
    }

    final next = ActiveFamilyGroupState(
      groupId: groupId,
      role: role ?? state.role,
      allowUserDisarm: allowUserDisarm ?? state.allowUserDisarm,
    );

    if (state.groupId == next.groupId &&
        state.role == next.role &&
        state.allowUserDisarm == next.allowUserDisarm) {
      FamilyGroupContext.set(
        groupId: next.groupId,
        role: next.role,
        allowUserDisarm: next.allowUserDisarm,
      );
      return;
    }

    state = next;
    FamilyGroupContext.set(
      groupId: next.groupId,
      role: next.role,
      allowUserDisarm: next.allowUserDisarm,
    );
  }

  void activateFromDetails(FamilyGroup group) {
    if (group.id.isEmpty) return;
    setActiveGroup(
      groupId: group.id,
      role: group.currentUserRole ?? state.role,
      allowUserDisarm: group.allowUserDisarm,
    );
  }

  void clear() => setActiveGroup(groupId: null);
}

final activeFamilyGroupStateProvider =
    StateNotifierProvider<ActiveFamilyGroupNotifier, ActiveFamilyGroupState>(
  (ref) => ActiveFamilyGroupNotifier(),
);

final activeFamilyGroupIdProvider = Provider<String?>((ref) {
  return ref.watch(activeFamilyGroupStateProvider).groupId;
});

final activeFamilyRoleProvider = Provider<FamilyRole?>((ref) {
  return ref.watch(activeFamilyGroupStateProvider).role;
});

final allowUserDisarmProvider = Provider<bool>((ref) {
  return ref.watch(activeFamilyGroupStateProvider).allowUserDisarm;
});

final familyGroupsProvider = FutureProvider.autoDispose<List<FamilyGroup>>(
  (ref) async {
    final groups = await familyGroupService.getAllGroups();
    final activeState = ref.read(activeFamilyGroupStateProvider);
    final activeId = activeState.groupId;
    final notifier = ref.read(activeFamilyGroupStateProvider.notifier);

    if (activeId != null) {
      final match = groups.where((g) => g.id == activeId).toList();
      if (match.isEmpty) {
        notifier.clear();
      } else {
        final group = match.first;
        if (group.currentUserRole != null || group.allowUserDisarm) {
          notifier.setActiveGroup(
            groupId: group.id,
            role: group.currentUserRole ?? activeState.role,
            allowUserDisarm: group.allowUserDisarm,
          );
        }
      }
    }

    return groups;
  },
);

final familyGroupDetailsProvider = FutureProvider.autoDispose.family<
    FamilyGroup,
    String>(
  (ref, groupId) async {
    final group = await familyGroupService.getGroupById(groupId);
    ref.read(activeFamilyGroupStateProvider.notifier).activateFromDetails(group);
    return group;
  },
);

final familyHubsProvider = FutureProvider.autoDispose
    .family<List<HubObject>, String>((ref, groupId) async {
      return familyGroupService.getHubsForGroups(groupId: groupId);
    });

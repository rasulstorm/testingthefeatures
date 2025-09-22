import 'package:ISS/models/family_group_models.dart';

/// Глобальный контекст активной семейной группы.
///
/// Используется сетевыми перехватчиками, чтобы автоматически добавлять
/// `X-Active-Group` в запросы. Обновляется из провайдеров семейного доступа.
class FamilyGroupContext {
  FamilyGroupContext._();

  static String? _activeGroupId;
  static FamilyRole? _activeRole;
  static bool _allowUserDisarm = false;

  static String? get activeGroupId => _activeGroupId;
  static FamilyRole? get activeRole => _activeRole;
  static bool get allowUserDisarm => _allowUserDisarm;

  static void clear() {
    _activeGroupId = null;
    _activeRole = null;
    _allowUserDisarm = false;
  }

  static void set({
    String? groupId,
    FamilyRole? role,
    bool? allowUserDisarm,
  }) {
    _activeGroupId = groupId;
    _activeRole = role;
    if (allowUserDisarm != null) {
      _allowUserDisarm = allowUserDisarm;
    }
  }
}

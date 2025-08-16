# ISS

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter projects:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

# ISS Mobile Architecture

## 📱 Описание
Приложение для управления хабами и системой безопасности с поддержкой **семейного доступа**.  
Стек: **Flutter**, **Riverpod**, **Dio**, **WebSockets**, **GoRouter**.  

### Основные фичи
- Управление хабами (ARM/DISARM, мониторинг, привязка/отвязка).
- Семейный доступ: группы, роли (OWNER/ADMIN/USER/GUEST).
- Управление участниками и их правами.
- Работа через REST API и WebSocket.

---

## 📂 Структура проекта

---

## 🏗 Архитектура

### 1. System Context
```mermaid
flowchart LR
  user([Пользователь iOS/Android])

  subgraph app["Flutter App (ISS Mobile)"]
    ui["UI (Screens & Widgets)"]
    prov["State: Riverpod Providers"]
    svc["Services: Dio/WebSocket"]
    models["Models + Parsers + Utils"]

    ui --> prov
    prov --> svc
    svc --> models
    ui --> models
  end

  subgraph backend["Backend API"]
    http[(REST API /api/v1)]
    ws[(WebSocket)]
  end

  user --> app
  svc --> http
  svc --- ws
```
```mermaid
graph TD
  A[features/home] --> P[providers/*]
  A --> W[widgets/*]
  A --> U[utils/device_parser & device_utils]
  A --> S1[services/hub_service]
  A --> WS[features/security_control/ws_provider]

  FG[features/family_access/*] --> P
  FG --> S2[services/family_group_service]
  FG --> W
  FG --> U

  settings[features/settings/*] --> P
  settings --> W

  P --> core[core/network/dio_provider]
  S1 --> core
  S2 --> core
  WS --> core

  subgraph Core
    core
  end

  subgraph Features
    A
    FG
    settings
  end

  subgraph Shared
    P
    W
    U
    models[models/*]
  end

  models --> U
  W --> models
```
```mermaid
flowchart TB
  settings[SettingsScreen] -->|tap "Семейный доступ"| groups[FamilyGroupsScreen (список)]
  groups -->|tap item| groupDetails[FamilyGroupScreen (детали)]

  subgraph FamilyGroupsScreen
    groups -->|Pull/Refresh| getMyGroups[GET /family-group/]
    groups -->|Delete group| deleteGroup[DELETE /family-group/{groupId}/delete]
  end

  subgraph FamilyGroupScreen
    groupDetails --> hubs[Хабы группы]
    groupDetails --> members[Участники]
    groupDetails --> actions[Действия с группой]
  end

  hubs -->|Attach| attach[POST /family-group/{groupId}/hub/{hubId}/attach]
  hubs -->|Detach| detach[POST /family-group/{groupId}/hub/{hubId}/dettach]
  hubs -->|ARM| arm[POST /family-group/{groupId}/arm-security/{hubId}]
  hubs -->|DISARM (PIN)| disarm[POST /family-group/{groupId}/disarm-security/{hubId}]

  members -->|Add| addMember[POST /family-group/add-member/{groupId}]
  members -->|Change role| updRole[PUT /family-group/{memberId}/update-member-role]
  members -->|Delete| delMember[DELETE /family-group/{memberId}/delete-member]

  actions -->|Rename| rename[PUT /family-group/{groupId}/update-group-name?name=]
  actions -->|Transfer owner| transfer[POST /family-group/{groupId}/transfer-ownership/{memberId}]
```









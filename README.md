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
nsfer[POST /family-group/{groupId}/transfer-ownership/{memberId}]

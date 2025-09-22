// lib/features/cameras/presentation/widgets/camera_form_sheet.dart
import 'package:flutter/material.dart';
import '../domain/camera_models.dart';

class CameraFormSheet extends StatefulWidget {
  final Camera? initial;
  const CameraFormSheet({super.key, this.initial});

  @override
  State<CameraFormSheet> createState() => _CameraFormSheetState();
}

class _CameraFormSheetState extends State<CameraFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController ipCtrl;
  late final TextEditingController modelCtrl;
  late final TextEditingController ingestCtrl;

  @override
  void initState() {
    super.initState();
    ipCtrl = TextEditingController(text: widget.initial?.ipAddress ?? '');
    modelCtrl = TextEditingController(text: widget.initial?.cameraModel ?? '');
    ingestCtrl = TextEditingController(
      text: widget.initial?.ingestSource ?? '',
    );
  }

  @override
  void dispose() {
    ipCtrl.dispose();
    modelCtrl.dispose();
    ingestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initial == null ? 'Новая камера' : 'Редактирование',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: modelCtrl,
                decoration: const InputDecoration(labelText: 'Модель камеры'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'IP адрес (опционально)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: ingestCtrl,
                decoration: const InputDecoration(
                  labelText: 'Источник (RTSP/dev://…)',
                ),
                validator:
                    (v) =>
                        (v == null || v.isEmpty) ? 'Укажи ingestSource' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() != true) return;
                  final req = CameraRequest(
                    ipAddress:
                        ipCtrl.text.trim().isEmpty ? null : ipCtrl.text.trim(),
                    cameraModel:
                        modelCtrl.text.trim().isEmpty
                            ? null
                            : modelCtrl.text.trim(),
                    ingestSource: ingestCtrl.text.trim(),
                  );
                  Navigator.pop(context, req);
                },
                child: const Text('Сохранить'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ISS/models/device_models.dart';

class AcDetailScreen extends StatefulWidget {
  final BaseDevice device;
  final String title, room;
  const AcDetailScreen({
    super.key,
    required this.device,
    required this.title,
    required this.room,
  });

  @override
  State<AcDetailScreen> createState() => _AcDetailScreenState();
}

class _AcDetailScreenState extends State<AcDetailScreen> {
  bool isOn = false;
  double temp = 23;
  int mode = 0; // 0 cool,1 heat,2 fan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            _card(
              child: Row(
                children: [
                  const Icon(Icons.power_settings_new_rounded),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Power',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Switch(
                    value: isOn,
                    onChanged: (v) => setState(() => isOn = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temperature',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: temp,
                    min: 16,
                    max: 30,
                    onChanged: (v) => setState(() => temp = v),
                  ),
                  Text('${temp.toStringAsFixed(1)}°C'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('Cool'),
                    selected: mode == 0,
                    onSelected: (_) => setState(() => mode = 0),
                  ),
                  ChoiceChip(
                    label: const Text('Heat'),
                    selected: mode == 1,
                    onSelected: (_) => setState(() => mode = 1),
                  ),
                  ChoiceChip(
                    label: const Text('Fan'),
                    selected: mode == 2,
                    onSelected: (_) => setState(() => mode = 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(blurRadius: 18, color: Colors.black12)],
    ),
    child: child,
  );
}

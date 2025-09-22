import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Небольшая круглая кнопка-тумблер ON/OFF c лоадером.
/// [isOn] — текущее состояние; [onToggle] получает nextState и
/// должен вернуть true/false (успех/ошибка) — при ошибке делаем откат UI.
class RoundToggleButton extends StatefulWidget {
  final String label;
  final bool isOn;
  final bool loading;
  final Future<bool> Function(bool nextState) onToggle;
  final IconData iconOn;
  final IconData iconOff;
  final double size;

  const RoundToggleButton({
    super.key,
    required this.label,
    required this.isOn,
    required this.onToggle,
    this.loading = false,
    this.iconOn = Icons.power,
    this.iconOff = Icons.power_off,
    this.size = 48, // компактнее
  });

  @override
  State<RoundToggleButton> createState() => _RoundToggleButtonState();
}

class _RoundToggleButtonState extends State<RoundToggleButton> {
  late bool _isOn;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isOn = widget.isOn;
    _busy = widget.loading;
  }

  @override
  void didUpdateWidget(covariant RoundToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOn != widget.isOn) _isOn = widget.isOn;
    _busy = widget.loading;
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    final next = !_isOn;

    setState(() {
      _busy = true;
      _isOn = next; // оптимистично
    });
    HapticFeedback.selectionClick();

    final ok = await widget.onToggle(next).catchError((_) => false);

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        _isOn = !next; // откат
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось изменить состояние')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = _isOn;
    final colorScheme = theme.colorScheme;
    final Color inactiveSurface = colorScheme.surfaceContainerHighest;
    final Color inactiveOnSurface = colorScheme.onSurface;

    final Color bg = on ? colorScheme.primary : inactiveSurface;
    final Color fg = on ? colorScheme.onPrimary : inactiveOnSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              if (on)
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: .18),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleTap,
              child: Center(
                child:
                    _busy
                        ? SizedBox(
                          width: widget.size * .42,
                          height: widget.size * .42,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(fg),
                          ),
                        )
                        : Icon(on ? widget.iconOn : widget.iconOff, color: fg),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: widget.size + 16,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

// lib/features/home/widgets/security_status_card.dart
import 'package:flutter/material.dart';
import 'package:ISS/appstyles.dart';

class SecurityStatusCard extends StatelessWidget {
  final bool isArmed;
  final bool isLoading;
  final VoidCallback onPressed;

  const SecurityStatusCard({
    super.key,
    required this.isArmed,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = isArmed ? "Система под охраной" : "Снято с охраны";
    final statusIcon =
        isArmed ? Icons.shield_rounded : Icons.verified_user_rounded;
    final gradient =
        isArmed
            ? const [Color(0xFFED5760), Color(0xFFFF8A65)]
            : const [Color(0xFF24C6DC), Color(0xFF514A9D)];

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Icon(statusIcon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: AppStyles.headline4(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Нажмите, чтобы открыть панель безопасности.',
                    style: AppStyles.bodyText2(
                      context,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.78)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isArmed ? 'Охрана активна' : 'Охрана выключена',
                      style: AppStyles.caption(
                        context,
                      ).copyWith(color: Colors.white, letterSpacing: 0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder:
                  (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
              child:
                  isLoading
                      ? const SizedBox(
                        key: ValueKey('security_loading'),
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Icon(
                        Icons.chevron_right_rounded,
                        key: ValueKey('security_arrow'),
                        color: Colors.white,
                        size: 34,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

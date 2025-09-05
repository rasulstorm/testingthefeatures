import 'package:flutter/material.dart';

class HubCoverBackground extends StatelessWidget {
  const HubCoverBackground({
    super.key,
    required this.imageUrl,
    required this.loading,
    required this.headers,
    this.assetFallback = 'assets/images/home_background.jpg',
  });

  final String? imageUrl;
  final bool loading;
  final Map<String, String> headers;
  final String assetFallback;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            headers: headers.isEmpty ? null : headers,
            errorBuilder: (_, __, ___) => _fallback(context),
          )
        else
          _fallback(context),
        // затемняющий градиент
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.4),
              ],
            ),
          ),
        ),
        if (loading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(BuildContext ctx) {
    return Image.asset(assetFallback, fit: BoxFit.cover);
  }
}

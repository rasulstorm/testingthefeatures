// lib/features/home/widgets/overview_grid.dart
import 'package:flutter/material.dart';
import 'package:ISS/widgets/status_indicator_card.dart';

class OverviewGrid extends StatelessWidget {
  final List<StatusIndicator> indicators;
  const OverviewGrid({super.key, required this.indicators});

  @override
  Widget build(BuildContext context) {
    if (indicators.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: CompactStatusIndicatorCard.minHeight,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemBuilder:
              (context, index) =>
                  CompactStatusIndicatorCard(indicator: indicators[index]),
          separatorBuilder: (context, _) => const SizedBox(width: 16),
          itemCount: indicators.length,
        ),
      ),
    );
  }
}

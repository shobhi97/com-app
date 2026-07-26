import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase/supabase_service.dart';

/// Candle-less line chart of an instrument's traded bell prices over time —
/// derived from the `bells` table (entry prices posted during the session),
/// not a live market-data feed (TickBell is a discussion room, not a broker).
final instrumentPriceHistoryProvider =
    FutureProvider.family.autoDispose<List<FlSpot>, String>((ref, instrument) async {
  final rows = await SupabaseService.client
      .from('bells')
      .select('price, created_at')
      .eq('instrument', instrument)
      .not('price', 'is', null)
      .order('created_at');

  final list = rows as List;
  return List.generate(list.length, (i) {
    final price = (list[i]['price'] as num).toDouble();
    return FlSpot(i.toDouble(), price);
  });
});

final distinctInstrumentsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final rows = await SupabaseService.client.from('bells').select('instrument');
  final set = <String>{};
  for (final r in rows as List) {
    set.add(r['instrument'] as String);
  }
  return set.toList()..sort();
});

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final instrumentsAsync = ref.watch(distinctInstrumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: instrumentsAsync.when(
        data: (instruments) {
          if (instruments.isEmpty) {
            return Center(
              child: Text('No instrument data yet', style: Theme.of(context).textTheme.titleMedium),
            );
          }
          _selected ??= instruments.first;
          final spotsAsync = ref.watch(instrumentPriceHistoryProvider(_selected!));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selected,
                  decoration: const InputDecoration(labelText: 'Instrument'),
                  items: instruments
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _selected = v),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: spotsAsync.when(
                    data: (spots) {
                      if (spots.isEmpty) {
                        return const Center(child: Text('No price points logged for this instrument yet.'));
                      }
                      return _PriceLineChart(spots: spots);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Chart error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load instruments: $e')),
      ),
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  const _PriceLineChart({required this.spots});

  @override
  Widget build(BuildContext context) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1 + 1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accentGold,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accentGold.withOpacity(0.12),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevatedDark,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      s.y.toStringAsFixed(2),
                      const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

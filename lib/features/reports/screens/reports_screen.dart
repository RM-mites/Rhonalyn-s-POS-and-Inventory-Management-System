import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/reports_data.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ReportsProvider>();
      if (provider.data == null) provider.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    final data = provider.data;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports & Analytics',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (data != null)
                    Text(
                      '${formatDate(data.from)} – ${formatDate(data.to)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              );
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 days')),
                      ButtonSegment(value: 30, label: Text('30 days')),
                      ButtonSegment(value: 90, label: Text('90 days')),
                    ],
                    selected: {provider.rangeDays},
                    onSelectionChanged: (selection) =>
                        context.read<ReportsProvider>().setRange(selection.first),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => provider.load(),
                  ),
                ],
              );
              if (constraints.maxWidth < 720) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: controls,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 8),
                  controls,
                ],
              );
            },
          ),
        ),
        Expanded(
          child: provider.isLoading && data == null
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null && data == null
                  ? _ErrorView(
                      message: provider.error!,
                      onRetry: () => provider.load(),
                    )
                  : data == null
                      ? const Center(child: Text('No report data available.'))
                      : _ReportsBody(data: data, refreshing: provider.isLoading),
        ),
      ],
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.data, required this.refreshing});

  final ReportsData data;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final kpiWidth = constraints.maxWidth < 520
                ? constraints.maxWidth
                : 220.0;
            final trend = _TrendCard(data: data);
            final payments = _PaymentCard(data: data);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: kpiWidth,
                      child: _KpiCard(
                        icon: Icons.payments_outlined,
                        label: 'Revenue',
                        value: formatPeso(data.totalRevenue),
                        subtitle: '${data.totalSales} completed sales',
                        accent: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: kpiWidth,
                      child: _KpiCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'Transactions',
                        value: formatQuantity(data.totalSales),
                        subtitle: 'In the selected range',
                        accent: const Color(0xFF5B8DEF),
                      ),
                    ),
                    SizedBox(
                      width: kpiWidth,
                      child: _KpiCard(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Items sold',
                        value: formatQuantity(data.itemsSold),
                        subtitle: '${data.topProducts.length} product(s) sold',
                        accent: const Color(0xFF34B27B),
                      ),
                    ),
                    SizedBox(
                      width: kpiWidth,
                      child: _KpiCard(
                        icon: Icons.trending_up,
                        label: 'Average sale',
                        value: formatPeso(data.averageSale),
                        subtitle: 'Revenue ÷ transactions',
                        accent: const Color(0xFF8E6CEF),
                      ),
                    ),
                    SizedBox(
                      width: kpiWidth,
                      child: _KpiCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'Low stock',
                        value: formatQuantity(data.lowStock.length),
                        subtitle: 'Variants at or below threshold',
                        accent: data.lowStock.isEmpty
                            ? const Color(0xFF34B27B)
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: trend),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: payments),
                    ],
                  )
                else ...[
                  trend,
                  const SizedBox(height: 16),
                  payments,
                ],
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _TopProductsCard(data: data)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _LowStockCard(data: data)),
                    ],
                  )
                else ...[
                  _TopProductsCard(data: data),
                  const SizedBox(height: 16),
                  _LowStockCard(data: data),
                ],
              ],
            );
          },
        ),
        if (refreshing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.data});

  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sales trend',
      subtitle: 'Daily completed sales revenue',
      child: SizedBox(
        height: 260,
        child: data.dailySales.every((p) => p.total == 0)
            ? const _EmptyChart(message: 'No sales in this period yet.')
            : _SalesTrendChart(points: data.dailySales),
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.points});

  final List<DailySalesPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final maxValue = points
        .map((p) => p.total)
        .fold(0.0, (previous, value) => math.max(previous, value));
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.15;
    final leftInterval = maxY / 4;
    final bottomInterval = math.max(1, (points.length / 4).ceil()).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: leftInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 62,
              interval: leftInterval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY + 0.001) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(_compactPeso(value), style: labelStyle),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 ||
                    index >= points.length ||
                    (value - index).abs() > 0.001) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    formatShortDate(points[index].date),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    '${formatPeso(spot.y)}\n${formatShortDate(points[spot.x.round()].date)}',
                    TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].total),
            ],
            isCurved: false,
            color: primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primary.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.data});

  final ReportsData data;

  static const _palette = [
    Color(0xFF5B8DEF),
    Color(0xFF34B27B),
    Color(0xFFF2B341),
    Color(0xFFE2566F),
    Color(0xFF8E6CEF),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payment mix',
      subtitle: 'Revenue by payment method',
      child: data.payments.isEmpty
          ? const SizedBox(
              height: 260,
              child: _EmptyChart(message: 'No payments recorded in this range.'),
            )
          : SizedBox(
              height: 260,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chart = AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 52,
                        borderData: FlBorderData(show: false),
                        sections: [
                          for (var i = 0; i < data.payments.length; i++)
                            _section(context, data.payments[i], i),
                        ],
                      ),
                    ),
                  );
                  final legend = _legend(context);
                  if (constraints.maxWidth < 380) {
                    return Column(
                      children: [
                        Expanded(child: chart),
                        legend,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: chart),
                      const SizedBox(width: 12),
                      Expanded(child: legend),
                    ],
                  );
                },
              ),
            ),
    );
  }

  PieChartSectionData _section(
    BuildContext context,
    PaymentBreakdown payment,
    int index,
  ) {
    final total = data.payments.fold(0.0, (sum, p) => sum + p.total);
    final percent = total <= 0 ? 0 : (payment.total / total * 100).round();
    return PieChartSectionData(
      value: payment.total,
      color: _palette[index % _palette.length],
      radius: 52,
      title: percent >= 5 ? '$percent%' : '',
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < data.payments.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _palette[i % _palette.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${data.payments[i].label} (${data.payments[i].count})',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    formatPeso(data.payments[i].total),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.data});

  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topRevenue = data.topProducts.isEmpty
        ? 0.0
        : data.topProducts.first.revenue;
    return _SectionCard(
      title: 'Top products',
      subtitle: 'By revenue in the selected range',
      child: data.topProducts.isEmpty
          ? const SizedBox(
              height: 120,
              child: _EmptyChart(message: 'No product sales in this period.'),
            )
          : Column(
              children: [
                for (var i = 0; i < data.topProducts.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              theme.colorScheme.secondaryContainer,
                          child: Text(
                            '${i + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data.topProducts[i].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      formatPeso(data.topProducts[i].revenue),
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: topRevenue <= 0
                                      ? 0
                                      : data.topProducts[i].revenue /
                                          topRevenue,
                                  minHeight: 6,
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${formatQuantity(data.topProducts[i].quantity)} sold',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.data});

  final ReportsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = data.lowStock.take(10).toList();
    return _SectionCard(
      title: 'Low stock alerts',
      subtitle: 'Variants at or below their threshold',
      child: items.isEmpty
          ? SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(height: 6),
                    const Text('All tracked stock is above threshold.'),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.errorContainer,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    title: Text(
                      '${item.productName} — ${item.variantLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('Threshold ${item.threshold}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 96),
                      child: Text(
                        '${item.stockQty} left',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                if (data.lowStock.length > items.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+ ${data.lowStock.length - items.length} more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined,
              size: 36, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _compactPeso(double value) {
  final abs = value.abs();
  if (abs >= 1000000) {
    return '₱${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000) {
    return '₱${(value / 1000).toStringAsFixed(1)}K';
  }
  return '₱${value.toStringAsFixed(0)}';
}

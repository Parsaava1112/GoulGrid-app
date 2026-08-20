import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../services/task_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آمار و پیشرفت')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getLast7DaysPoints(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBarChart(data),
              const SizedBox(height: 24),
              _buildHeatmap(),
              const SizedBox(height: 24),
              _buildBadgeSummary(),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getLast7DaysPoints() async {
    final db = DatabaseHelper.instance;
    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final summary = await db.getSummary(dateStr);
      result.add({
        'date': dateStr,
        'label': DateFormat('E', 'fa').format(date),
        'points': summary?.totalPoints ?? 0,
      });
    }
    return result;
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('امتیاز ۷ روز اخیر'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.map((e) => (e['points'] as int).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Text(data[index]['label']);
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (item['points'] as int).toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    // یک شبکه ۷ ستونه (روزهای هفته جاری)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('فعالیت این هفته'),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: _getWeekHeatmapData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final date = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 - index));
                    final dateStr = DateFormat('yyyy-MM-dd').format(date);
                    final count = data[dateStr] ?? 0;
                    final color = count == 0
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Color.lerp(Colors.lightGreen, Colors.green, count / 5)!;
                    return Tooltip(
                      message: '$dateStr\n$count تسک',
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getWeekHeatmapData() async {
    final db = DatabaseHelper.instance;
    final map = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final count = await db.countCompletionsForDate(dateStr);
      map[dateStr] = count;
    }
    return map;
  }

  Widget _buildBadgeSummary() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('نشان‌های کسب‌شده'),
            subtitle: Text('${provider.unlockedBadges} نشان'),
            trailing: const Icon(Icons.chevron_left),
          ),
        );
      },
    );
  }
}
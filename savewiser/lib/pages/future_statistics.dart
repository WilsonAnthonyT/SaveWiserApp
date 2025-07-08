import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'api_service.dart'; // Contains your ApiService.fetchAdvice()
import '../models/transaction.dart';

class FutureStatisticsPage extends StatefulWidget {
  const FutureStatisticsPage({super.key});

  @override
  State<FutureStatisticsPage> createState() => _FutureStatisticsPageState();
  //_FutureStatisticsPageState createState() => _FutureStatisticsPageState();
}

class _FutureStatisticsPageState extends State<FutureStatisticsPage> {
  static const years = ['2026', '2027', '2028'];
  Map<String, List<double>> _series = {for (var y in years) y: List.generate(12, (_) {
    return 0;
  })};

  String? _advice;
  bool _isLoading = false;
  late double pace;
  late String _goalDateText;

  final Random rng = Random();

  @override
  void initState() {
    super.initState();
    _refreshData();
    _fetchAdvice();
    final stats = _computeSavingsStats();
    final goalDate = _estimateGoalDate(stats[0], stats[1], 10000);
    final formatted = DateFormat.yMMMMd().format(goalDate);
    setState(() {
      _goalDateText = '$formatted';
    });

  }

  List<double> _computeSavingsStats() {
    final box = Hive.box<Transaction>('transactions');

    double totalSaved = 0.0;
    for (final txn in box.values) {
      totalSaved += txn.amount;
    }

    // 3) Figure out how many months span your data:
    //    find earliest txn and today
    final dates = box.values.map((t) => DateTime(t.year, t.month)).toList()
      ..sort();
    final start = dates.first;
    final now   = DateTime.now();
    final monthsSpan =
        (now.year - start.year) * 12 +
        (now.month - start.month) +
        1; // +1 so a single-month period counts as 1

    // 4) Compute pace in ₱/month:
    final pace = totalSaved / monthsSpan;

    return [totalSaved, pace];
  }

  DateTime _estimateGoalDate(double currentSaved, double monthlyPace, double goalAmount) {
    if (monthlyPace <= 0) {
      // no pace → can’t predict; just return “never”
      return DateTime(9999);
    }
    final remaining = goalAmount - currentSaved;
    if (remaining <= 0) {
      // already there!
      return DateTime.now();
    }
    // how many months (rounded up):
    final monthsNeeded = (remaining / monthlyPace).ceil();

    final now = DateTime.now();
    // roll forward that many months (day=1 for simplicity)
    return DateTime(now.year, now.month + monthsNeeded, 1);
  }

  Future<void> _refreshData() async {
    final box = Hive.box<Transaction>('transactions');
    double startingPercentage = 20;
    final freshSeries = {for (var y in years) y: List.generate(12, 
      (_) {
          final val = startingPercentage + (rng.nextDouble() * 6 - 3);
          return val.clamp(0.0, 100.0);
        }
      )
    };
    

    for (final txn in box.values) {
      final key = txn.year.toString();
      if (freshSeries.containsKey(key) && txn.month >= 1 && txn.month <= 12) {
        freshSeries[key]![txn.month - 1] += txn.amount;
      }
    }
    setState(() => _series = freshSeries);
  }

  Future<void> _fetchAdvice() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiService().fetchAdvice();
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'] as String;
      setState(() => _advice = content.trim());
    } catch (_) {
      setState(() => _advice = 'Could not load advice.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'SAVEWISER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildChartCard(),
            const SizedBox(height: 24),
            _buildAdviceCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildChartCard() {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final maxY = (_series.values
                .expand((e) => e)
                .fold<double>(0, (prev, amt) => amt > prev ? amt : prev) + 10)
            .ceilToDouble();
    
    final lineBarsData = [
      _makeLineBar(_series['2026']!, Colors.pinkAccent),
      _makeLineBar(_series['2027']!, Colors.purple),
      _makeLineBar(_series['2028']!, Colors.green)
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Predicted Savings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: years.map((y) {
              final color = {'2026':Colors.pinkAccent, '2027': Colors.purple, '2028': Colors.green}[y]!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      y,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Transform.rotate(
                            angle: -0.6,
                            child: Text(
                              months[idx],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                      // ← Explicitly hide the top ticks/labels
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(enabled: false),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black12),
                    bottom: BorderSide(color: Colors.black12),
                    top: BorderSide(color: Colors.transparent),
                    right: BorderSide(color: Colors.transparent),
                  ),
                ),
                  lineBarsData: lineBarsData,
                ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
                children: [
                  const TextSpan(text: 'At your current pace, you\'ll reach your goal by '),
                  TextSpan(
                    text: '$_goalDateText.',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _makeLineBar(List<double> data, Color color) {
    return LineChartBarData(
      spots: data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
          show: true,
          getDotPainter: (FlSpot spot, double _percent, LineChartBarData bar, int index) {
            return FlDotCirclePainter(
              radius: 4,            // size of the dot
              color: color,     // match the line’s color
              strokeWidth: 0,       // or give it a border
            );
          },
        ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'What to do with your savings?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: SizedBox(width: 48, height: 48, child: CircularProgressIndicator()))
          else
            Text(
              _advice ?? '',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

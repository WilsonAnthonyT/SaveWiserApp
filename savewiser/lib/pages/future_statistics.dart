import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'api_service.dart';
import '../models/transaction.dart';

class FutureStatisticsPage extends StatefulWidget {
  const FutureStatisticsPage({super.key});

  @override
  State<FutureStatisticsPage> createState() => _FutureStatisticsPageState();
  //_FutureStatisticsPageState createState() => _FutureStatisticsPageState();
}

class _FutureStatisticsPageState extends State<FutureStatisticsPage> {
  late Map<String, List<double>> _series;
  late final List<String> years;

  String? _advice;
  bool _isLoading = false;
  late double pace;
  late String? _goalDateText;
  late double moneySaved;
  late String mygoal;
  late String moneyGoal;

  final Random rng = Random();

  Future<void> _getPreference() async {
    final prefs = await SharedPreferences.getInstance();
    moneyGoal = prefs.getString('amount') ?? "";
    mygoal = prefs.getString("goalDate") ?? "";
    final stats = _computeSavingsStats();
    moneySaved = stats[0];
    pace = stats[1];
    final goalDate = _estimateGoalDate(
      stats[0],
      stats[1],
      double.tryParse(moneyGoal.replaceAll(",", "")) ?? 0,
    );
    final formatted = DateFormat.yMMMMd().format(goalDate);

    setState(() {
      _goalDateText = '$formatted';
    });
  }

  @override
  void initState() {
    super.initState();

    final currentYear = DateTime.now().year;
    years = List.generate(3, (i) => (currentYear + i + 1).toString());

    _series = {for (var y in years) y: List.generate(12, (_) => 0.0)};

    _goalDateText = "";
    _refreshData();
    _fetchAdvice();
    _getPreference();
  }

  double _niceInterval(double maxY) {
    const targetLines = 8;
    final raw = maxY / targetLines;
    // pull out exponent (10ⁿ) of that raw interval
    final exp = pow(10, (log(raw) / ln10).floor());
    final frac = raw / exp;

    double niceFrac;
    if (frac <= 1)
      niceFrac = 1;
    else if (frac <= 2)
      niceFrac = 2;
    else if (frac <= 5)
      niceFrac = 5;
    else
      niceFrac = 10;

    return niceFrac * exp;
  }

  List<double> _computeSavingsStats() {
    final box = Hive.box<Transaction>('transactions');

    final savingsTxns = box.values
        .where((txn) => txn.category == 'Savings')
        .toList();

    if (savingsTxns.isEmpty) {
      return [0.0, 0.0];
    }

    final totalSaved = savingsTxns.fold(
      0.0,
      (sum, txn) => sum + txn.amount.abs(),
    );

    final dates =
        savingsTxns.map((t) => DateTime(t.year, t.month, t.date ?? 1)).toList()
          ..sort();

    final start = dates.first;
    final now = DateTime.now();

    final daysSpan = now.difference(start).inDays + 1; // +1 to avoid div/0
    final dailyPace = totalSaved / daysSpan;

    return [totalSaved, dailyPace];
  }

  DateTime _estimateGoalDate(
    double currentSaved,
    double dailyPace,
    double goalAmount,
  ) {
    if (dailyPace <= 0) {
      return DateTime(9999);
    }

    final remaining = goalAmount - currentSaved;
    if (remaining <= 0) {
      return DateTime.now();
    }

    final daysNeeded = (remaining / dailyPace).ceil();
    return DateTime.now().add(Duration(days: daysNeeded));
  }

  double calculateAverageSavingPercentage() {
    final box = Hive.box<Transaction>('transactions');
    final incomeByMonth = <String, double>{};
    final netByMonth = <String, double>{};

    for (final txn in box.values) {
      final key = '${txn.year}-${txn.month.toString().padLeft(2, '0')}';
      incomeByMonth[key] =
          (incomeByMonth[key] ?? 0) + (txn.amount > 0 ? txn.amount : 0);
      if (txn.category == 'Savings') {
        netByMonth[key] = (netByMonth[key] ?? 0) + txn.amount.abs();
      }
    }

    double totalPct = 0;
    int counted = 0;

    incomeByMonth.forEach((key, income) {
      if (income > 0) {
        final net = netByMonth[key] ?? 0;
        final pct = (net / income) * 100;
        //print("pct = $pct");
        totalPct += pct;
        counted++;
      }
    });

    return counted > 0 ? totalPct / counted.toDouble() : 0.0;
  }

  Future<void> _refreshData() async {
    final box = Hive.box<Transaction>('transactions');
    double startingPercentage = calculateAverageSavingPercentage();
    final freshSeries = {
      for (var y in years)
        y: List.generate(12, (_) {
          final val = startingPercentage + (rng.nextDouble() * 6 - 3);
          return val.clamp(0.0, 100.0);
        }),
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
      final resp = await ApiService().fetchAdvice(
        moneySaved,
        mygoal,
        pace,
        moneyGoal,
      );
      if (!mounted) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      setState(() => _advice = content.trim());
    } catch (_) {
      if (!mounted) return;
      setState(() => _advice = 'Could not load advice.');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
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
        // backgroundColor: Colors.grey[100],
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
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    final colors = [Colors.pinkAccent, Colors.purple, Colors.green];
    final currentYear = DateTime.now().year;

    final lineBarsData = List.generate(3, (i) {
      final year = (currentYear + i + 1).toString(); // +1 starts from next year
      return _makeLineBar(_series[year]!, colors[i]);
    });

    final maxY = (_series.values.expand((e) => e).reduce(max) + 10)
        .ceilToDouble();
    final interval = _niceInterval(maxY);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
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
              final index = int.parse(y) - DateTime.now().year - 1;
              final color = colors[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
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
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade300, strokeWidth: 1),
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
                      interval: interval,
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
                  const TextSpan(
                    text: 'At your current pace, you\'ll reach your goal by ',
                  ),
                  TextSpan(
                    text: '$_goalDateText.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
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
        getDotPainter:
            (FlSpot spot, double _percent, LineChartBarData bar, int index) {
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 0,
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
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
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
            const Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(),
              ),
            )
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

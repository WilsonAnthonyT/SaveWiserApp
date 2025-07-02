import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'api_service.dart'; // Contains your ApiService.fetchAdvice()

class FutureStatisticsPage extends StatefulWidget {
  const FutureStatisticsPage({Key? key}) : super(key: key);

  @override
  _FutureStatisticsPageState createState() => _FutureStatisticsPageState();
}

class _FutureStatisticsPageState extends State<FutureStatisticsPage> {
  Map<String, List<double>> _series = {
    '2026': List.filled(12, 0),
    '2027': List.filled(12, 0),
    '2028': List.filled(12, 0),
  };
  String? _advice;
  bool _loadingAdvice = false;

  @override
  void initState() {
    super.initState();
    _loadGraphData();
    _getAdvice();
  }

  Future<void> _loadGraphData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('graph_data');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _series = decoded.map(
            (year, list) => MapEntry(
              year,
              List<double>.from((list as List).map((e) => e.toDouble())),
            ),
          );
        });
      } catch (_) {
        // handle parse error if needed
      }
    }
  }

  Future<void> _getAdvice() async {
    if (!mounted) return;

    setState(() => _loadingAdvice = true);

    try {
      final resp = await ApiService().fetchAdvice();
      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      final data = jsonDecode(resp.body);
      final content =
          (data['choices'] as List).first['message']['content'] as String;

      if (!mounted) return;
      setState(() {
        _advice = content.trim();
      });
    } catch (e) {
      print('Advice fetch error: $e');

      if (!mounted) return;
      setState(() {
        _advice = 'Error fetching advice';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loadingAdvice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SAVEWISER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- Predicted Savings Card ---
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Predicted Savings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (v, meta) {
                                  final idx = v.toInt();
                                  if (idx >= 0 && idx < months.length) {
                                    return Text(
                                      months[idx],
                                      style: const TextStyle(fontSize: 10),
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
                              ),
                            ),
                          ),
                          minX: 0,
                          maxX: 11,
                          minY: 0,
                          maxY:
                              (_series.values
                                          .expand((l) => l)
                                          .fold<double>(
                                            0,
                                            (p, e) => e > p ? e : p,
                                          ) +
                                      10)
                                  .ceilToDouble(),
                          lineBarsData: _series.entries.map((entry) {
                            final yearColor = {
                              '2026': Colors.pink,
                              '2027': Colors.deepPurple,
                              '2028': Colors.green,
                            }[entry.key]!;
                            return LineChartBarData(
                              spots: List.generate(
                                entry.value.length,
                                (i) => FlSpot(i.toDouble(), entry.value[i]),
                              ),
                              isCurved: true,
                              dotData: FlDotData(show: false),
                              color: yearColor,
                              barWidth: 2,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Placeholder text – replace with your calculated date
                    const Text(
                      "At your current pace, you'll reach your goal by October 18, 2026.",
                      style: TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Advice Card ---
            SizedBox(
              width: double.infinity,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'What to do with your savings?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_loadingAdvice)
                        Center(
                          child: SizedBox(
                            width: 48, // pick whatever diameter you like
                            height: 48,
                            child: CircularProgressIndicator(strokeWidth: 4),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

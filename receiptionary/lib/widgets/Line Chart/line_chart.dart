import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../service/receipt_service.dart';
import 'line_chart_model.dart';

class LineChartWidget extends StatefulWidget {
  final Map<String, Color> categoryColors;

  const LineChartWidget({
    super.key,
    required this.categoryColors,
  });

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool isLoading = true;
  List<LineData> lineDataList = [];
  bool isShowingMainData = true;

  @override
  void initState() {
    super.initState();
    selectedEndDate = DateTime.now();
    selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
    _loadData();
  }

  // line_chart_widget.dart içindeki _loadData fonksiyonu
  Future<void> _loadData() async {
    try {
      if (selectedStartDate == null || selectedEndDate == null) return;

      final dailyTotals =
          await ReceiptService.getDailyCategoryTotalsBetweenDates(
              selectedStartDate!, selectedEndDate!);

      // Her kategori için kümülatif verileri hesapla
      Map<String, List<FlSpot>> categoryData = {};

      // Tüm tarihleri sırala
      var sortedDates = dailyTotals.keys.toList()..sort();

      // Her kategori için başlangıç değerlerini oluştur
      Set<String> allCategories = {};
      for (var dayData in dailyTotals.values) {
        allCategories.addAll(dayData.keys);
      }

      for (var category in allCategories) {
        categoryData[category] = [];
        double cumulativeTotal = 0;

        for (var date in sortedDates) {
          final dayIndex =
              date.difference(selectedStartDate!).inDays.toDouble();
          final dayAmount = dailyTotals[date]?[category] ?? 0;
          cumulativeTotal += dayAmount;
          categoryData[category]!.add(FlSpot(dayIndex, cumulativeTotal));
        }
      }

      setState(() {
        lineDataList = categoryData.entries
            .map((entry) => LineData(entry.value, entry.key))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        isLoading = true;
      });
      _loadData();
    }
  }

  LineChartData get mainData {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 5,
            getTitlesWidget: (value, meta) {
              final date =
                  selectedStartDate!.add(Duration(days: value.toInt()));
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 10,
                child: Text(
                  DateFormat('MMM d', 'tr_TR').format(date),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 100,
            getTitlesWidget: (value, meta) {
              return Text(
                '₺${value.toInt()}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 4),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: selectedEndDate!.difference(selectedStartDate!).inDays.toDouble(),
      minY: 0,
      maxY: lineDataList.isEmpty
          ? 100
          : lineDataList
                  .map((data) => data.spots.map((spot) => spot.y).reduce(max))
                  .reduce(max) *
              1.2,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.blueAccent.withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final date =
                  selectedStartDate!.add(Duration(days: touchedSpot.x.toInt()));
              return LineTooltipItem(
                '${DateFormat('MMM d', "tr-TR").format(date)}\n₺${touchedSpot.y.toStringAsFixed(2)}',
                const TextStyle(color: Colors.black),
              );
            }).toList();
          },
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipMargin: 8,
        ),
      ),
      lineBarsData: lineDataList.map((lineData) {
        final color = widget.categoryColors[lineData.category] ?? Colors.grey;
        return LineChartBarData(
          spots: lineData.spots,
          curveSmoothness: 0.0,
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.0),
                color.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, left: 6),
                      child: LineChart(mainData),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLegend(),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.date_range,
                  color: Colors.black,
                ),
                onPressed: () => _selectDateRange(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.0,
      runSpacing: 8.0,
      children: lineDataList.map((data) {
        final color = widget.categoryColors[data.category] ?? Colors.grey;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 6, // Yuvarlağın boyutunu ayarlayabilirsiniz
            ),
            const SizedBox(width: 4),
            Text(
              data.category,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

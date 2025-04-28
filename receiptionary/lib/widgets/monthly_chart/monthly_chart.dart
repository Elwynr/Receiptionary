import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:collection';
import '../../service/receipt_service.dart';

class MonthlyChartWidget extends StatelessWidget {
  final int selectedYear;

  MonthlyChartWidget({super.key, required this.selectedYear});

  final Map<String, Color> categoryColors = LinkedHashMap.from({
    "Bebek ve Çocuk": Colors.blue,
    "Abur Cubur": Colors.red,
    "Dondurma": Colors.cyan,
    "Dondurulmuş Ürünler": Colors.teal,
    "Elektronik": Colors.purple,
    "Ev ve Yaşam": Colors.orange,
    "Evcil Hayvan": Colors.brown,
    "Ekmek ve Pastane": Colors.amber,
    "Et": Colors.deepOrange,
    "Giyim": Colors.indigo,
    "İçecek": Colors.green,
    "Kağıt Ürünler": Colors.yellow,
    "Kahvaltılık": Colors.lightGreen,
    "Kişisel Bakım ve Kozmetik": Colors.pink,
    "Meyve ve Sebze": Colors.lime,
    "Oyuncak": Colors.deepPurple,
    "Süt ve Süt Ürünleri": Colors.lightBlue,
    "Temizlik": Colors.deepPurpleAccent,
    "Yemeklik Malzeme": Colors.lightGreenAccent,
    "Diğer": Colors.grey,
  });

  final double betweenSpace = 1.0;

  BarChartGroupData generateGroupData(
    int x,
    Map<String, double> categoryTotals,
  ) {
    final List<BarChartRodData> barRods = [];
    double currentY = 0;

    // Sadece sıfırdan büyük değerleri işle
    for (var category in categoryColors.keys) {
      if (categoryTotals[category] != null && categoryTotals[category]! > 0) {
        barRods.add(
          BarChartRodData(
            fromY: currentY,
            toY: currentY + categoryTotals[category]!,
            color: categoryColors[category]!,
            width: 20,
            borderRadius:
                const BorderRadius.all(Radius.circular(0)), // Düz köşeler
          ),
        );
        currentY = currentY + categoryTotals[category]! + betweenSpace;
      }
    }

    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: barRods,
      barsSpace: 100,
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final date = DateTime(2023, value.toInt() + 1);
    final monthName = DateFormat.MMM('tr_TR').format(date);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(monthName, style: style),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.toInt().toString(), style: style),
    );
  }

  double findMaxY(Map<int, Map<String, double>> monthlyCategoryTotals) {
    double maxY = 0.0;
    monthlyCategoryTotals.forEach((month, categoryTotals) {
      final Map<String, double> nonZeroTotals = {};
      for (var category in categoryColors.keys) {
        if (categoryTotals[category] != null && categoryTotals[category]! > 0) {
          nonZeroTotals[category] = categoryTotals[category]!;
        }
      }

      final double monthTotal =
          nonZeroTotals.values.fold(0.0, (prev, curr) => prev + curr);
      if (monthTotal > maxY) {
        maxY = monthTotal;
      }
    });
    return maxY;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, Map<String, double>>>(
      future: ReceiptService.getMonthlyCategoryTotals(year: selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No data available for the selected year'));
        }

        final monthlyCategoryTotals = snapshot.data!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.9,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: leftTitles,
                        reservedSize: 35,
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 20,
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      direction: TooltipDirection.top,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final nonZeroCategories = categoryColors.keys
                            .where((category) =>
                                monthlyCategoryTotals[group.x + 1]?[category] !=
                                    null &&
                                monthlyCategoryTotals[group.x + 1]![category]! >
                                    0)
                            .toList();
                        final category = nonZeroCategories[rodIndex];
                        final total = (rod.toY - rod.fromY).toInt();
                        return BarTooltipItem(
                          '$category\n$total',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(12, (index) {
                    final month = index + 1;
                    final categoryTotals = monthlyCategoryTotals[month] ?? {};
                    return generateGroupData(index, categoryTotals);
                  }),
                  maxY: findMaxY(monthlyCategoryTotals),
                  groupsSpace: 30,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Kategoriye göre aylık harcama',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: categoryColors.entries.map((entry) {
                    return Legend(entry.key, entry.value);
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Legend extends StatelessWidget {
  final String text;
  final Color color;

  const Legend(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
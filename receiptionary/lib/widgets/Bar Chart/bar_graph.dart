import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:receiptionary/pages/receipt_view_page.dart';
import 'package:receiptionary/service/receipt_service.dart';
import 'package:receiptionary/model/receipt.dart';

import 'bar_data.dart';

class BarGraph extends StatefulWidget {
  final BarData barData;

  const BarGraph({super.key, required this.barData});

  @override
  State<BarGraph> createState() => _BarGraphState();
}

class _BarGraphState extends State<BarGraph> {
  late DateTime selectedWeekStart;
  List<BarChartGroupData> barGroups = [];
  bool isLoading = true;
  Map<int, List<Receipt>> dailyReceipts = {};

  @override
  void initState() {
    super.initState();
    selectedWeekStart = getWeekStart(DateTime.now());
    initializeDateFormatting('tr', null);
    _loadData();
  }

  DateTime getWeekStart(DateTime date) {
    DateTime normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  List<Map<String, String>> getWeeklyDates(DateTime weekStart) {
    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return {
        "date": DateFormat('d MMM', 'tr').format(day),
        "day": DateFormat('EEEE', 'tr').format(day),
      };
    });
  }

  Future<void> _loadData() async {
    DateTime weekStart = selectedWeekStart;
    DateTime weekEnd = weekStart.add(const Duration(days: 6));

    List<Receipt> allReceipts = await ReceiptService.getAllReceipts();

    List<Receipt> receipts = allReceipts.where((receipt) {
      return receipt.dateTime.isAfter(weekStart) &&
          receipt.dateTime.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();

    Map<int, double> weeklyTotals = {
      DateTime.monday: 0.0,
      DateTime.tuesday: 0.0,
      DateTime.wednesday: 0.0,
      DateTime.thursday: 0.0,
      DateTime.friday: 0.0,
      DateTime.saturday: 0.0,
      DateTime.sunday: 0.0,
    };

    Map<int, List<Receipt>> groupedReceipts = {
      DateTime.monday: [],
      DateTime.tuesday: [],
      DateTime.wednesday: [],
      DateTime.thursday: [],
      DateTime.friday: [],
      DateTime.saturday: [],
      DateTime.sunday: [],
    };

    for (var receipt in receipts) {
      int weekday = receipt.dateTime.weekday;
      double receiptTotal = receipt.products.fold(
        0.0,
        (sum, product) => sum + (product.price * product.quantity),
      );
      weeklyTotals[weekday] = weeklyTotals[weekday]! + receiptTotal;
      groupedReceipts[weekday]!.add(receipt);
    }

    List<BarChartGroupData> groups = List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyTotals[index + 1]!,
            color: Colors.blue,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    setState(() {
      barGroups = groups;
      dailyReceipts = groupedReceipts;
      isLoading = false;
    });
  }

  void _showDetails(int weekday) {
    List<Receipt> receipts = dailyReceipts[weekday] ?? [];
    String selectedDay = getWeeklyDates(selectedWeekStart)[weekday - 1]['day']!;
    String selectedDate =
        getWeeklyDates(selectedWeekStart)[weekday - 1]['date']!;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '$selectedDate Harcamaları',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView(
                children: receipts.map((receipt) {
                  final totalAmount = receipt.products.fold(
                    0.0,
                    (sum, product) => sum + (product.price * product.quantity),
                  );
                  return ListTile(
                    title: Text(receipt.market),
                    trailing: Text(
                      '₺${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      // Tıklanan fişin detayına yönlendirme
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiptViewPage(
                            receiptId: receipt.id,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> weekDays = getWeeklyDates(selectedWeekStart);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<DateTime>(
            value: selectedWeekStart,
            items: List.generate(4, (index) {
              final weekStart = getWeekStart(
                  DateTime.now().subtract(Duration(days: 7 * index)));
              final weekEnd = weekStart.add(const Duration(days: 6));
              return DropdownMenuItem<DateTime>(
                value: weekStart,
                child: Text(
                  '${DateFormat('d MMM', 'tr').format(weekStart)} - ${DateFormat('d MMM', 'tr').format(weekEnd)}',
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedWeekStart = value;
                });
                _loadData();
              }
            },
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < weekDays.length) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            weekDays[index]['day']!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            weekDays[index]['date']!,
                                            style: const TextStyle(fontSize: 9),
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: barGroups,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                '${weekDays[index]['day']} (${weekDays[index]['date']})',
                                style: const TextStyle(fontSize: 16),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _showDetails(index + 1),
                                child: const Text('Detaylı Bilgi'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

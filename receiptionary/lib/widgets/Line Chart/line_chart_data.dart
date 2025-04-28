import 'package:fl_chart/fl_chart.dart';
import 'package:receiptionary/model/receipt.dart';
import 'package:receiptionary/service/receipt_service.dart';
import 'line_chart_model.dart';

Future<List<LineData>> getLineChartData(
    DateTime startDate, DateTime endDate) async {
  final dailyTotals = await ReceiptService.getDailyCategoryTotalsBetweenDates(
      startDate, endDate);

  // Tüm kategorileri bul
  Set<String> allCategories = {};
  for (var dayData in dailyTotals.values) {
    allCategories.addAll(dayData.keys);
  }

  // Her kategori için LineData oluştur
  List<LineData> lineDataList = [];

  for (String category in allCategories) {
    List<FlSpot> spots = [];
    double cumulativeTotal = 0.0;

    // Tüm günleri sırala
    var sortedDates = dailyTotals.keys.toList()..sort();

    for (var date in sortedDates) {
      // Günün indeksini hesapla
      final dayIndex = date.difference(startDate).inDays.toDouble();

      // O gün için kategori toplamını al
      final dayAmount = dailyTotals[date]?[category] ?? 0.0;
      cumulativeTotal += dayAmount;

      // Spot'u ekle
      spots.add(FlSpot(dayIndex, cumulativeTotal));
    }

    // Kategori için LineData oluştur
    lineDataList.add(LineData(spots, category));
  }

  return lineDataList;
}

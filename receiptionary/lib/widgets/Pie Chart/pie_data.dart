import 'individual_pie.dart';

class PieData {
  final List<IndividualPie> pieData = [];

  // Veri eklemek için bir fonksiyon
  void initializePieData(Map<String, double> categoryTotals) {
    pieData.clear();
    categoryTotals.forEach((category, value) {
      pieData.add(IndividualPie(category: category, value: value));
    });
  }
}

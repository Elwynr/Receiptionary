import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:receiptionary/service/receipt_service.dart';
import 'package:receiptionary/model/receipt.dart';
import 'pie_data.dart';

class PieChartWidget extends StatefulWidget {
  final PieData pieData;

  const PieChartWidget({super.key, required this.pieData});

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  bool isLoading = true;
  String? selectedCategory;
  Map<String, Map<String, double>> subcategoryData = {};
  int? touchedSectionIndex;

  final Map<String, Color> categoryColors = {
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
  };

  @override
  void initState() {
    super.initState();

    // AnimationController'ı başlat
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    initializeDateFormatting('tr', null);
    selectedEndDate = DateTime.now();
    selectedStartDate = DateTime.now().subtract(const Duration(days: 30));

    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (selectedStartDate == null || selectedEndDate == null) return;

      DateTime startDate = selectedStartDate!;
      DateTime endDate = selectedEndDate!;

      List<Receipt> allReceipts = await ReceiptService.getAllReceipts();
      List<Receipt> receipts = allReceipts.where((receipt) {
        return receipt.dateTime.isAfter(startDate) &&
            receipt.dateTime.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      Map<String, double> categoryTotals = {};
      Map<String, Map<String, double>> tempSubcategoryData = {};

      for (var receipt in receipts) {
        for (var product in receipt.products) {
          categoryTotals[product.category] =
              (categoryTotals[product.category] ?? 0) +
                  (product.price * product.quantity);

          tempSubcategoryData.putIfAbsent(product.category, () => {});
          tempSubcategoryData[product.category]![product.subcategory] =
              (tempSubcategoryData[product.category]![product.subcategory] ??
                      0) +
                  (product.price * product.quantity);
        }
      }

      widget.pieData.initializePieData(categoryTotals);
      subcategoryData = tempSubcategoryData;

      setState(() {
        isLoading = false;
      });

      // Veriler yüklendiğinde animasyonu başlat
      _controller.forward(from: 0.0);
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
        selectedCategory = null;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.pieData.pieData.fold(
      0.0,
      (sum, element) => sum + element.value,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => _selectDateRange(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                selectedStartDate != null && selectedEndDate != null
                    ? '${DateFormat('d MMM', 'tr').format(selectedStartDate!)} - ${DateFormat('d MMM', 'tr').format(selectedEndDate!)}'
                    : 'Tarih Aralığı Seçin',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    SizedBox(
                      height: 330,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return PieChart(
                            PieChartData(
                              sections: widget.pieData.pieData.map((data) {
                                final percentage =
                                    (data.value / totalAmount) * 100;
                                final color = categoryColors[data.category] ??
                                    Colors.grey;
                                final isTouched = touchedSectionIndex ==
                                    widget.pieData.pieData.indexOf(data);

                                return PieChartSectionData(
                                  color: isTouched
                                      ? color.withOpacity(0.8)
                                      : color,
                                  value: percentage *
                                      _controller.value, // Animate the value
                                  title: isTouched
                                      ? '${data.category}\n${percentage.toStringAsFixed(1)}%'
                                      : (percentage >= 3 ? data.category : ''),
                                  radius: isTouched ? 60 : 50,
                                  titleStyle: TextStyle(
                                    fontSize: isTouched ? 14 : 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(2.0, 2.0),
                                        blurRadius: 3.0,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                  titlePositionPercentageOffset: 0.5,
                                );
                              }).toList(),
                              borderData: FlBorderData(show: false),
                              centerSpaceRadius: 100,
                              sectionsSpace: 2,
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      touchedSectionIndex = -1;
                                      return;
                                    }
                                    touchedSectionIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toplam Harcama: ₺${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.pieData.pieData.length,
                        itemBuilder: (context, index) {
                          widget.pieData.pieData.sort((a, b) {
                            final double percentageA =
                                (a.value / totalAmount) * 100;
                            final double percentageB =
                                (b.value / totalAmount) * 100;
                            return percentageB.compareTo(percentageA);
                          });

                          final data = widget.pieData.pieData[index];
                          final percentage = (data.value / totalAmount) * 100;
                          final color =
                              categoryColors[data.category] ?? Colors.grey;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color,
                              radius:
                                  8, // Yuvarlağın boyutunu ayarlayabilirsiniz
                            ),
                            title: Text(
                              '${data.category} (%${percentage.toStringAsFixed(1)})',
                            ),
                            trailing: Text(
                              '₺${data.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedCategory = data.category;
                              });
                              showModalBottomSheet(
                                context: context,
                                builder: (_) =>
                                    _buildSubcategoryView(data.category),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryView(String category) {
    final subcategories = subcategoryData[category] ?? {};

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Alt Kategoriler: $category',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final entry = subcategories.entries.elementAt(index);
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Text(
                      '₺${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

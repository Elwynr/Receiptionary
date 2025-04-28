import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../widgets/Bar Chart/bar_data.dart';
import '../widgets/Bar Chart/bar_graph.dart';
import '../widgets/Line Chart/line_chart.dart'; // Updated LineChartWidget
import '../widgets/Pie Chart/pie_chart.dart';
import '../widgets/Pie Chart/pie_data.dart';
import '../widgets/monthly_chart/monthly_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<PieData> _pieData; // Pie chart için Future verisi
  late Future<BarData> _barData; // Bar chart için Future verisi

  final PageController _pageController = PageController();
  int _currentPage = 0;

  int selectedYear = DateTime.now().year; // Default to the current year
  final List<int> years = List.generate(
      10, (index) => DateTime.now().year - index); // Last 10 years

  @override
  void initState() {
    super.initState();
    _pieData = getPieChartData(); // Pie chart için veriyi yükle
    _barData = getWeeklyData(); // Bar chart için veriyi yükle
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  Future<PieData> getPieChartData() async {
    // API veya servisten gerçek verileri almak için burayı doldurun.
    await Future.delayed(const Duration(seconds: 1)); // Örnek bir gecikme
    PieData pieData = PieData();
    pieData.initializePieData({
      "Kategori 1": 30.0,
      "Kategori 2": 40.0,
      "Kategori 3": 50.0,
    });
    return pieData;
  }

  Future<BarData> getWeeklyData() async {
    // API veya servisten gerçek verileri almak için burayı doldurun.
    await Future.delayed(const Duration(seconds: 1)); // Örnek bir gecikme
    return BarData(
      monAmount: 10.0,
      tueAmount: 20.0,
      wedAmount: 15.0,
      thuAmount: 30.0,
      friAmount: 25.0,
      satAmount: 40.0,
      sunAmount: 35.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  // Sayfa değiştiğinde Future'ları yeniden yükle
                  if (index == 0) {
                    _pieData = getPieChartData();
                  } else if (index == 2) {
                    _barData = getWeeklyData();
                  }
                });
              },
              children: [
                // Pie chart FutureBuilder
                FutureBuilder<PieData>(
                  future: _pieData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      return PieChartWidget(pieData: snapshot.data!);
                    } else {
                      return const Center(child: Text('Veri bulunamadı'));
                    }
                  },
                ),

                // Bar chart FutureBuilder
                FutureBuilder<BarData>(
                  future: _barData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      return BarGraph(barData: snapshot.data!);
                    } else {
                      return const Center(child: Text('Veri bulunamadı'));
                    }
                  },
                ),

                // Line chart
                // const LineChartWidget(
                //   categoryColors: {
                //     "Bebek ve Çocuk": Colors.blue,
                //     "Abur Cubur": Colors.red,
                //     "Dondurma": Colors.cyan,
                //     "Dondurulmuş Ürünler": Colors.teal,
                //     "Elektronik": Colors.purple,
                //     "Ev ve Yaşam": Colors.orange,
                //     "Evcil Hayvan": Colors.brown,
                //     "Ekmek ve Pastane": Colors.amber,
                //     "Et": Colors.deepOrange,
                //     "Giyim": Colors.indigo,
                //     "İçecek": Colors.green,
                //     "Kağıt Ürünler": Colors.yellow,
                //     "Kahvaltılık": Colors.lightGreen,
                //     "Kişisel Bakım ve Kozmetik": Colors.pink,
                //     "Meyve ve Sebze": Colors.lime,
                //     "Oyuncak": Colors.deepPurple,
                //     "Süt ve Süt Ürünleri": Colors.lightBlue,
                //     "Temizlik": Colors.deepPurpleAccent,
                //     "Yemeklik Malzeme": Colors.lightGreenAccent,
                //     "Diğer": Colors.grey,
                //   },
                // ),

                // MonthlyChartWidget wrapped in a Container with DropdownMenu
                Container(
                  padding:
                      const EdgeInsets.only(left: 15, right: 15, bottom: 20),
                  child: Column(
                    children: [
                      // Year selection dropdown
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: DropdownButton<int>(
                            value: selectedYear,
                            onChanged: (int? newValue) {
                              setState(() {
                                selectedYear = newValue!;
                              });
                            },
                            items:
                                years.map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // MonthlyChartWidget
                      Expanded(
                        child: MonthlyChartWidget(selectedYear: selectedYear),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 3,
              effect: const WormEffect(
                activeDotColor: Colors.green,
                dotColor: Colors.grey,
                dotHeight: 8,
                dotWidth: 8,
                spacing: 4,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[],
      ),
    );
  }
}
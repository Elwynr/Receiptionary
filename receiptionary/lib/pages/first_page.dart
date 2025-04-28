import 'package:flutter/material.dart';
import 'package:receiptionary/pages/history_page.dart';
import 'package:receiptionary/pages/home_page.dart';
import 'package:receiptionary/pages/oss_licenses_page.dart';
import 'package:receiptionary/pages/settings_page.dart';
import 'package:receiptionary/pages/stats_page.dart';
import 'package:url_launcher/url_launcher.dart';

import 'table_page.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _selectedIndex = 0;
  late List _pages;

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List _appBarTitles = [
    'Anasayfa',
    'İstatistikler',
    'Ürünler',
    'Alışverişler',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onNavigateBottomBar: navigateBottomBar),
      const StatsPage(),
      const TablePage(),
      const HistoryPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
      ),
      body: _pages[_selectedIndex],
      drawer: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Ayarlar"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text("Bize Ulaşın"),
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'info@localhost.com',
                  query: encodeQueryParameters({
                    'subject': 'About receipt app',
                    'body': 'Hi,\n\n',
                  }),
                );
                launchUrl(emailLaunchUri);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("Hakkında"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const OssLicensesPage()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: navigateBottomBar,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Anasayfa"),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              label: "İstatistikler"),
          BottomNavigationBarItem(
              icon: Icon(Icons.table_chart), label: "Ürünler"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), label: "Alışverişlerim"),
        ],
        selectedItemColor: Colors.green, // Aktif ikon rengi
        unselectedItemColor: Colors.grey, // Pasif ikon rengi
        backgroundColor: Colors.white, // Arka plan rengi
      ),
    );
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

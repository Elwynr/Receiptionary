import 'package:flutter/material.dart';

import 'first_page.dart';
import 'manuel_data_input_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fiş logu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const FirstPage(),
      routes: {
        '/manuel_data_input_page': (context) => const ManuelDataInputPage(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/app.dart';
import 'service/receipt_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReceiptService.initialize();
  await initializeDateFormatting('tr-TR');
  runApp(const App());
}

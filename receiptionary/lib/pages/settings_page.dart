import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:receiptionary/model/receipt.dart';
import '../service/receipt_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedEngine = 'Google ML Kit';

  @override
  void initState() {
    super.initState();
    ReceiptService.initialize();
    _loadSelectedEngine();
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request storage permissions
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      // For Android 11 and above, request manage external storage permission
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true;
  }

  Future<void> _loadSelectedEngine() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedEngine = prefs.getString('selectedEngine') ?? 'Google ML Kit';
    });
  }

  Future<void> _saveSelectedEngine(String engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedEngine', engine);
    setState(() {
      _selectedEngine = engine;
    });
  }

  Map<String, dynamic> serializeReceipt(Receipt receipt) {
    return {
      'id': receipt.id,
      'market': receipt.market,
      'dateTime': receipt.dateTime.toIso8601String(),
      'products': receipt.products.map((product) {
        return {
          'productName': product.productName,
          'quantity': product.quantity,
          'price': product.price,
          'category': product.category,
          'subcategory': product.subcategory,
        };
      }).toList(),
    };
  }

  Receipt deserializeReceipt(Map<String, dynamic> json) {
    final receipt = Receipt()
      ..id = json['id']
      ..market = json['market']
      ..dateTime = DateTime.parse(json['dateTime'])
      ..products = (json['products'] as List).map((productJson) {
        final product = Product()
          ..productName = productJson['productName']
          ..quantity = productJson['quantity']
          ..price = productJson['price'].toDouble()
          ..category = productJson['category']
          ..subcategory = productJson['subcategory'];
        return product;
      }).toList();
    return receipt;
  }

  Future<void> exportReceipts() async {
    try {
      if (!await _requestPermissions()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      // Let the user select a directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No directory selected")),
        );
        return;
      }

      final receipts = await ReceiptService.getAllReceipts();
      final jsonReceipts =
          receipts.map((receipt) => serializeReceipt(receipt)).toList();
      final jsonString = jsonEncode(jsonReceipts);

      // Define the file name and path
      final fileName = 'receipts_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '$selectedDirectory/$fileName';

      // Write the file to the selected directory
      final file = File(filePath);
      await file.writeAsString(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Receipts exported successfully to $filePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export failed: ${e.toString()}")),
      );
    }
  }

  Future<void> importReceipts() async {
    try {
      if (!await _requestPermissions()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        final jsonReceipts = jsonDecode(jsonString) as List<dynamic>;
        final receipts =
            jsonReceipts.map((json) => deserializeReceipt(json)).toList();

        for (final receipt in receipts) {
          await ReceiptService.addReceipt(receipt);
        }

        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receipts imported successfully")),
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();
        throw Exception("Failed to process JSON: ${e.toString()}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text("Dışa Aktar"),
            onTap: exportReceipts,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("İçe Aktar"),
            onTap: importReceipts,
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Görsel Motoru"),
            subtitle: Text(_selectedEngine),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Görsel Motoru Seçin"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text("Google ML Kit"),
                          onTap: () {
                            _saveSelectedEngine('Google ML Kit');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("PaddleOCR"),
                          onTap: () {
                            _saveSelectedEngine('PaddleOCR');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: const Text("Gemini Image Input"),
                          onTap: () {
                            _saveSelectedEngine('Gemini Image Input');
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
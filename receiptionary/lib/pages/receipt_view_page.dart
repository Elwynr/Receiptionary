import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/receipt.dart';
import '../service/receipt_service.dart';
import 'manuel_data_input_page.dart';

class ReceiptViewPage extends StatefulWidget {
  final int receiptId;

  const ReceiptViewPage({super.key, required this.receiptId});

  @override
  State<ReceiptViewPage> createState() => _ReceiptViewPageState();
}

class _ReceiptViewPageState extends State<ReceiptViewPage> {
  Receipt? _receipt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReceipt();
  }

  Future<void> _fetchReceipt() async {
    setState(() {
      _isLoading = true;
    });

    await ReceiptService.initialize();
    Receipt? fetchedReceipt =
        await ReceiptService.getReceiptById(widget.receiptId);

    setState(() {
      _receipt = fetchedReceipt;
      _isLoading = false;
    });
  }

  Future<void> _deleteReceipt() async {
    await ReceiptService.deleteReceipt(widget.receiptId);
    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fiş silindi.")),
    );
    // Navigate back to the previous screen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fiş Detayı"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManuelDataInputPage(
                    receiptId: widget.receiptId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Show a confirmation dialog before deleting
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Sil"),
                    content:
                        const Text("Bu fişi silmek istediğinize emin misiniz?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          _deleteReceipt();
                          // Call the delete function
                        },
                        child: const Text("Evet"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text("Hayır"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receipt == null
              ? const Center(child: Text("Fiş bulunamadı."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Market: ${_receipt!.market}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tarih: ${DateFormat('dd.MM.yyyy - HH:mm').format(_receipt!.dateTime)}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Ürünler:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(thickness: 2),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _receipt!.products.length,
                          itemBuilder: (context, index) {
                            final product = _receipt!.products[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.all(0),
                              title: Text(
                                product.productName,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                "${product.category} - ${product.subcategory}",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${product.quantity} x ${product.price.toStringAsFixed(2)} ₺",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(thickness: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Toplam: ${_receipt!.products.fold<double>(0, (sum, item) => sum + item.price * item.quantity).toStringAsFixed(2)} ₺",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

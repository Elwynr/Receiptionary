import 'package:flutter/material.dart';
import 'package:receiptionary/model/receipt.dart';
import 'package:receiptionary/service/receipt_service.dart';
import 'package:receiptionary/pages/receipt_view_page.dart';
import 'package:receiptionary/utils/categories.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String searchQuery = '';
  List<Receipt> receipts = [];
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, String>> selectedCategorySubcategories =
      []; // Store category-subcategory pairs
  List<String> selectedProducts = [];
  double? minPrice;
  double? maxPrice;

  // Add controllers for product input
  final TextEditingController productController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  // For dropdowns
  String? selectedCategory;
  String? selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _fetchInitialReceipts();
  }

  Future<void> _fetchInitialReceipts() async {
    List<Receipt> allReceipts = await ReceiptService.getAllReceipts();
    allReceipts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    setState(() {
      receipts = allReceipts.take(10).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Fişleri Filtrele'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Range Selection
                    const Text('Tarih Aralığı',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Başlangıç',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: startDate != null
                                  ? DateFormat('dd/MM/yyyy').format(startDate!)
                                  : '',
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => startDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Bitiş',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(endDate!)
                                  : '',
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price Range
                    const Text('Fiyat Aralığı',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Min Fiyat',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Max Fiyat',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category and Subcategory Selection
                    const Text('Kategori ve Alt Kategori',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                            ),
                            items: categories.keys.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                selectedCategory = value;
                                selectedSubcategory =
                                    null; // Reset subcategory when category changes
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedSubcategory,
                            decoration: const InputDecoration(
                              labelText: 'Alt Kategori',
                              border: OutlineInputBorder(),
                            ),
                            items: selectedCategory != null
                                ? categories[selectedCategory]
                                    ?.map((String subcategory) {
                                    return DropdownMenuItem<String>(
                                      value: subcategory,
                                      child: Text(subcategory),
                                    );
                                  }).toList()
                                : [],
                            onChanged: (String? value) {
                              setState(() {
                                selectedSubcategory = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (selectedCategory != null) {
                              setState(() {
                                selectedCategorySubcategories.add({
                                  'category': selectedCategory!,
                                  'subcategory': selectedSubcategory ?? '',
                                });
                                selectedCategory = null;
                                selectedSubcategory = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: selectedCategorySubcategories.map((item) {
                        return Chip(
                          label: Text(
                              '${item['category']}${item['subcategory']!.isNotEmpty ? ' > ${item['subcategory']}' : ''}'),
                          onDeleted: () {
                            setState(() {
                              selectedCategorySubcategories.remove(item);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Product Selection
                    const Text('Ürünler',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: productController,
                            decoration: const InputDecoration(
                              hintText: 'Ürün adı girin',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (productController.text.isNotEmpty) {
                              setState(() {
                                selectedProducts.add(productController.text);
                                productController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: selectedProducts.map((product) {
                        return Chip(
                          label: Text(product),
                          onDeleted: () {
                            setState(() {
                              selectedProducts.remove(product);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetFilters();
                  },
                  child: const Text('Sıfırla'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      startDate = null;
      endDate = null;
      selectedCategorySubcategories.clear();
      selectedProducts.clear();
      minPriceController.clear();
      maxPriceController.clear();
      minPrice = null;
      maxPrice = null;
      _fetchInitialReceipts();
    });
  }

  Future<void> _applyFilters() async {
    // Parse price values
    minPrice = double.tryParse(minPriceController.text);
    maxPrice = double.tryParse(maxPriceController.text);

    List<Receipt> allReceipts = await ReceiptService.getAllReceipts();

    List<Receipt> filteredReceipts = allReceipts.where((receipt) {
      // Date filter
      bool dateMatch = true;
      if (startDate != null) {
        dateMatch = dateMatch && receipt.dateTime.isAfter(startDate!);
      }
      if (endDate != null) {
        dateMatch = dateMatch &&
            receipt.dateTime.isBefore(endDate!.add(const Duration(days: 1)));
      }

      // Price filter
      double receiptTotal = receipt.products.fold(
          0.0, (sum, product) => sum + (product.price * product.quantity));
      bool priceMatch = true;
      if (minPrice != null) {
        priceMatch = priceMatch && receiptTotal >= minPrice!;
      }
      if (maxPrice != null) {
        priceMatch = priceMatch && receiptTotal <= maxPrice!;
      }

      // Category and Subcategory filter
      bool categoryMatch = true;
      if (selectedCategorySubcategories.isNotEmpty) {
        categoryMatch = receipt.products.any((product) {
          return selectedCategorySubcategories.any((filter) {
            bool categoryMatches = product.category == filter['category'];
            bool subcategoryMatches = filter['subcategory']!.isEmpty ||
                product.subcategory == filter['subcategory'];
            return categoryMatches && subcategoryMatches;
          });
        });
      }

      // Product filter
      bool productMatch = true;
      if (selectedProducts.isNotEmpty) {
        productMatch = receipt.products.any((product) => selectedProducts.any(
            (selectedProduct) => product.productName
                .toLowerCase()
                .contains(selectedProduct.toLowerCase())));
      }

      return dateMatch && priceMatch && categoryMatch && productMatch;
    }).toList();

    // Sort by date (newest first)
    filteredReceipts.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    setState(() {
      receipts = filteredReceipts;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter receipts based on search query
    List<Receipt> filteredList = receipts.where((receipt) {
      return receipt.market.toLowerCase().contains(searchQuery.toLowerCase()) ||
          receipt.products.any((product) => product.productName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()));
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Arama terimi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  var receipt = filteredList[index];
                  String formattedDate = DateFormat('dd/MM/yyyy')
                      .format(receipt.dateTime.toLocal());
                  String productNames =
                      receipt.products.map((p) => p.productName).join(', ');
                  String shortDescription = productNames.length > 50
                      ? '${productNames.substring(0, 50)}...'
                      : productNames;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ListTile(
                          title: Text(receipt.market),
                          subtitle: Text(
                            shortDescription,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReceiptViewPage(
                                  receiptId: receipt.id,
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2.0, vertical: 1.0),
                            decoration: BoxDecoration(
                              color: Colors.green.shade300,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8.0),
                                bottomRight: Radius.circular(0.0),
                                bottomLeft: Radius.circular(8.0),
                                topLeft: Radius.circular(0.0),
                              ),
                            ),
                            child: Text(
                              formattedDate,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

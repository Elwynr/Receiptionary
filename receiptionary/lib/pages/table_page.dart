import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/receipt.dart';
import '../service/receipt_service.dart';
import '../utils/categories.dart';

class TablePage extends StatefulWidget {
  const TablePage({super.key});

  @override
  _TablePageState createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  bool isAscending = true;
  int? sortColumnIndex;
  List<Receipt> receipts = [];
  List<Product> products = [];
  List<Receipt> filteredReceipts = [];
  List<Product> filteredProducts = [];

// Filtreleme değişkenleri
  DateTime? startDate;
  DateTime? endDate;
  List<Map<String, String>> selectedCategorySubcategories = [];
  List<String> selectedProducts = [];
  double? minPrice;
  double? maxPrice;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController productController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  List<Map<String, dynamic>> sortedProductReceiptPairs = [];

  String? selectedCategory;
  String? selectedSubcategory;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final fetchedReceipts = await ReceiptService.getReceiptsWithLimit(100);
    if (mounted) {
      setState(() {
        receipts = fetchedReceipts;
        filteredReceipts = List.from(receipts);

        // Tüm ürünleri birleştirerek products listesini doldurun.
        products = receipts.expand((receipt) => receipt.products).toList();
        filteredProducts =
            List.from(products); // Başlangıçta tüm ürünleri göstermek için.
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ürünleri Filtrele'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
// Tarih Aralığı
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
                                  ? DateFormat('dd MMM', 'tr-TR')
                                      .format(startDate!)
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
                                  ? DateFormat('dd MMM', 'tr-TR')
                                      .format(endDate!)
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

                    // Fiyat Aralığı
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

                    // Kategori ve Alt Kategori Seçimi
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
                                selectedSubcategory = null;
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

                    // Ürün Seçimi
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
      _loadReceipts();
    });
  }

  Future<void> _applyFilters() async {
    minPrice = double.tryParse(minPriceController.text);
    maxPrice = double.tryParse(maxPriceController.text);

    List<Product> filteredProductList =
        await ReceiptService.filterProductsWithMultipleCategories(
      startDate: startDate,
      endDate: endDate,
      categorySubcategoryPairs: selectedCategorySubcategories,
      productNames: selectedProducts,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    setState(() {
      filteredProducts = filteredProductList;
      // Update receipts based on filtered products
      filteredReceipts = receipts.where((receipt) {
        return receipt.products.any((product) => filteredProducts.any((fp) =>
            fp.productName == product.productName &&
            fp.category == product.category &&
            fp.subcategory == product.subcategory));
      }).toList();
    });
  }

  void _sortData(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;

      if (columnIndex == 0) {
        // Tarih
        filteredReceipts.sort((a, b) => ascending
            ? a.dateTime.compareTo(b.dateTime)
            : b.dateTime.compareTo(a.dateTime));
      } else if (columnIndex == 1) {
        // Market - büyük/küçük harf duyarsız
        filteredReceipts.sort((a, b) => ascending
            ? a.market.toLowerCase().compareTo(b.market.toLowerCase())
            : b.market.toLowerCase().compareTo(a.market.toLowerCase()));
      } else {
        // Ürün bazlı sıralama için tüm ürün-fiş çiftlerini içeren bir liste oluştur
        List<Map<String, dynamic>> productReceiptPairs = [];

        for (var receipt in filteredReceipts) {
          for (var product in receipt.products) {
            if (filteredProducts.any((fp) =>
                fp.productName == product.productName &&
                fp.category == product.category &&
                fp.subcategory == product.subcategory)) {
              productReceiptPairs.add({
                'receipt': receipt,
                'product': product,
              });
            }
          }
        }

        // Sıralama
        productReceiptPairs.sort((a, b) {
          Product productA = a['product'];
          Product productB = b['product'];
          int compareResult;

          switch (columnIndex) {
            case 2: // Ürün Adı - büyük/küçük harf duyarsız
              compareResult = productA.productName
                  .toLowerCase()
                  .compareTo(productB.productName.toLowerCase());
              break;
            case 3: // Miktar
              compareResult = productA.quantity.compareTo(productB.quantity);
              break;
            case 4: // Fiyat
              compareResult = (productA.price * productA.quantity)
                  .compareTo(productB.price * productB.quantity);
              break;
            case 5: // Kategori - büyük/küçük harf duyarsız
              compareResult = productA.category
                  .toLowerCase()
                  .compareTo(productB.category.toLowerCase());
              break;
            case 6: // Alt Kategori - büyük/küçük harf duyarsız
              compareResult = productA.subcategory
                  .toLowerCase()
                  .compareTo(productB.subcategory.toLowerCase());
              break;
            default:
              compareResult = 0;
          }
          return ascending ? compareResult : -compareResult;
        });

        // Sıralanmış çiftleri sakla
        sortedProductReceiptPairs = productReceiptPairs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Arka plan rengi beyaz
                borderRadius: BorderRadius.circular(16.0), // Kenar yuvarlaklığı
                border: Border.all(color: Colors.grey), // Kenar çizgisi
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Ürün ara...',
                        border: InputBorder.none, // Kenar çizgisini kaldır
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 12), // İç boşluk
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            filteredProducts = List.from(products);
                            filteredReceipts = List.from(receipts);
                          } else {
                            filteredProducts = products.where((product) {
                              return product.productName
                                      .toLowerCase()
                                      .contains(value.toLowerCase()) ||
                                  product.category
                                      .toLowerCase()
                                      .contains(value.toLowerCase()) ||
                                  product.subcategory
                                      .toLowerCase()
                                      .contains(value.toLowerCase());
                            }).toList();

                            filteredReceipts = receipts.where((receipt) {
                              return receipt.products.any((product) =>
                                  filteredProducts.any((fp) =>
                                      fp.productName == product.productName &&
                                      fp.category == product.category &&
                                      fp.subcategory == product.subcategory));
                            }).toList();
                          }
                        });
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Arka plan rengi beyaz
                      borderRadius:
                          BorderRadius.circular(8), // Kenar yuvarlaklığı
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  sortAscending: isAscending,
                  sortColumnIndex: sortColumnIndex,
                  columns: [
                    DataColumn(
                      label: const Text('Tarih'),
                      onSort: (columnIndex, ascending) {
                        _sortData(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Market'),
                      onSort: (columnIndex, ascending) {
                        _sortData(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Ürün Adı'),
                      onSort: (columnIndex, ascending) {
                        _sortData(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Miktar'),
                      numeric: true,
                      onSort: (columnIndex, ascending) {
                        _sortData(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Fiyat'),
                      numeric: true,
                      onSort: (columnIndex, ascending) {
                        _sortData(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Kategori'),
                      onSort: (columnIndex, ascending) {
                        _sortData(columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text('Alt Kategori'),
                      onSort: (columnIndex, ascending) {
                        _sortData(columnIndex, ascending);
                      },
                    ),
                  ],
                  rows: _buildDataRows(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildDataRows() {
    if (sortColumnIndex != null && sortColumnIndex! > 1) {
      // Ürün bazlı sıralama için
      return sortedProductReceiptPairs.map((pair) {
        Receipt receipt = pair['receipt'];
        Product product = pair['product'];

        return DataRow(
          cells: [
            DataCell(
                Text(DateFormat('dd MMM', 'tr-TR').format(receipt.dateTime))),
            DataCell(Text(receipt.market)),
            DataCell(Text(product.productName)),
            DataCell(Text(product.quantity.toString())),
            DataCell(
                Text((product.price * product.quantity).toStringAsFixed(2))),
            DataCell(Text(product.category)),
            DataCell(Text(product.subcategory)),
          ],
        );
      }).toList();
    } else {
      // Tarih ve market sıralaması için
      List<DataRow> rows = [];
      for (var receipt in filteredReceipts) {
        for (var product in receipt.products) {
          if (filteredProducts.any((fp) =>
              fp.productName == product.productName &&
              fp.category == product.category &&
              fp.subcategory == product.subcategory)) {
            rows.add(DataRow(
              cells: [
                DataCell(Text(
                    DateFormat('dd MMM', 'tr-TR').format(receipt.dateTime))),
                DataCell(Text(receipt.market)),
                DataCell(Text(product.productName)),
                DataCell(Text(product.quantity.toString())),
                DataCell(Text(
                    (product.price * product.quantity).toStringAsFixed(2))),
                DataCell(Text(product.category)),
                DataCell(Text(product.subcategory)),
              ],
            ));
          }
        }
      }
      return rows;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    productController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }
}
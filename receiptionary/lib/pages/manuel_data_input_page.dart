import 'package:flutter/material.dart';
import 'package:receiptionary/service/receipt_service.dart';
import 'package:intl/intl.dart';
import '../model/receipt.dart';
import '../utils/categories.dart';

class ManuelDataInputPage extends StatefulWidget {
  final Map<String, dynamic>? jsonResponseMap;
  final int? receiptId;

  const ManuelDataInputPage({
    super.key,
    this.jsonResponseMap,
    this.receiptId,
  });

  @override
  State<ManuelDataInputPage> createState() => _ManuelDataInputPageState();
}

class _ManuelDataInputPageState extends State<ManuelDataInputPage> {
  bool _isLoading = false;
  Receipt? editData;
  final formKey = GlobalKey<FormState>();
  final TextEditingController _marketNameController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  final List<TextEditingController> _productNameControllers = [];
  final List<TextEditingController> _productQuantityControllers = [];
  final List<TextEditingController> _productPriceControllers = [];
  final List<String> _selectedCategories = [];
  final List<String> _selectedSubcategories = [];

  final List<FocusNode> _focusNodes = [FocusNode()];
  final List<FocusNode> _categoryFocusNodes = [FocusNode()];
  final List<FocusNode> _subcategoryFocusNodes = [FocusNode()];

  @override
  void initState() {
    super.initState();
    ReceiptService.initialize();
    _initializeFormFields();
  }

  void _initializeFormFields() {
    if (widget.jsonResponseMap != null) {
      final data = widget.jsonResponseMap!;
      _marketNameController.text = data['market'] ?? '';
      List<dynamic> products = data['products'] ?? [];

      if (data['date'] != null) {
        final rawDate = data['date'];
        try {
          // Tarihi "dd.MM.yyyy" formatından DateTime nesnesine dönüştür
          final parts = rawDate.split(RegExp(r'[/.]'));
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            _selectedDate = DateTime(year, month, day);
          } else {
            print('Hatalı tarih formatı: $rawDate');
          }
        } catch (e) {
          print('Tarih dönüşüm hatası: $e');
        }
      }
      if (data['time'] != null) {
        try {
          final timeParts = data['time'].split(':');
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        } catch (e) {
          print('Saat formatı hatalı: $e');
        }
      }

      for (var product in products) {
        _productNameControllers.add(
          TextEditingController(text: product['productName']),
        );
        _productQuantityControllers.add(
          TextEditingController(text: product['quantity'].toString()),
        );
        _productPriceControllers.add(
          TextEditingController(text: product['price'].toString()),
        );
        _selectedCategories.add(product['category'] ?? '');
        _selectedSubcategories.add(product['subcategory'] ?? '');
        _focusNodes.add(FocusNode());
        _categoryFocusNodes.add(FocusNode());
        _subcategoryFocusNodes.add(FocusNode());
      }
    } else if (widget.receiptId != null) {
      _isLoading = true;
      final receiptId = widget.receiptId;
      _fetchReceipt(receiptId!);
    } else {
      _addNewRow();
    }
  }

  Future<void> _fetchReceipt(int receiptId) async {
    setState(() {
      _isLoading = true;
    });

    await ReceiptService.initialize();
    Receipt? fetchedData = await ReceiptService.getReceiptById(receiptId);

    setState(() {
      _isLoading = false;
      _marketNameController.text = fetchedData?.market ?? '';

      if (fetchedData?.dateTime != null) {
        DateTime fetchedDateTime = fetchedData!.dateTime;
        _selectedDate = DateTime(
            fetchedDateTime.year, fetchedDateTime.month, fetchedDateTime.day);
        _selectedTime = TimeOfDay(
            hour: fetchedDateTime.hour, minute: fetchedDateTime.minute);
      }

      List<Product> products = fetchedData!.products;

      for (var product in products) {
        _productNameControllers.add(
          TextEditingController(text: product.productName),
        );
        _productQuantityControllers.add(
          TextEditingController(text: product.quantity.toString()),
        );
        _productPriceControllers.add(
          TextEditingController(text: product.price.toString()),
        );
        _selectedCategories.add(product.category ?? '');
        _selectedSubcategories.add(product.subcategory ?? '');
        _focusNodes.add(FocusNode());
        _categoryFocusNodes.add(FocusNode());
        _subcategoryFocusNodes.add(FocusNode());
      }
    });
  }

  void _saveData() async {
    Receipt receipt = Receipt()
      ..market = _marketNameController.text
      ..dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

    for (int i = 0; i < _productNameControllers.length; i++) {
      String productName = _productNameControllers[i].text;
      double price = double.tryParse(_productPriceControllers[i].text) ?? 0.0;
      double quantity =
          double.tryParse(_productQuantityControllers[i].text) ?? 1.0;

      if (productName.isNotEmpty) {
        Product newProduct = Product()
          ..productName = productName
          ..quantity = quantity.toInt()
          ..price = price
          ..category = _selectedCategories[i]
          ..subcategory = _selectedSubcategories[i];

        receipt.products.add(newProduct);
      }
    }

    if (widget.receiptId != null) {
      receipt.id = widget.receiptId!;
      await ReceiptService.updateReceipt(receipt);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fiş güncellendi."),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      await ReceiptService.addReceipt(receipt);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fiş kaydedildi."),
          duration: Duration(seconds: 2),
        ),
      );
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _addNewRow() {
    setState(() {
      _productNameControllers.add(TextEditingController());
      _productQuantityControllers.add(TextEditingController(text: '1'));
      _productPriceControllers.add(TextEditingController());
      _selectedCategories.add('');
      _selectedSubcategories.add('');
      _focusNodes.add(FocusNode());
      _categoryFocusNodes.add(FocusNode());
      _subcategoryFocusNodes.add(FocusNode());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _productNameControllers[index].dispose();
      _productQuantityControllers[index].dispose();
      _productPriceControllers[index].dispose();
      _productNameControllers.removeAt(index);
      _productQuantityControllers.removeAt(index);
      _productPriceControllers.removeAt(index);
      _selectedCategories.removeAt(index);
      _selectedSubcategories.removeAt(index);
      _focusNodes[index].dispose();
      _categoryFocusNodes[index].dispose();
      _subcategoryFocusNodes[index].dispose();
      _focusNodes.removeAt(index);
      _categoryFocusNodes.removeAt(index);
      _subcategoryFocusNodes.removeAt(index);
    });
  }

  List<String> _getSubcategories(int index) {
    String category = _selectedCategories[index];
    return categories[category] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Veri Girişi'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
              size: 35,
              color: Colors.black,
            ),
            onPressed: _saveData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextField(
                      controller: _marketNameController,
                      decoration: const InputDecoration(
                        labelText: 'Market Adı',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Tarih',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: DateFormat('dd.MM.yyyy')
                                  .format(_selectedDate),
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(1970),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null &&
                                  pickedDate != _selectedDate) {
                                setState(() {
                                  _selectedDate = pickedDate;
                                });
                              }
                            },
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Saat',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (pickedTime != null &&
                                  pickedTime != _selectedTime) {
                                setState(() {
                                  _selectedTime = pickedTime;
                                });
                              }
                            },
                            controller: TextEditingController(
                              text:
                                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      thickness: 2,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _productNameControllers.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) {
                            _removeRow(index);
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerLeft,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.symmetric(vertical: 2.0),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: TextFormField(
                                        controller:
                                            _productNameControllers[index],
                                        focusNode: _focusNodes[index],
                                        decoration: const InputDecoration(
                                          labelText: 'Ürün Adı',
                                          border: OutlineInputBorder(),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller:
                                            _productQuantityControllers[index],
                                        decoration: const InputDecoration(
                                          labelText: 'Miktar',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller:
                                            _productPriceControllers[index],
                                        decoration: const InputDecoration(
                                          labelText: 'Fiyat',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Flexible(child: StatefulBuilder(
                                      builder: (context, setState) {
                                        return Row(
                                          children: [
                                            // Category Dropdown
                                            Flexible(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                isExpanded: true,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Kategori',
                                                  border: OutlineInputBorder(),
                                                ),
                                                value:
                                                    _selectedCategories[index]
                                                            .isEmpty
                                                        ? null
                                                        : _selectedCategories[
                                                            index],
                                                items: categories.keys
                                                    .map((String category) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: category,
                                                    child: Text(
                                                      category,
                                                      style: const TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  if (_selectedCategories[
                                                          index] !=
                                                      value) {
                                                    setState(() {
                                                      _selectedCategories[
                                                          index] = value ?? '';
                                                      _selectedSubcategories[
                                                          index] = '';
                                                    });
                                                  }
                                                },
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Subcategory Dropdown
                                            Flexible(
                                              child: DropdownButtonFormField<
                                                  String>(
                                                isExpanded: true,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Alt Kategori',
                                                  border: OutlineInputBorder(),
                                                ),
                                                value: _selectedSubcategories[
                                                            index]
                                                        .isEmpty
                                                    ? null
                                                    : _selectedSubcategories[
                                                        index],
                                                items: _getSubcategories(index)
                                                    .map((String subcategory) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: subcategory,
                                                    child: Text(
                                                      subcategory,
                                                      style: const TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedSubcategories[
                                                        index] = value ?? '';
                                                  });
                                                },
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRow,
        tooltip: 'Yeni Veri Ekle',
        heroTag: 'add_button',
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _marketNameController.dispose();
    for (var controller in _productNameControllers) {
      controller.dispose();
    }
    for (var controller in _productQuantityControllers) {
      controller.dispose();
    }
    for (var controller in _productPriceControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _categoryFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _subcategoryFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}

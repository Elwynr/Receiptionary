import 'package:flutter/material.dart';
import 'package:receiptionary/model/receipt.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptService {
  static late Isar isar;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ReceiptSchema], directory: dir.path);
    _isInitialized = true;
  }

  static Future<void> addReceipt(Receipt receipt) async {
    await isar.writeTxn(() async {
      await isar.receipts.put(receipt);
    });
  }

  static Future<List<Receipt>> getAllReceipts() async {
    return await isar.receipts.where().findAll();
  }

  static Future<List<Receipt>> getReceiptsWithLimit(int limit) async {
    // Tüm fişleri tarihe göre azalan sırada al (en yeni fişler en üstte)
    final receipts = await isar.receipts.where().findAll();
    receipts.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Belirtilen limit kadar fiş döndür
    return receipts.take(limit).toList();
  }

  static Future<Receipt?> getReceiptById(int id) async {
    return await isar.receipts.get(id);
  }

  static Future<void> updateReceipt(Receipt updatedReceipt) async {
    final existingReceipt = await isar.receipts.get(updatedReceipt.id);

    if (existingReceipt != null) {
      await isar.writeTxn(() async {
        updatedReceipt.id = existingReceipt.id;
        await isar.receipts.put(updatedReceipt);
      });
      print("Fiş güncellendi.");
    } else {
      print("Güncellenmek istenen fiş bulunamadı.");
    }
  }

  static Future<void> deleteReceipt(int id) async {
    await isar.writeTxn(() async {
      await isar.receipts.delete(id);
    });
  }

  static Future<double> getTotalProductsPriceBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final receipts = await isar.receipts
        .filter()
        .dateTimeBetween(startDate, endDate)
        .findAll();

    if (receipts.isEmpty) {
      return 0;
    }

    double totalPrice = 0;

    for (var receipt in receipts) {
      for (var product in receipt.products) {
        totalPrice += product.price * product.quantity;
      }
    }

    return totalPrice;
  }

  static Future<List<Product>> getAllProducts() async {
    final receipts = await getAllReceipts();

    List<Product> allProducts = [];

    for (var receipt in receipts) {
      for (var product in receipt.products) {
        allProducts.add(product);
      }
    }

    return allProducts;
  }

  static Future<Map<String, double>> getProductsByCategoryBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final receipts = await isar.receipts
        .filter()
        .dateTimeBetween(startDate, endDate)
        .findAll();

    Map<String, double> categoryTotals = {};

    for (var receipt in receipts) {
      for (var product in receipt.products) {
        categoryTotals.update(
          product.category,
          (value) => value + product.price * product.quantity,
          ifAbsent: () => product.price * product.quantity,
        );
      }
    }

    return categoryTotals;
  }

  // receipt_service.dart içine eklenecek yeni fonksiyon
  static Future<Map<DateTime, Map<String, double>>>
      getDailyCategoryTotalsBetweenDates(
          DateTime startDate, DateTime endDate) async {
    final receipts = await isar.receipts
        .filter()
        .dateTimeBetween(startDate, endDate)
        .findAll();

    Map<DateTime, Map<String, double>> dailyCategoryTotals = {};

    // Tarihleri normalize et (saat, dakika, saniye bilgilerini sıfırla)
    DateTime normalizeDate(DateTime date) {
      return DateTime(date.year, date.month, date.day);
    }

    for (var receipt in receipts) {
      final date = normalizeDate(receipt.dateTime);

      if (!dailyCategoryTotals.containsKey(date)) {
        dailyCategoryTotals[date] = {};
      }

      for (var product in receipt.products) {
        dailyCategoryTotals[date]!.update(
          product.category,
          (value) => value + (product.price * product.quantity),
          ifAbsent: () => product.price * product.quantity,
        );
      }
    }

    debugPrint(dailyCategoryTotals.toString());

    return dailyCategoryTotals;
  }

  static Future<Map<int, Map<String, double>>> getMonthlyCategoryTotals(
      {int? year}) async {
    final receipts = await getAllReceipts();
    Map<int, Map<String, double>> monthlyCategoryTotals = {};

    for (var receipt in receipts) {
      // Filter receipts by the selected year (if provided)
      if (year != null && receipt.dateTime.year != year) {
        continue;
      }

      final month = receipt.dateTime.month;

      if (!monthlyCategoryTotals.containsKey(month)) {
        monthlyCategoryTotals[month] = {};
      }

      for (var product in receipt.products) {
        monthlyCategoryTotals[month]!.update(
          product.category,
          (value) => value + (product.price * product.quantity),
          ifAbsent: () => product.price * product.quantity,
        );
      }
    }

    return monthlyCategoryTotals;
  }

  static Future<List<Product>> filterProducts({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? subcategory,
    String? productName,
    double? minPrice,
    double? maxPrice,
    int? minQuantity,
    int? maxQuantity,
  }) async {
    final receipts = await getAllReceipts();

    List<Product> filteredProducts = [];

    for (var receipt in receipts) {
      // Tarih filtresi
      if (startDate != null && receipt.dateTime.isBefore(startDate)) continue;
      if (endDate != null && receipt.dateTime.isAfter(endDate)) continue;

      for (var product in receipt.products) {
        // Kategori filtresi
        if (category != null && product.category != category) continue;

        // Alt kategori filtresi
        if (subcategory != null && product.subcategory != subcategory) continue;

        // Ürün adı filtresi
        if (productName != null &&
            !product.productName
                .toLowerCase()
                .contains(productName.toLowerCase())) continue;

        // Fiyat filtresi
        double totalPrice = product.price * product.quantity;
        if (minPrice != null && totalPrice < minPrice) continue;
        if (maxPrice != null && totalPrice > maxPrice) continue;

        // Miktar filtresi
        if (minQuantity != null && product.quantity < minQuantity) continue;
        if (maxQuantity != null && product.quantity > maxQuantity) continue;

        filteredProducts.add(product);
      }
    }

    return filteredProducts;
  }

  static Future<List<Product>> filterProductsWithMultipleCategories({
    DateTime? startDate,
    DateTime? endDate,
    List<Map<String, String>>? categorySubcategoryPairs,
    List<String>? productNames,
    double? minPrice,
    double? maxPrice,
    int? minQuantity,
    int? maxQuantity,
  }) async {
    final receipts = await getAllReceipts();
    List<Product> filteredProducts = [];

    for (var receipt in receipts) {
      // Tarih filtresi
      if (startDate != null && receipt.dateTime.isBefore(startDate)) continue;
      if (endDate != null && receipt.dateTime.isAfter(endDate)) continue;

      for (var product in receipt.products) {
        bool shouldAdd = true;

        // Kategori ve alt kategori filtresi
        if (categorySubcategoryPairs != null &&
            categorySubcategoryPairs.isNotEmpty) {
          bool matchesAnyCategory = false;
          for (var pair in categorySubcategoryPairs) {
            if (product.category == pair['category']) {
              if (pair['subcategory']!.isEmpty ||
                  product.subcategory == pair['subcategory']) {
                matchesAnyCategory = true;
                break;
              }
            }
          }
          if (!matchesAnyCategory) shouldAdd = false;
        }

        // Ürün adı filtresi
        if (productNames != null && productNames.isNotEmpty) {
          bool matchesAnyProduct = false;
          for (var name in productNames) {
            if (product.productName
                .toLowerCase()
                .contains(name.toLowerCase())) {
              matchesAnyProduct = true;
              break;
            }
          }
          if (!matchesAnyProduct) shouldAdd = false;
        }

        // Fiyat filtresi
        double totalPrice = product.price * product.quantity;
        if (minPrice != null && totalPrice < minPrice) shouldAdd = false;
        if (maxPrice != null && totalPrice > maxPrice) shouldAdd = false;

        // Miktar filtresi
        if (minQuantity != null && product.quantity < minQuantity) {
          shouldAdd = false;
        }
        if (maxQuantity != null && product.quantity > maxQuantity) {
          shouldAdd = false;
        }

        if (shouldAdd) {
          // Receipt bilgisini de ekleyelim
          filteredProducts.add(product);
        }
      }
    }

    return filteredProducts;
  }

  static Future<List<Product>> getLast100Products() async {
    // Tüm fişleri tarihe göre azalan sırada al (en yeni fişler en üstte)
    final receipts = await isar.receipts.where().findAll();
    receipts.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Tüm ürünleri bir listeye ekle
    List<Product> allProducts = [];
    for (var receipt in receipts) {
      for (var product in receipt.products) {
        allProducts.add(product);
      }
    }

    // En son 100 ürünü al ve yeniden eskiye sırala
    return allProducts.take(100).toList();
  }
}

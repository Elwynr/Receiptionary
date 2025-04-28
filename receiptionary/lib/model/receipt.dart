import 'package:isar/isar.dart';
part 'receipt.g.dart';

@Collection()
class Receipt {
  Id id = Isar.autoIncrement;
  late String market;
  late DateTime dateTime;
  late List<Product> products = [];
}

@Embedded()
class Product {
  late String productName;
  late int quantity;
  late double price;
  late String category;
  late String subcategory;
}




// @Collection()
// class Receipt {
//   Id id = Isar.autoIncrement;
//   late String market;
//   late DateTime dateTime;
//   late List<Product> products = [];

//   // Default constructor
//   Receipt();

//   // JSON'dan Receipt nesnesi oluşturma
//   factory Receipt.fromJson(Map<String, dynamic> json) {
//     String date = json['date'] as String? ?? ''; // Varsayılan değer
//     String time = json['time'] as String? ?? ''; // Varsayılan değer

//     List<String> dateParts = date.split('/');
//     List<String> timeParts = time.split(':');

//     int hour = int.parse(timeParts[0]);
//     int minute = int.parse(timeParts[1]);
//     int second = timeParts.length > 2
//         ? int.parse(timeParts[2])
//         : 0; // Saniye yoksa 0 kullan

//     DateTime dateTime = DateTime(
//       int.parse(dateParts[2]), // Yıl
//       int.parse(dateParts[1]), // Ay
//       int.parse(dateParts[0]), // Gün
//       hour, // Saat
//       minute, // Dakika
//       second, // Saniye
//     );

//     return Receipt()
//       ..market = json['market'] as String
//       ..dateTime = dateTime
//       ..products = (json['products'] as List)
//           .map((productJson) => Product.fromJson(productJson))
//           .toList();
//   }

//   // Receipt nesnesini JSON'a dönüştürme
//   Map<String, dynamic> toJson() {
//     return {
//       'market': market,
//       'date':
//           '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}', // "dd/MM/yyyy"
//       'time':
//           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}', // "HH:mm:ss"
//       'products': products.map((product) => product.toJson()).toList(),
//     };
//   }
// }

// @Embedded()
// class Product {
//   late String productName;
//   late int quantity;
//   late double price;
//   late String category;
//   late String subcategory;

//   // Default constructor
//   Product();

//   // JSON'dan Product nesnesi oluşturma
//   factory Product.fromJson(Map<String, dynamic> json) {
//     return Product()
//       ..productName = json['productName'] as String
//       ..quantity = json['quantity'] as int
//       ..price = (json['price'] as num).toDouble()
//       ..category = json['category'] as String
//       ..subcategory = json['subcategory'] as String;
//   }

//   // Product nesnesini JSON'a dönüştürme
//   Map<String, dynamic> toJson() {
//     return {
//       'productName': productName,
//       'quantity': quantity,
//       'price': price,
//       'category': category,
//       'subcategory': subcategory,
//     };
//   }
// }

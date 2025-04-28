import 'package:receiptionary/model/receipt.dart';
import 'package:receiptionary/service/receipt_service.dart';

import '../widgets/Bar Chart/bar_data.dart';

Future<BarData> getWeeklyData() async {
  // Tüm fişleri Isar'dan alıyoruz
  List<Receipt> receipts = await ReceiptService.getAllReceipts();

  // Haftanın her günü için fiyatları sıfırlıyoruz
  double monAmount = 0;
  double tueAmount = 0;
  double wedAmount = 0;
  double thuAmount = 0;
  double friAmount = 0;
  double satAmount = 0;
  double sunAmount = 0;

  // Fişleri günlere göre işliyoruz ve fiyatları topluyoruz
  for (var receipt in receipts) {
    for (var product in receipt.products) {
      switch (receipt.dateTime.weekday) {
        case DateTime.monday:
          monAmount += product.price * product.quantity;
          break;
        case DateTime.tuesday:
          tueAmount += product.price * product.quantity;
          break;
        case DateTime.wednesday:
          wedAmount += product.price * product.quantity;
          break;
        case DateTime.thursday:
          thuAmount += product.price * product.quantity;
          break;
        case DateTime.friday:
          friAmount += product.price * product.quantity;
          break;
        case DateTime.saturday:
          satAmount += product.price * product.quantity;
          break;
        case DateTime.sunday:
          sunAmount += product.price * product.quantity;
          break;
      }
    }
  }

  // BarData'yı oluşturuyoruz ve verileri başlatıyoruz
  return BarData(
    monAmount: monAmount,
    tueAmount: tueAmount,
    wedAmount: wedAmount,
    thuAmount: thuAmount,
    friAmount: friAmount,
    satAmount: satAmount,
    sunAmount: sunAmount,
  );
}

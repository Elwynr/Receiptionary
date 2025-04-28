import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../model/receipt.dart';
import '../model/story.dart';
import '../service/receipt_service.dart';
import '../utils/stories.dart';
import 'image_page.dart';
import 'story_page.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigateBottomBar;

  const HomePage({super.key, required this.onNavigateBottomBar});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String amount = "0";
  late DateTime _startDate;
  late DateTime _endDate;
  late List<dynamic> jsonData;
  late List<StoryOwner> storyOwners;

  List<Receipt> receipts = [];

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
    _getAmount();
    _getStories();
  }

  void _getStories() {
    List<dynamic> jsonData = json.decode(jsonString);
    storyOwners = jsonData.map((json) => StoryOwner.fromJson(json)).toList();
  }

  Future<void> _getAmount() async {
    DateTime now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    double totalPrice = await ReceiptService.getTotalProductsPriceBetweenDates(
        _startDate, _endDate);
    totalPrice *= -1;
    setState(() {
      amount = totalPrice == 0 ? "0" : totalPrice.toStringAsFixed(2);
    });
  }

  Future<void> _fetchReceipts() async {
    List<Receipt> allReceipts = await ReceiptService.getAllReceipts();
    allReceipts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    setState(() {
      receipts = allReceipts.take(5).toList();
    });
  }

  void selectInputOption() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        );
      },
    );
  }

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePage(imageFile: File(returnedImage.path)),
        ),
      );
    }
  }

  Future _pickImageFromCamera() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePage(imageFile: File(returnedImage.path)),
        ),
      );
    }
  }

  void _openStories(List<StoryOwner> storyOwners, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryPage(
          storyOwners: storyOwners,
          startIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height;
    double containerWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height /
                8, // Original height for circles
            child: storyOwners.isEmpty
                ? const Center(
                    child: Text(
                      "No stories available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: storyOwners.length,
                    itemBuilder: (context, index) {
                      final owner = storyOwners[index];
                      return GestureDetector(
                        onTap: () {
                          _openStories(storyOwners, index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width:
                              MediaQuery.of(context).size.height * 0.125 / 1.5,
                          height:
                              MediaQuery.of(context).size.height * 0.125 / 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFBCF0B4), width: 2),
                            image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                  owner.profileImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            height: containerHeight / 6,
            width: double.infinity,
            decoration: BoxDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 5,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$amount₺",
                      style: const TextStyle(
                        fontSize: 80,
                        letterSpacing: -2,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -15), // Yukarı kaydırma miktarı
                  child: Text(
                    "${DateFormat('MMMM', 'tr_TR').format(DateTime.now())} ayındaki harcamanız",
                    style: const TextStyle(
                      color: Color.fromARGB(255, 165, 168, 167),
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: containerHeight / 20,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Son alışverişleriniz...",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      widget.onNavigateBottomBar(3);
                    },
                    child: Text(
                      "Tümünü Gör",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: receipts.length,
                itemBuilder: (context, index) {
                  Receipt receipt = receipts[index];
                  return GestureDetector(
                    onTap: () => print('Receipt $index clicked'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Market: ${receipt.market}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tarih: ${DateFormat('dd.MM.yyyy - HH:mm').format(receipt.dateTime)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: receipt.products.length + 1,
                                      itemBuilder: (context, productIndex) {
                                        if (productIndex <
                                            receipt.products.length) {
                                          final product =
                                              receipt.products[productIndex];
                                          return SizedBox(
                                            height: 25,
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.all(0),
                                              title: Text(
                                                product.productName,
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "${product.quantity} x ${product.price.toStringAsFixed(2)} ₺",
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            height: 25,
                                            color: Colors.transparent,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const Divider(thickness: 1),
                                  Container(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "Toplam: ${receipt.products.fold<double>(0, (sum, item) => sum + item.price * item.quantity).toStringAsFixed(2)} ₺",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/manuel_data_input_page');
            },
            mini: true,
            heroTag: 'manual_input',
            child: const Icon(Icons.create),
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            onPressed: selectInputOption,
            heroTag: 'camera_input',
            child: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
    );
  }
}
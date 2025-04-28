import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'manuel_data_input_page.dart';
import 'dart:developer';

class ImagePage extends StatefulWidget {
  final File imageFile;

  const ImagePage({super.key, required this.imageFile});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  List<Point> points = [];
  int? imageWidth;
  int? imageHeight;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<String> _getSelectedEngine() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedEngine') ?? 'Google ML Kit';
  }

  Future<void> _sendDataForGeminiImageInput() async {
    setState(() {
      isLoading = true;
    });

    try {
      final bytes = await widget.imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      List<Point> newPointList = pointSorter(points);

      List<Map<String, int>> pointsData =
          newPointList.map((point) => {'x': point.x, 'y': point.y}).toList();

      final requestBody = jsonEncode({
        'image': base64Image,
        'points': pointsData,
      });

      // Send the POST request
      final response = await http.post(
        Uri.parse(
            'http://31.59.129.98:8000/api/v3/scan'), //http://31.59.129.98:8000/api/v1/scan
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        log(responseBody);
        if (responseBody.isEmpty) {
          print('Error: Response body is empty');
          return;
        }

        try {
          final jsonResponseMap = jsonDecode(responseBody);
          log('$jsonResponseMap');

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ManuelDataInputPage(jsonResponseMap: jsonResponseMap),
              ),
            );
          }
        } catch (e) {
          print('Error parsing response body: $e');
        }
      } else {
        print('Error sending data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _sendData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final bytes = await widget.imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      List<Point> newPointList = pointSorter(points);

      List<Map<String, int>> pointsData =
          newPointList.map((point) => {'x': point.x, 'y': point.y}).toList();

      final requestBody = jsonEncode({
        'image': base64Image,
        'points': pointsData,
      });

      // Send the POST request
      final response = await http.post(
        Uri.parse(
            'http://31.59.129.98:8000/api/v1/scan'), //http://31.59.129.98:8000/api/v1/scan
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        log(responseBody);
        if (responseBody.isEmpty) {
          print('Error: Response body is empty');
          return;
        }

        try {
          final jsonResponseMap = jsonDecode(responseBody);
          log('$jsonResponseMap');

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ManuelDataInputPage(jsonResponseMap: jsonResponseMap),
              ),
            );
          }
        } catch (e) {
          print('Error parsing response body: $e');
        }
      } else {
        print('Error sending data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _sendDataAsText() async {
    setState(() {
      isLoading = true;
    });

    try {
      final image = await widget.imageFile;
      final inputImage = InputImage.fromFile(image);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String rectext = recognizedText.text;

      List<Point> newPointList = pointSorter(points);
      List<Map<String, int>> pointsData =
          newPointList.map((point) => {'x': point.x, 'y': point.y}).toList();

      final requestBody = jsonEncode({
        'receiptContent': rectext,
        'points': pointsData,
      });

      // Send the POST request
      final response = await http.post(
        Uri.parse('http://31.59.129.98:8000/api/v2/scan'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print(responseBody);
        if (responseBody.isEmpty) {
          print('Error: Response body is empty');
          return;
        }

        try {
          final jsonResponseMap = jsonDecode(responseBody);
          print('Parsed JSON Response: $jsonResponseMap');
          log('$jsonResponseMap');

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ManuelDataInputPage(jsonResponseMap: jsonResponseMap),
              ),
            );
          }
        } catch (e) {
          print('Error parsing response body: $e');
        }
      } else {
        print('Error sending data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadImageDimensions() async {
    final image = img.decodeImage(await widget.imageFile.readAsBytes());
    if (image != null) {
      setState(() {
        imageWidth = image.width;
        imageHeight = image.height;
      });
    }
  }

  void _addPoint(Point point) {
    if (points.length < 4) {
      setState(() {
        points.add(point);
      });
    }
  }

  void _resetPoints() {
    setState(() {
      points.clear();
    });
  }

  List<Point> pointSorter(List<Point> points) {
    List<Point> newPointList = [];

    double avgX =
        points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
    double avgY =
        points.map((p) => p.y).reduce((a, b) => a + b) / points.length;

    // Initialize placeholders for each point
    Point? topLeft, topRight, bottomRight, bottomLeft;

    // Classify points into quadrants
    for (var point in points) {
      if (point.x < avgX && point.y < avgY) {
        // Top-left
        topLeft = point;
      } else if (point.x >= avgX && point.y < avgY) {
        // Top-right
        topRight = point;
      } else if (point.x >= avgX && point.y >= avgY) {
        // Bottom-right
        bottomRight = point;
      } else if (point.x < avgX && point.y >= avgY) {
        // Bottom-left
        bottomLeft = point;
      }
    }

    // Ensure all points are assigned
    if (topLeft != null &&
        topRight != null &&
        bottomRight != null &&
        bottomLeft != null) {
      newPointList = [topLeft, topRight, bottomRight, bottomLeft];
      return newPointList;
    } else {
      print("Error: Points could not be properly classified into quadrants.");
    }
    return newPointList;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Köşe Seçimi'),
      ),
      body: imageWidth != null && imageHeight != null
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Image.file(
                      widget.imageFile,
                      fit: BoxFit.contain, // Resmi ekran boyutuna sığdır
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                    GestureDetector(
                      onTapDown: (details) {
                        // Ekrandaki görüntü widget'ının RenderBox'ını alın
                        final RenderBox renderBox =
                            context.findRenderObject() as RenderBox;

                        // Widget'ın ekran üzerindeki konumunu ve boyutunu alın
                        final Offset widgetPosition =
                            renderBox.localToGlobal(Offset.zero);
                        final Size widgetSize = renderBox.size;

                        // Görüntü ve widget arasındaki ölçek faktörünü bulun
                        double scaleX = widgetSize.width / imageWidth!;
                        double scaleY = widgetSize.height / imageHeight!;

                        // Görüntüyü ekrana ortalama (BoxFit.contain'in yan etkileri)
                        double scale = scaleX < scaleY ? scaleX : scaleY;

                        // Rendered görüntü boyutları
                        double renderedWidth = imageWidth! * scale;
                        double renderedHeight = imageHeight! * scale;

                        // Görüntüyü ortalamak için yatay ve dikey ofset
                        double offsetX = (widgetSize.width - renderedWidth) / 2;
                        double offsetY =
                            (widgetSize.height - renderedHeight) / 2;

                        // Tıklama koordinatlarını widget içindeki konuma dönüştür
                        double tapX = details.localPosition.dx - offsetX;
                        double tapY = details.localPosition.dy - offsetY;

                        // Eğer tıklama görüntü içinde değilse, ekleme yapma
                        if (tapX < 0 ||
                            tapX > renderedWidth ||
                            tapY < 0 ||
                            tapY > renderedHeight) {
                          return;
                        }

                        // Görüntü boyutlarına normalleştir
                        double normalizedX =
                            (tapX / scale).clamp(0, imageWidth! - 1);
                        double normalizedY =
                            (tapY / scale).clamp(0, imageHeight! - 1);

                        // Noktayı ekle
                        _addPoint(
                            Point(normalizedX.round(), normalizedY.round()));
                      },
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: CustomPaint(
                          painter: PointsPainter(points, imageWidth!,
                              imageHeight!), // Noktaları ve dörtgeni çizer
                          child: Container(),
                        ),
                      ),
                    ),
                    if (isLoading)
                      Container(
                        color:
                            Colors.black.withOpacity(0.5), // Arka planı karart
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                );
              },
            )
          : const Center(
              child:
                  CircularProgressIndicator()), // Resim yüklenirken bir yükleme göstergesi
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  _resetPoints, // Kullanıcı sıfırla butonuna bastığında noktaları temizle
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (points.length == 4) {
                  try {
                    setState(() {
                      isLoading = true;
                    });

                    String selectedEngine = await _getSelectedEngine();

                    if (selectedEngine == 'Google ML Kit') {
                      await _sendDataAsText();
                    } else if (selectedEngine == 'Gemini Image Input') {
                      await _sendDataForGeminiImageInput();
                    } else {
                      await _sendData();
                    }
                  } catch (e) {
                    _showErrorDialog('İşlem sırasında bir hata oluştu: $e');
                  } finally {
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  }
                } else {
                  _showErrorDialog('Lütfen 4 nokta seçin.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PointsPainter extends CustomPainter {
  final List<Point> points;
  final int imageWidth;
  final int imageHeight;

  PointsPainter(this.points, this.imageWidth, this.imageHeight);

  List<Point> pointSorter(List<Point> points) {
    List<Point> newPointList = [];

    double avgX =
        points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
    double avgY =
        points.map((p) => p.y).reduce((a, b) => a + b) / points.length;

    // Initialize placeholders for each point
    Point? topLeft, topRight, bottomRight, bottomLeft;

    // Classify points into quadrants
    for (var point in points) {
      if (point.x < avgX && point.y < avgY) {
        // Top-left
        topLeft = point;
      } else if (point.x >= avgX && point.y < avgY) {
        // Top-right
        topRight = point;
      } else if (point.x >= avgX && point.y >= avgY) {
        // Bottom-right
        bottomRight = point;
      } else if (point.x < avgX && point.y >= avgY) {
        // Bottom-left
        bottomLeft = point;
      }
    }

    // Ensure all points are assigned
    if (topLeft != null &&
        topRight != null &&
        bottomRight != null &&
        bottomLeft != null) {
      newPointList = [topLeft, topRight, bottomRight, bottomLeft];
      return newPointList;
    } else {
      print("Error: Points could not be properly classified into quadrants.");
    }
    return newPointList;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.4) // Şeffaf yeşil
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    // Görüntünün ölçekleme faktörünü hesapla
    double scaleX = size.width / imageWidth;
    double scaleY = size.height / imageHeight;
    double scale = scaleX < scaleY ? scaleX : scaleY;

    double offsetX = (size.width - imageWidth * scale) / 2;
    double offsetY = (size.height - imageHeight * scale) / 2;

    List<Point> newPointList;
    if (points.length == 4) {
      newPointList = pointSorter(points);
    } else {
      newPointList = points;
    }

    List<Offset> normalizedPoints = newPointList
        .map((point) => Offset(
              point.x * scale + offsetX,
              point.y * scale + offsetY,
            ))
        .toList();

    if (normalizedPoints.length == 4) {
      Path path = Path()..addPolygon(normalizedPoints, true);

      canvas.drawPath(path, paint); // Dörtgen içini doldur
      canvas.drawPath(path, borderPaint); // Kenar çizgisi
    }

    for (var point in normalizedPoints) {
      canvas.drawCircle(point, 6, dotPaint); // Noktalar içi dolu
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  @override
  String toString() {
    return '($x, $y)';
  }
}

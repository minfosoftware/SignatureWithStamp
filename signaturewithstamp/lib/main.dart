import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignaturePad(),
    );
  }
}

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  _SignaturePadState createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  // Background image
  final String backgroundImagePath = 'assets/company_stamp.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature With Stamp'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 100,),
          const Divider(),
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              children: [
                // Background image
                Center(
                  child: Image.asset(
                    backgroundImagePath,
                    fit: BoxFit.cover,
                  ),
                ),
                // Signature pad
                Center(
                  child: Signature(
                    controller: _controller,
                    height: 300,
                    width: double.infinity,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          const Divider()
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                _controller.clear(); // Clear signature
              },
              child: const Text('Clear Signature'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveSignature(); // Save signature
              },
              child: const Text('Save Signature'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSignature() async {
    try {
      // Capture signature as image bytes
      final Uint8List? signatureBytes = await _controller.toPngBytes();

      // Load background image bytes
      final ByteData data = await rootBundle.load(backgroundImagePath);
      final Uint8List backgroundBytes = data.buffer.asUint8List();

      // Convert bytes to images
      final ui.Image background = await decodeImageFromList(backgroundBytes);
      final ui.Image signature = await decodeImageFromList(signatureBytes!);

      // Create a new image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw background image
      final Paint backgroundPaint = Paint()..isAntiAlias = true;
      canvas.drawImage(background, Offset.zero, backgroundPaint);

      // Calculate position to center signature within stamp area
      final double centerX = (background.width - signature.width) / 2;
      final double centerY = (background.height - signature.height) / 2;

      // Draw signature on background
      canvas.drawImage(signature, Offset(centerX, centerY), Paint());

      // Convert picture to image
      final ui.Image compositeImage = await recorder.endRecording().toImage(
        background.width,
        background.height,
      );

      // Convert image to PNG bytes
      final ByteData? compositeByteData = await compositeImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List compositeBytes = compositeByteData!.buffer.asUint8List();

      // Save image to file (you can replace this with your preferred method)
      final Directory directory = await getTemporaryDirectory();
      final File file =
      File('${directory.path}/signature_with_background.png');
      await file.writeAsBytes(compositeBytes);

      print('Signature saved to: ${file.path}');
    } catch (e) {
      print('Error saving signature: $e');
    }
  }
}

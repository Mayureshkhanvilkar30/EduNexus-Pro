import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// Nayi screen ka import
import 'scan_result_screen.dart';

class OCRScannerScreen extends StatefulWidget {
  const OCRScannerScreen({super.key});

  @override
  State<OCRScannerScreen> createState() => _OCRScannerScreenState();
}

class _OCRScannerScreenState extends State<OCRScannerScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isScanning = false; // Loading indicator ke liye
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  Future<void> _scanText() async {
    if (_controller == null || !_controller!.value.isInitialized || _isScanning) return;

    setState(() => _isScanning = true);

    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      if (mounted) {
        // Dialog ki jagah ab hum Edit Screen par jayenge
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(scannedText: recognizedText.text),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isScanning = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Notes")),
      body: _isInitialized
          ? Stack(
        children: [
          CameraPreview(_controller!),
          // Scan hone ke waqt loading dikhane ke liye
          if (_isScanning)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF2D5AF0),
                onPressed: _scanText,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
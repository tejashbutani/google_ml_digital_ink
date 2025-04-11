import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as ml_kit;
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Googe ML',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  List<Offset> points = [];
  bool isDrawing = false;
  List<List<Offset>> strokes = [];
  bool isTextMode = false;
  late ml_kit.DigitalInkRecognizer _digitalInkRecognizer;
  late ml_kit.DigitalInkRecognizerModelManager _modelManager;
  Timer? _recognitionTimer;
  static const int recognitionDelay = 300; // 1 second delay
  String? recognizedText;
  Offset? textPosition;
  double? textFontSize;

  @override
  void initState() {
    super.initState();
    _initDigitalInkRecognizer();
  }

  Future<void> _initDigitalInkRecognizer() async {
    _digitalInkRecognizer = ml_kit.DigitalInkRecognizer(languageCode: 'en');
    _modelManager = ml_kit.DigitalInkRecognizerModelManager();

    // Download the model if not already downloaded
    final bool isDownloaded = await _modelManager.isModelDownloaded('en');
    if (!isDownloaded) {
      await _modelManager.downloadModel('en');
    }
  }

  @override
  void dispose() {
    _digitalInkRecognizer.close();
    _recognitionTimer?.cancel();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      isDrawing = true;
      points = [details.localPosition];
      strokes.add(points);
      // Cancel any pending recognition
      _recognitionTimer?.cancel();
      // Clear previous recognized text
      recognizedText = null;
      textPosition = null;
      textFontSize = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (isDrawing) {
      setState(() {
        points.add(details.localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      isDrawing = false;
    });

    if (isTextMode) {
      // Calculate the average position and height of all points for text placement
      if (points.isNotEmpty) {
        double avgX = points.map((p) => p.dx).reduce((a, b) => a + b) / points.length;
        double avgY = points.map((p) => p.dy).reduce((a, b) => a + b) / points.length;
        textPosition = Offset(avgX, avgY);

        // Calculate the height of the stroke
        double minY = points.map((p) => p.dy).reduce(math.min);
        double maxY = points.map((p) => p.dy).reduce(math.max);
        double strokeHeight = maxY - minY;

        // Set font size proportional to stroke height
        // Using a multiplier to make the text slightly larger than the stroke
        textFontSize = strokeHeight * 1.5;
      }

      // Cancel any existing timer
      _recognitionTimer?.cancel();
      // Start a new timer
      _recognitionTimer = Timer(const Duration(milliseconds: recognitionDelay), () {
        _recognizeText();
      });
    }
  }

  Future<void> _recognizeText() async {
    try {
      final ink = ml_kit.Ink();
      final List<ml_kit.Stroke> mlStrokes = [];

      // Convert all strokes to ML Kit format
      for (var stroke in strokes) {
        final mlStroke = ml_kit.Stroke();
        mlStroke.points = stroke
            .map((point) => ml_kit.StrokePoint(
                  x: point.dx,
                  y: point.dy,
                  t: DateTime.now().millisecondsSinceEpoch,
                ))
            .toList();
        mlStrokes.add(mlStroke);
      }

      ink.strokes = mlStrokes;

      final candidates = await _digitalInkRecognizer.recognize(ink);

      if (candidates.isNotEmpty) {
        setState(() {
          recognizedText = candidates.first.text;
          // Clear the strokes after recognition
          strokes.clear();
          points = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _clearCanvas() {
    setState(() {
      strokes.clear();
      points = [];
      recognizedText = null;
      textPosition = null;
      textFontSize = null;
      // Cancel any pending recognition
      _recognitionTimer?.cancel();
    });
  }

  void _togglePenMode(bool t) {
    setState(() {
      isTextMode = t;
      // Cancel any pending recognition when switching modes
      _recognitionTimer?.cancel();
      recognizedText = null;
      textPosition = null;
      textFontSize = null;
    });
    _clearCanvas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google ML Digital Ink Recognition'),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: DrawingPainter(strokes, isTextMode),
              size: Size.infinite,
            ),
          ),
          if (recognizedText != null && textPosition != null)
            Positioned(
              left: textPosition!.dx,
              top: textPosition!.dy,
              child: Text(
                recognizedText!,
                style: TextStyle(
                  fontSize: textFontSize ?? 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _togglePenMode(true),
            tooltip: 'Text Mode',
            backgroundColor: isTextMode ? Colors.blue : Colors.black87,
            child: const Icon(Icons.abc, color: Colors.white),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () => _togglePenMode(false),
            tooltip: 'Normal Mode',
            backgroundColor: isTextMode ? Colors.black87 : Colors.blue,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _clearCanvas,
            tooltip: 'Clear Canvas',
            backgroundColor: Colors.black87,
            child: const Icon(Icons.delete_forever, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final bool isTextMode;

  DrawingPainter(this.strokes, this.isTextMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isTextMode ? Colors.blue : Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (var stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

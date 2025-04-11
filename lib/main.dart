import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as ml_kit;

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
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      isDrawing = true;
      points = [details.localPosition];
      strokes.add(points);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (isDrawing) {
      setState(() {
        points.add(details.localPosition);
      });
    }
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    setState(() {
      isDrawing = false;
    });

    if (isTextMode) {
      await _recognizeText();
    }
  }

  Future<void> _recognizeText() async {
    try {
      final ink = ml_kit.Ink();
      final stroke = ml_kit.Stroke();

      // Convert our points to StrokePoints
      stroke.points = points
          .map((point) => ml_kit.StrokePoint(
                x: point.dx,
                y: point.dy,
                t: DateTime.now().millisecondsSinceEpoch,
              ))
          .toList();

      ink.strokes = [stroke];

      final candidates = await _digitalInkRecognizer.recognize(ink);

      if (candidates.isNotEmpty) {
        final recognizedText = candidates.first.text;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recognized: $recognizedText')),
          );
        }
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
    });
  }

  void _togglePenMode() {
    setState(() {
      isTextMode = !isTextMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Canvas'),
      ),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: DrawingPainter(strokes, isTextMode),
          size: Size.infinite,
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _togglePenMode,
            tooltip: isTextMode ? 'Switch to Drawing' : 'Switch to Text',
            child: Icon(isTextMode ? Icons.edit : Icons.abc),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _clearCanvas,
            tooltip: 'Clear Canvas',
            child: const Icon(Icons.delete_forever),
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

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final Function(File) onCropComplete;

  const ImageCropperWidget({
    Key? key,
    required this.imageFile,
    required this.onCropComplete,
  }) : super(key: key);

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  late ui.Image _image;
  bool _isImageLoaded = false;
  Offset _startPoint = Offset.zero;
  Offset _endPoint = Offset.zero;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _isImageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImageLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _cropImage,
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: ImageCropperPainter(
              image: _image,
              startPoint: _startPoint,
              endPoint: _endPoint,
              isCropping: _isCropping,
            ),
            size: Size(_image.width.toDouble(), _image.height.toDouble()),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _startPoint = details.localPosition;
      _endPoint = details.localPosition;
      _isCropping = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _endPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isCropping = false;
    });
  }

  void _cropImage() {
    // For now, just return the original image
    // In a real implementation, you would crop the image here
    widget.onCropComplete(widget.imageFile);
    Navigator.of(context).pop();
  }
}

class ImageCropperPainter extends CustomPainter {
  final ui.Image image;
  final Offset startPoint;
  final Offset endPoint;
  final bool isCropping;

  ImageCropperPainter({
    required this.image,
    required this.startPoint,
    required this.endPoint,
    required this.isCropping,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);

    // Draw crop rectangle
    if (isCropping) {
      final cropRect = Rect.fromPoints(startPoint, endPoint);
      final cropPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawRect(cropRect, cropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

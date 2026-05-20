import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

class ImageCropScreen extends StatefulWidget {
  final File imageFile;
  const ImageCropScreen({super.key, required this.imageFile});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen>
    with SingleTickerProviderStateMixin {
  ui.Image? _uiImage;
  Size _imageSize = Size.zero;

  // Crop rect in image-pixel coordinates
  late Rect _cropRect;
  bool _imageLoaded = false;

  // Rotation in degrees: 0, 90, 180, 270
  int _rotationDeg = 0;

  _DragHandle? _activeHandle;
  static const double _handleSize = 26.0;
  static const double _minCropSize = 60.0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _uiImage = frame.image;
      _imageSize =
          Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      _cropRect =
          Rect.fromLTWH(0, 0, _imageSize.width, _imageSize.height);
      _imageLoaded = true;
    });
    _fadeController.forward();
  }

  // ── Effective image size after rotation ─────────────────────────────────
  Size get _effectiveSize {
    if (_rotationDeg == 90 || _rotationDeg == 270) {
      return Size(_imageSize.height, _imageSize.width);
    }
    return _imageSize;
  }

  // ── Rotate actions ───────────────────────────────────────────────────────
  void _rotateLeft() {
    setState(() {
      _rotationDeg = (_rotationDeg - 90 + 360) % 360;
      _resetCrop();
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationDeg = (_rotationDeg + 90) % 360;
      _resetCrop();
    });
  }

  void _resetCrop() {
    final s = _effectiveSize;
    _cropRect = Rect.fromLTWH(0, 0, s.width, s.height);
  }

  // ── Coordinate helpers ───────────────────────────────────────────────────
  Rect _getDisplayRect(BoxConstraints constraints) {
    final widgetW = constraints.maxWidth;
    final widgetH = constraints.maxHeight;
    final eff = _effectiveSize;
    final imgAspect = eff.width / eff.height;
    final widgetAspect = widgetW / widgetH;
    double dW, dH;
    if (imgAspect > widgetAspect) {
      dW = widgetW;
      dH = widgetW / imgAspect;
    } else {
      dH = widgetH;
      dW = widgetH * imgAspect;
    }
    final left = (widgetW - dW) / 2;
    final top = (widgetH - dH) / 2;
    return Rect.fromLTWH(left, top, dW, dH);
  }

  Rect _toDisplayRect(Rect imageRect, Rect displayRect) {
    final eff = _effectiveSize;
    final scaleX = displayRect.width / eff.width;
    final scaleY = displayRect.height / eff.height;
    return Rect.fromLTRB(
      displayRect.left + imageRect.left * scaleX,
      displayRect.top + imageRect.top * scaleY,
      displayRect.left + imageRect.right * scaleX,
      displayRect.top + imageRect.bottom * scaleY,
    );
  }

  // ── Hit test & pan ───────────────────────────────────────────────────────
  _DragHandle? _hitTest(Offset pt, Rect displayCropRect) {
    const hs = _handleSize / 2;
    final corners = {
      _DragHandle.topLeft: displayCropRect.topLeft,
      _DragHandle.topRight: displayCropRect.topRight,
      _DragHandle.bottomLeft: displayCropRect.bottomLeft,
      _DragHandle.bottomRight: displayCropRect.bottomRight,
    };
    for (final e in corners.entries) {
      if ((pt - e.value).distance <= hs + 8) return e.key;
    }
    if ((pt - Offset(displayCropRect.center.dx, displayCropRect.top))
            .distance <=
        hs + 8) {
      return _DragHandle.topMid;
    }
    if ((pt - Offset(displayCropRect.center.dx, displayCropRect.bottom))
            .distance <=
        hs + 8) {
      return _DragHandle.bottomMid;
    }
    if ((pt - Offset(displayCropRect.left, displayCropRect.center.dy))
            .distance <=
        hs + 8) {
      return _DragHandle.leftMid;
    }
    if ((pt - Offset(displayCropRect.right, displayCropRect.center.dy))
            .distance <=
        hs + 8) {
      return _DragHandle.rightMid;
    }
    if (displayCropRect.contains(pt)) return _DragHandle.move;
    return null;
  }

  void _onPanStart(DragStartDetails d, Rect displayRect) {
    final dispCrop = _toDisplayRect(_cropRect, displayRect);
    _activeHandle = _hitTest(d.localPosition, dispCrop);
  }

  void _onPanUpdate(DragUpdateDetails d, Rect displayRect) {
    if (_activeHandle == null) return;
    final eff = _effectiveSize;
    final scaleX = eff.width / displayRect.width;
    final scaleY = eff.height / displayRect.height;
    final dx = d.delta.dx * scaleX;
    final dy = d.delta.dy * scaleY;

    setState(() {
      double l = _cropRect.left,
          t = _cropRect.top,
          r = _cropRect.right,
          b = _cropRect.bottom;

      switch (_activeHandle!) {
        case _DragHandle.topLeft:
          l = (l + dx).clamp(0, r - _minCropSize);
          t = (t + dy).clamp(0, b - _minCropSize);
          break;
        case _DragHandle.topRight:
          r = (r + dx).clamp(l + _minCropSize, eff.width);
          t = (t + dy).clamp(0, b - _minCropSize);
          break;
        case _DragHandle.bottomLeft:
          l = (l + dx).clamp(0, r - _minCropSize);
          b = (b + dy).clamp(t + _minCropSize, eff.height);
          break;
        case _DragHandle.bottomRight:
          r = (r + dx).clamp(l + _minCropSize, eff.width);
          b = (b + dy).clamp(t + _minCropSize, eff.height);
          break;
        case _DragHandle.topMid:
          t = (t + dy).clamp(0, b - _minCropSize);
          break;
        case _DragHandle.bottomMid:
          b = (b + dy).clamp(t + _minCropSize, eff.height);
          break;
        case _DragHandle.leftMid:
          l = (l + dx).clamp(0, r - _minCropSize);
          break;
        case _DragHandle.rightMid:
          r = (r + dx).clamp(l + _minCropSize, eff.width);
          break;
        case _DragHandle.move:
          final w = r - l;
          final h = b - t;
          l = (l + dx).clamp(0, eff.width - w);
          t = (t + dy).clamp(0, eff.height - h);
          r = l + w;
          b = t + h;
          break;
      }
      _cropRect = Rect.fromLTRB(l, t, r, b);
    });
  }

  void _onPanEnd(DragEndDetails _) => _activeHandle = null;

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Crop & Rotate',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        actions: [
          TextButton.icon(
            onPressed: _imageLoaded ? _confirmCrop : null,
            icon:
                const Icon(Icons.check_rounded, color: Colors.blueAccent),
            label: Text(
              'Use Photo',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Image + crop overlay ─────────────────────────────────────
          Expanded(
            child: _imageLoaded
                ? FadeTransition(
                    opacity: _fadeAnim,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final displayRect = _getDisplayRect(constraints);
                        final dispCrop =
                            _toDisplayRect(_cropRect, displayRect);

                        return GestureDetector(
                          onPanStart: (d) =>
                              _onPanStart(d, displayRect),
                          onPanUpdate: (d) =>
                              _onPanUpdate(d, displayRect),
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            painter: _CropPainter(
                              uiImage: _uiImage!,
                              displayRect: displayRect,
                              cropRect: dispCrop,
                              rotationDeg: _rotationDeg,
                              handleSize: _handleSize,
                            ),
                            size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight),
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                        color: Colors.blueAccent),
                  ),
          ),

          // ── Bottom toolbar ───────────────────────────────────────────
          Container(
            color: const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reset crop
                _BottomAction(
                  icon: Icons.crop_free,
                  label: 'Reset',
                  onTap: _imageLoaded
                      ? () => setState(_resetCrop)
                      : null,
                ),

                // Rotate left
                _BottomAction(
                  icon: Icons.rotate_left,
                  label: 'Rotate L',
                  onTap: _imageLoaded ? _rotateLeft : null,
                  highlight: true,
                ),

                // Rotation badge
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    '$_rotationDeg°',
                    key: ValueKey(_rotationDeg),
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Rotate right
                _BottomAction(
                  icon: Icons.rotate_right,
                  label: 'Rotate R',
                  onTap: _imageLoaded ? _rotateRight : null,
                  highlight: true,
                ),

                // Flip (horizontal)
                _BottomAction(
                  icon: Icons.flip,
                  label: 'Flip',
                  onTap: _imageLoaded ? _flip : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _flip() async {
    // Decode, flip, re-encode, reload
    final bytes = _flippedBytes ?? await widget.imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return;
    final flipped = img.flipHorizontal(original);
    final flippedBytes =
        Uint8List.fromList(img.encodeJpg(flipped, quality: 95));

    final codec = await ui.instantiateImageCodec(flippedBytes);
    final frame = await codec.getNextFrame();

    // Guard: widget may have been disposed during the awaits above
    if (!mounted) return;

    setState(() {
      _uiImage = frame.image;
      _imageSize =
          Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      _rotationDeg = 0;
      _flippedBytes = flippedBytes; // keep for confirm
      _resetCrop();
    });
  }

  Uint8List? _flippedBytes;

  // ── Confirm: rotate + flip + crop ────────────────────────────────────────
  Future<void> _confirmCrop() async {
    try {
      final bytes = _flippedBytes ?? await widget.imageFile.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      if (_rotationDeg != 0) {
        original = img.copyRotate(original, angle: _rotationDeg);
      }

      // Clamp the crop rect to the actual (possibly rotated) pixel bounds to
      // avoid out-of-bounds crashes inside the `image` package.
      final x = _cropRect.left.round().clamp(0, original.width - 1);
      final y = _cropRect.top.round().clamp(0, original.height - 1);
      final w = _cropRect.width.round().clamp(1, original.width - x);
      final h = _cropRect.height.round().clamp(1, original.height - y);

      final cropped = img.copyCrop(
        original,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      final croppedBytes =
          Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
      final dir = widget.imageFile.parent;
      final outPath =
          '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(croppedBytes);

      if (mounted) Navigator.pop(context, outFile);
    } catch (e) {
      debugPrint('Crop error: $e');
      if (mounted) Navigator.pop(context, widget.imageFile);
    }
  }
}

// ── Small bottom toolbar button ────────────────────────────────────────────
class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  const _BottomAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.blueAccent : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap == null ? Colors.grey : color, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: onTap == null ? Colors.grey : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drag handle enum ───────────────────────────────────────────────────────
enum _DragHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  topMid,
  bottomMid,
  leftMid,
  rightMid,
  move,
}

// ── Custom painter ─────────────────────────────────────────────────────────
class _CropPainter extends CustomPainter {
  final ui.Image uiImage;
  final Rect displayRect;
  final Rect cropRect;
  final int rotationDeg;
  final double handleSize;

  const _CropPainter({
    required this.uiImage,
    required this.displayRect,
    required this.cropRect,
    required this.rotationDeg,
    required this.handleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Rotate canvas around the center of displayRect
    if (rotationDeg != 0) {
      final cx = displayRect.center.dx;
      final cy = displayRect.center.dy;
      canvas.translate(cx, cy);
      canvas.rotate(rotationDeg * 3.14159265 / 180);
      // After rotation the image might be taller than wide — recalculate dest
      final srcW = uiImage.width.toDouble();
      final srcH = uiImage.height.toDouble();
      final swapped = rotationDeg == 90 || rotationDeg == 270;
      final dW = swapped ? displayRect.height : displayRect.width;
      final dH = swapped ? displayRect.width : displayRect.height;
      canvas.drawImageRect(
        uiImage,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromCenter(center: Offset.zero, width: dW, height: dH),
        Paint(),
      );
    } else {
      canvas.drawImageRect(
        uiImage,
        Rect.fromLTWH(
            0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()),
        displayRect,
        Paint(),
      );
    }

    canvas.restore();

    // Dim overlay outside crop
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // Crop border
    canvas.drawRect(
      cropRect,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );

    // Rule-of-thirds grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 2; i++) {
      final x = cropRect.left + cropRect.width / 3 * i;
      final y = cropRect.top + cropRect.height / 3 * i;
      canvas.drawLine(Offset(x, cropRect.top), Offset(x, cropRect.bottom),
          gridPaint);
      canvas.drawLine(Offset(cropRect.left, y), Offset(cropRect.right, y),
          gridPaint);
    }

    // Corner handles
    for (final pt in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ]) {
      canvas.drawCircle(pt, 10,
          Paint()..color = Colors.blueAccent);
      canvas.drawCircle(
          pt,
          10,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }

    // Edge handles
    for (final pt in [
      Offset(cropRect.center.dx, cropRect.top),
      Offset(cropRect.center.dx, cropRect.bottom),
      Offset(cropRect.left, cropRect.center.dy),
      Offset(cropRect.right, cropRect.center.dy),
    ]) {
      canvas.drawCircle(
          pt, 6, Paint()..color = Colors.white.withOpacity(0.85));
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.cropRect != cropRect ||
      old.uiImage != uiImage ||
      old.rotationDeg != rotationDeg;
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:image/image.dart' as img;
import 'thai_model_service.dart';

/// Called on each MJPEG frame; runs the AI model and returns original frame.
class AiMjpegPreprocessor extends MjpegPreprocessor {
  AiMjpegPreprocessor(this.onNewText);

  final void Function(String) onNewText;

  bool _initStarted = false;

  @override
  List<int>? process(List<int> frame) {
    // Lazy init model (non-blocking)
    if (!ThaiModelService.instance.initialized && !_initStarted) {
      _initStarted = true;
      // fire & forget
      unawaited(ThaiModelService.instance.init());
      return frame;
    }

    if (!ThaiModelService.instance.initialized) {
      // Model still loading; just show video
      return frame;
    }

    try {
      // Decode JPEG bytes to Image
      final bytes = Uint8List.fromList(frame);
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return frame;
      }

      // Run model
      final text = ThaiModelService.instance.runOnImage(decoded);

      // Send result to UI
      onNewText(text);
    } catch (e) {
      // Don't break the stream on error
      debugPrint('AI preprocess error: $e');
    }

    // Return original frame for display
    return frame;
  }
}

// Helper to silence "unawaited" warning
void unawaited(Future<void> f) {}

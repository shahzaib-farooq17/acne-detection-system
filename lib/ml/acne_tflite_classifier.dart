import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

/// Thrown when the picked file is not a valid/supported image.
class InvalidImageException implements Exception {
  final String message;
  const InvalidImageException(this.message);

  @override
  String toString() => 'InvalidImageException: $message';
}

/// Thrown when the image does not contain a sufficient amount of skin.
class NotSkinImageException implements Exception {
  final String message;
  const NotSkinImageException([this.message = 'The uploaded image does not appear to contain skin.']);

  @override
  String toString() => 'NotSkinImageException: $message';
}

/// Thrown when the skin has very low texture variance (perfectly clear/healthy skin).
class HealthySkinException implements Exception {
  final String message;
  const HealthySkinException([this.message = 'This skin appears healthy and clear.']);

  @override
  String toString() => 'HealthySkinException: $message';
}

class AcnePrediction {
  final String acneType;
  final double probability;
  final List<double> rawOutput;
  final List<double> probabilities;
  final List<int> inputShape;
  final List<double> first10NormalizedInput;
  final int preprocessMs;
  final int inferenceMs;

  /// True when the image does not appear to contain skin, or the model
  /// is not confident enough — the condition is not in our dataset.
  final bool isNotInDataset;

  /// What fraction of pixels were detected as skin-toned (0.0–1.0).
  final double skinPixelRatio;

  const AcnePrediction({
    required this.acneType,
    required this.probability,
    required this.rawOutput,
    required this.probabilities,
    required this.inputShape,
    required this.first10NormalizedInput,
    required this.preprocessMs,
    required this.inferenceMs,
    required this.isNotInDataset,
    required this.skinPixelRatio,
  });

  double get confidencePercent => probability * 100.0;
  int get totalMs => preprocessMs + inferenceMs;
}

class AcneTFLiteClassifier {
  AcneTFLiteClassifier._internal();

  static final AcneTFLiteClassifier _instance = AcneTFLiteClassifier._internal();

  factory AcneTFLiteClassifier() => _instance;

  static const int inputSize = 224;
  static const int _threads = 4;
  static const String modelAssetPath = 'assets/models/model.tflite';
  static const List<int> _fixedInputShape = [1, inputSize, inputSize, 3];

  /// Minimum softmax confidence required to accept a prediction.
  /// Below this, the image is treated as "not in our dataset".
  static const double confidenceThreshold = 0.70;

  /// Minimum fraction of skin-toned pixels required for a valid skin image.
  /// Images below this (e.g. laptops, scenery) are rejected before inference.
  static const double skinPixelThreshold = 0.20;

  /// Minimum fraction of skin pixels that must diverge significantly from the 
  /// local background color to be considered "blemished" (acne). 
  /// Below this threshold, the image is perfectly clear/healthy skin.
  static const double healthySkinBlemishThreshold = 0.015; // 1.5%

  /// Allowed image file extensions.
  static const Set<String> allowedImageExtensions = {
    '.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp', '.tiff', '.tif',
  };

  static const List<String> classNames = [
    'Blackheads',
    'Cyst',
    'Papules',
    'Pustules',
    'Whiteheads',
  ];

  static const List<double> mean = [0.485, 0.456, 0.406];
  static const List<double> std = [0.229, 0.224, 0.225];

  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  Future<void>? _initFuture;
  bool _closed = false;

  Future<void> init() async {
    if (_workerSendPort != null) return;
    if (_closed) {
      throw StateError('AcneTFLiteClassifier was already closed.');
    }
    if (_initFuture != null) {
      return _initFuture!;
    }

    final completer = Completer<void>();
    _initFuture = completer.future;

    try {
      await _spawnWorker();
      completer.complete();
    } catch (error, stackTrace) {
      _workerIsolate?.kill(priority: Isolate.immediate);
      _workerIsolate = null;
      _workerSendPort = null;
      _initFuture = null;
      completer.completeError(error, stackTrace);
    }

    return completer.future;
  }

  /// Validates that the file has a supported image extension.
  /// Throws [InvalidImageException] if the extension is not allowed.
  static void validateImageFile(File imageFile) {
    final path = imageFile.path.toLowerCase();
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      throw const InvalidImageException(
        'The selected file has no extension. Please select a valid image file '
        '(jpg, png, webp, etc.).',
      );
    }
    final ext = path.substring(dotIndex);
    if (!allowedImageExtensions.contains(ext)) {
      throw InvalidImageException(
        'Unsupported file type "$ext". Please select a valid image file '
        '(jpg, png, webp, etc.).',
      );
    }
  }

  Future<AcnePrediction> predict(File imageFile) async {
    // Validate file extension before doing any heavy work.
    validateImageFile(imageFile);

    await init();

    Map<String, Object?> result;
    try {
      result = await _sendRequest('predict', {
        'imagePath': imageFile.path,
      });
    } on StateError catch (e) {
      if (e.message.contains('NOT_SKIN_IMAGE')) {
        throw const NotSkinImageException();
      }
      if (e.message.contains('HEALTHY_SKIN')) {
        throw const HealthySkinException();
      }
      rethrow;
    }

    final inputShape = _parseIntList(result['inputShape']);
    final first10 = _parseDoubleList(result['first10NormalizedInput']);
    final rawOutput = _parseDoubleList(result['rawOutput']);
    final preprocessMs = (result['preprocessMs'] as num).toInt();
    final inferenceMs = (result['inferenceMs'] as num).toInt();
    final skinPixelRatio = (result['skinPixelRatio'] as num).toDouble();

    final probabilities = _softmax(rawOutput);
    var bestIndex = 0;
    var bestProbability = probabilities.first;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > bestProbability) {
        bestProbability = probabilities[i];
        bestIndex = i;
      }
    }

    // Primary check: does the image actually contain skin?
    final notInDataset = skinPixelRatio < skinPixelThreshold;

    print('DEBUG ML: Input tensor shape: $inputShape');
    print('DEBUG ML: Skin pixel ratio: ${(skinPixelRatio * 100).toStringAsFixed(1)}%');
    print('DEBUG ML: First 10 normalized input values: $first10');
    print('DEBUG ML: Output tensor values: $rawOutput');
    print('DEBUG ML: Preprocessing: ${preprocessMs}ms');
    print('DEBUG ML: Inference: ${inferenceMs}ms');
    print(
      'DEBUG ML: Top prediction: ${classNames[bestIndex]} '
      '(${(bestProbability * 100).toStringAsFixed(1)}%)',
    );
    if (notInDataset) {
      final reasons = <String>[];
      if (skinPixelRatio < skinPixelThreshold) {
        reasons.add(
          'skin pixels ${(skinPixelRatio * 100).toStringAsFixed(1)}% '
          '< threshold ${(skinPixelThreshold * 100).toStringAsFixed(0)}%',
        );
      }
      if (bestProbability < confidenceThreshold) {
        reasons.add(
          'confidence ${(bestProbability * 100).toStringAsFixed(1)}% '
          '< threshold ${(confidenceThreshold * 100).toStringAsFixed(0)}%',
        );
      }
      print('DEBUG ML: Flagged NOT IN DATASET — ${reasons.join("; ")}');
    }

    return AcnePrediction(
      acneType: classNames[bestIndex],
      probability: bestProbability,
      rawOutput: rawOutput,
      probabilities: probabilities,
      inputShape: inputShape,
      first10NormalizedInput: first10,
      preprocessMs: preprocessMs,
      inferenceMs: inferenceMs,
      isNotInDataset: notInDataset,
      skinPixelRatio: skinPixelRatio,
    );
  }

  Future<void> close() async {
    if (_workerSendPort == null) return;
    try {
      await _sendRequest('close', const <String, Object?>{});
    } catch (_) {
      _workerIsolate?.kill(priority: Isolate.immediate);
    } finally {
      _workerIsolate = null;
      _workerSendPort = null;
      _initFuture = null;
      _closed = true;
    }
  }

  Future<void> _spawnWorker() async {
    final rootIsolateToken = ServicesBinding.rootIsolateToken;
    if (rootIsolateToken == null) {
      throw StateError('RootIsolateToken is unavailable.');
    }

    final modelAsset = await rootBundle.load(modelAssetPath);
    final bootstrapPort = ReceivePort();

    _workerIsolate = await Isolate.spawn(
      _acneModelWorkerMain,
      <String, Object>{
        'bootstrapPort': bootstrapPort.sendPort,
        'rootIsolateToken': rootIsolateToken,
      },
      debugName: 'AcneTFLiteWorker',
    );

    final sendPort = await bootstrapPort.first;
    bootstrapPort.close();

    if (sendPort is! SendPort) {
      throw StateError('Failed to bootstrap ML worker isolate.');
    }

    _workerSendPort = sendPort;

    await _sendRequest('init', {
      'modelBytes': TransferableTypedData.fromList([
        modelAsset.buffer.asUint8List(),
      ]),
    });
  }

  Future<Map<String, Object?>> _sendRequest(
    String type,
    Map<String, Object?> payload,
  ) async {
    final sendPort = _workerSendPort;
    if (sendPort == null) {
      throw StateError('ML worker is not initialized.');
    }

    final responsePort = ReceivePort();
    sendPort.send({
      'type': type,
      'replyTo': responsePort.sendPort,
      ...payload,
    });

    final response = await responsePort.first;
    responsePort.close();

    if (response is! Map) {
      throw StateError('Worker returned an invalid response: $response');
    }

    final data = Map<String, Object?>.from(response);
    final ok = data['ok'] == true;
    if (!ok) {
      final message = data['error']?.toString() ?? 'Unknown ML worker error.';
      final stack = data['stackTrace'];
      throw StateError(
        stack == null ? message : '$message\n$stack',
      );
    }

    return Map<String, Object?>.from(
      (data['data'] as Map?) ?? const <String, Object?>{},
    );
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final expValues = logits.map((value) => math.exp(value - maxLogit)).toList();
    final sum = expValues.fold<double>(0.0, (acc, value) => acc + value);
    return expValues.map((value) => value / sum).toList(growable: false);
  }

  static List<double> _parseDoubleList(Object? value) {
    final list = value as List<dynamic>;
    return list.map((item) => (item as num).toDouble()).toList(growable: false);
  }

  static List<int> _parseIntList(Object? value) {
    final list = value as List<dynamic>;
    return list.map((item) => (item as num).toInt()).toList(growable: false);
  }
}

Future<void> _acneModelWorkerMain(Map<String, Object> bootstrap) async {
  final bootstrapPort = bootstrap['bootstrapPort'] as SendPort;
  final rootIsolateToken = bootstrap['rootIsolateToken'] as RootIsolateToken;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  final commandPort = ReceivePort();
  bootstrapPort.send(commandPort.sendPort);

  Interpreter? interpreter;
  XNNPackDelegate? xnnPackDelegate;
  FlexDelegate? flexDelegate;
  Float32List? reusableInputBuffer;
  Float32List? reusableOutputBuffer;
  List<int>? inputShape;
  List<int>? outputShape;

  await for (final rawCommand in commandPort) {
    if (rawCommand is! Map) {
      continue;
    }

    final command = Map<String, Object?>.from(rawCommand);
    final replyTo = command['replyTo'] as SendPort?;
    final type = command['type'] as String?;

    if (replyTo == null || type == null) {
      continue;
    }

    try {
      switch (type) {
        case 'init':
          final modelBytes = (command['modelBytes'] as TransferableTypedData)
              .materialize()
              .asUint8List();

          final options = InterpreterOptions();
          try {
            options.threads = AcneTFLiteClassifier._threads;

            final xnnPackOptions = XNNPackDelegateOptions(
              numThreads: AcneTFLiteClassifier._threads,
            );
            xnnPackDelegate = XNNPackDelegate(options: xnnPackOptions);
            xnnPackOptions.delete();
            options.addDelegate(xnnPackDelegate);

            flexDelegate = await FlexDelegate.create();
            options.addDelegate(flexDelegate);

            interpreter = Interpreter.fromBuffer(modelBytes, options: options);
          } finally {
            options.delete();
          }

          final currentInputShape = interpreter.getInputTensor(0).shape;
          if (!_sameShape(currentInputShape, AcneTFLiteClassifier._fixedInputShape)) {
            interpreter.resizeInputTensor(
              0,
              AcneTFLiteClassifier._fixedInputShape,
            );
            interpreter.allocateTensors();
          }

          inputShape = interpreter.getInputTensor(0).shape;
          outputShape = interpreter.getOutputTensor(0).shape;
          reusableInputBuffer = Float32List(
            AcneTFLiteClassifier.inputSize *
                AcneTFLiteClassifier.inputSize *
                3,
          );
          reusableOutputBuffer = Float32List(_elementCount(outputShape));

          print('DEBUG ML: Interpreter initialized once in worker isolate.');
          print('DEBUG ML: XNNPACK enabled with 4 threads.');
          print('DEBUG ML: Flex delegate enabled because the model uses SELECT_TF_OPS.');
          print('DEBUG ML: Input tensor shape: $inputShape');
          print('DEBUG ML: Output tensor shape: $outputShape');

          replyTo.send({
            'ok': true,
            'data': {
              'inputShape': inputShape,
              'outputShape': outputShape,
            },
          });
          break;

        case 'predict':
          final localInterpreter = interpreter;
          final localInputBuffer = reusableInputBuffer;
          final localOutputBuffer = reusableOutputBuffer;
          final localInputShape = inputShape;

          if (localInterpreter == null ||
              localInputBuffer == null ||
              localOutputBuffer == null ||
              localInputShape == null) {
            throw StateError('Interpreter is not initialized.');
          }

          final imagePath = command['imagePath'] as String;

          final preprocessWatch = Stopwatch()..start();
          final preprocessResult = _preprocessImageToNhwcFloat32(
            imagePath,
            localInputBuffer,
          );
          preprocessWatch.stop();

          final inferenceWatch = Stopwatch()..start();
          localInterpreter.run(
            preprocessResult.buffer.buffer,
            localOutputBuffer.buffer,
          );
          inferenceWatch.stop();

          final rawOutput = List<double>.from(localOutputBuffer);

          print('DEBUG ML: Input tensor shape: $localInputShape');
          print(
            'DEBUG ML: First 10 normalized input values: '
            '${preprocessResult.first10NormalizedValues}',
          );
          print('DEBUG ML: Output tensor values: $rawOutput');
          print(
            'DEBUG ML: Preprocessing: ${preprocessWatch.elapsedMilliseconds}ms',
          );
          print(
            'DEBUG ML: Inference: ${inferenceWatch.elapsedMilliseconds}ms',
          );

          replyTo.send({
            'ok': true,
            'data': {
              'inputShape': localInputShape,
              'first10NormalizedInput': preprocessResult.first10NormalizedValues,
              'skinPixelRatio': preprocessResult.skinPixelRatio,
              'rawOutput': rawOutput,
              'preprocessMs': preprocessWatch.elapsedMilliseconds,
              'inferenceMs': inferenceWatch.elapsedMilliseconds,
            },
          });
          break;

        case 'close':
          commandPort.close();
          replyTo.send({
            'ok': true,
            'data': const <String, Object?>{},
          });
          break;

        default:
          throw UnsupportedError('Unsupported worker command: $type');
      }
    } catch (error, stackTrace) {
      replyTo.send({
        'ok': false,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      });
    }
  }

  interpreter?.close();
  xnnPackDelegate?.delete();
  flexDelegate?.delete();
}

_PreprocessResult _preprocessImageToNhwcFloat32(
  String imagePath,
  Float32List buffer,
) {
  final bytes = File(imagePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Failed to decode image at $imagePath');
  }

  // ---- Skin pixel detection (YCbCr color-space) ----
  // Run on the original image (or a downscaled version for speed).
  final skinCheckImage = (decoded.width > 128 || decoded.height > 128)
      ? img.copyResize(decoded, width: 128, height: 128,
          interpolation: img.Interpolation.nearest)
      : decoded;

  // --- Create a aggressively downscaled/upscaled version to act as a "smooth" baseline ---
  final blurred = img.copyResize(
    img.copyResize(skinCheckImage, width: 16, height: 16, interpolation: img.Interpolation.linear),
    width: 128, height: 128, interpolation: img.Interpolation.linear,
  );

  var skinPixels = 0;
  var blemishPixels = 0;
  var totalPixels = 0;

  for (var y = 0; y < skinCheckImage.height; y++) {
    for (var x = 0; x < skinCheckImage.width; x++) {
      final pixel = skinCheckImage.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // Convert RGB → YCbCr
      final cb = (-0.169 * r - 0.331 * g + 0.500 * b + 128).round();
      final cr = (0.500 * r - 0.419 * g - 0.081 * b + 128).round();

      // Well-established skin-tone ranges in YCbCr
      if (cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173) {
        skinPixels++;

        // Measure how far this pixel deviates from the "smooth" local background
        final bPixel = blurred.getPixel(x, y);
        final diff = (r - bPixel.r.toInt()).abs() +
                     (g - bPixel.g.toInt()).abs() +
                     (b - bPixel.b.toInt()).abs();

        // 60 total RGB difference means it's a distinct spot/blemish contrasting the skin
        if (diff > 60) {
          blemishPixels++;
        }
      }
      totalPixels++;
    }
  }

  final blemishRatio = skinPixels > 0 ? blemishPixels / skinPixels : 0.0;
  final skinPixelRatio = totalPixels > 0 ? skinPixels / totalPixels : 0.0;

  print('DEBUG ML: Skin pixel ratio: ${(skinPixelRatio * 100).toStringAsFixed(1)}% '
      '($skinPixels / $totalPixels pixels)');
  print('DEBUG ML: Skin Blemish Ratio: ${(blemishRatio * 100).toStringAsFixed(2)}%');

  if (skinPixelRatio < AcneTFLiteClassifier.skinPixelThreshold) {
    throw const FormatException('NOT_SKIN_IMAGE');
  }

  // If blemishes take up less than 0.5% of the skin, it's perfectly clear, healthy skin.
  if (blemishRatio < AcneTFLiteClassifier.healthySkinBlemishThreshold) {
    throw const FormatException('HEALTHY_SKIN');
  }

  // ---- Resize and normalize for model input ----
  final resized = img.copyResize(
    decoded,
    width: AcneTFLiteClassifier.inputSize,
    height: AcneTFLiteClassifier.inputSize,
    interpolation: img.Interpolation.linear,
  );

  final rgbBytes = resized.getBytes(order: img.ChannelOrder.rgb);
  const inv255 = 1.0 / 255.0;

  var srcOffset = 0;
  var dstOffset = 0;
  while (srcOffset < rgbBytes.length) {
    final r = rgbBytes[srcOffset++] * inv255;
    final g = rgbBytes[srcOffset++] * inv255;
    final b = rgbBytes[srcOffset++] * inv255;

    buffer[dstOffset++] = (r - AcneTFLiteClassifier.mean[0]) /
        AcneTFLiteClassifier.std[0];
    buffer[dstOffset++] = (g - AcneTFLiteClassifier.mean[1]) /
        AcneTFLiteClassifier.std[1];
    buffer[dstOffset++] = (b - AcneTFLiteClassifier.mean[2]) /
        AcneTFLiteClassifier.std[2];
  }

  final first10 = List<double>.generate(
    10,
    (index) => buffer[index],
    growable: false,
  );

  return _PreprocessResult(
    buffer: buffer,
    first10NormalizedValues: first10,
    skinPixelRatio: skinPixelRatio,
  );
}

int _elementCount(List<int> shape) {
  var count = 1;
  for (final dimension in shape) {
    count *= dimension;
  }
  return count;
}

bool _sameShape(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

class _PreprocessResult {
  const _PreprocessResult({
    required this.buffer,
    required this.first10NormalizedValues,
    required this.skinPixelRatio,
  });

  final Float32List buffer;
  final List<double> first10NormalizedValues;
  final double skinPixelRatio;
}

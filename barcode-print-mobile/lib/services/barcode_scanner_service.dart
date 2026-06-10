import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;

/// 摄像头扫码服务
/// 封装 mobile_scanner 包，提供扫描结果流
class BarcodeScannerService {
  MobileScannerController? _controller;
  final _barcodeStreamController = StreamController<String>.broadcast();
  StreamSubscription? _subscription;

  Stream<String> get barcodeStream => _barcodeStreamController.stream;

  MobileScannerController get controller {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 1500,
    );
    return _controller!;
  }

  /// 开始监听扫码结果
  void startScanning() {
    _subscription?.cancel();
    _subscription = controller.barcodes.listen((barcode) {
      if (barcode.barcode?.rawValue case final raw?) {
        _barcodeStreamController.add(raw);
      }
    });
  }

  /// 停止扫码
  Future<void> stopScanning() async {
    await _subscription?.cancel();
    await _controller?.stop();
  }

  void dispose() {
    _subscription?.cancel();
    _controller?.dispose();
    _barcodeStreamController.close();
  }
}

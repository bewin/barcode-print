import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../models/models.dart';
import '../database/database_helper.dart';

/// PDF 索引引擎
/// 逐页渲染 PDF → ML Kit 条码检测 → SQLite 存储
class PdfIndexer {
  final DatabaseHelper _db = DatabaseHelper();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  /// 索引一个 PDF 文件，返回结果统计
  Future<IndexResult> indexPdf(PdfFile file,
      {void Function(int current, int total, String msg)? onProgress}) async {
    final document = PdfDocument(filename: file.filePath);
    final totalPages = document.pages.count;
    final allEntries = <BarcodeEntry>[];

    // 先删旧索引
    await _db.deleteBarcodesByFileId(file.id!);

    for (int i = 0; i < totalPages; i++) {
      try {
        onProgress?.call(i + 1, totalPages, '正在索引第 ${i + 1}/${totalPages} 页...');

        // 渲染页面为图片
        final page = document.pages[i];
        final image = await page.toImage(scale: 2.0); // 2x for better detection
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) continue;
        image.dispose();

        // ML Kit 检测条码
        final inputImage = InputImage.fromBytes(
          bytes: bytes.buffer.asUint8List(),
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bytes,
            bytesPerRow: image.width * 4,
          ),
        );

        final barcodes = await _barcodeScanner.processImage(inputImage);

        for (final barcode in barcodes) {
          final rawValue = barcode.rawValue ?? barcode.displayValue ?? '';
          if (rawValue.isEmpty) continue;

          allEntries.add(BarcodeEntry(
            pdfFileId: file.id!,
            barcode: rawValue,
            pageNumber: i + 1,
            productInfo: '', // 移动端 PDF 文字提取较复杂，暂时留空
          ));
        }
      } catch (e) {
        onProgress?.call(i + 1, totalPages, '第 ${i + 1} 页出错: $e');
      }
    }

    document.dispose();

    // 批量写入数据库
    if (allEntries.isNotEmpty) {
      await _db.insertBarcodeBatch(allEntries);
    }

    // 更新文件信息
    file.pageCount = totalPages;
    file.barcodeCount = allEntries.length;
    file.indexed = true;
    await _db.updatePdfFile(file);

    return IndexResult(
      totalPages: totalPages,
      barcodeCount: allEntries.length,
    );
  }

  void dispose() {
    _barcodeScanner.close();
  }
}

class IndexResult {
  final int totalPages;
  final int barcodeCount;
  IndexResult({required this.totalPages, required this.barcodeCount});
}

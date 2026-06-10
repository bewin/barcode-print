// 条码打印系统 - Flutter 移动端
// 数据模型定义

// PDF 文件信息
class PdfFile {
  final int? id;
  final String fileName;
  final String filePath;
  final int pageCount;
  final int barcodeCount;
  final bool indexed;
  final DateTime addedAt;

  PdfFile({
    this.id,
    required this.fileName,
    required this.filePath,
    this.pageCount = 0,
    this.barcodeCount = 0,
    this.indexed = false,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'pageCount': pageCount,
        'barcodeCount': barcodeCount,
        'indexed': indexed ? 1 : 0,
        'addedAt': addedAt.toIso8601String(),
      };

  factory PdfFile.fromMap(Map<String, dynamic> m) => PdfFile(
        id: m['id'] as int?,
        fileName: m['fileName'] as String,
        filePath: m['filePath'] as String,
        pageCount: m['pageCount'] as int? ?? 0,
        barcodeCount: m['barcodeCount'] as int? ?? 0,
        indexed: (m['indexed'] as int? ?? 0) == 1,
        addedAt: DateTime.tryParse(m['addedAt'] as String? ?? ''),
      );
}

// 条码索引条目
class BarcodeEntry {
  final int? id;
  final int pdfFileId;
  final String barcode;
  final int pageNumber;
  final String? productInfo;
  final String? pdfFileName;

  BarcodeEntry({
    this.id,
    required this.pdfFileId,
    required this.barcode,
    required this.pageNumber,
    this.productInfo,
    this.pdfFileName,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pdfFileId': pdfFileId,
        'barcode': barcode,
        'pageNumber': pageNumber,
        'productInfo': productInfo ?? '',
      };

  factory BarcodeEntry.fromMap(Map<String, dynamic> m) => BarcodeEntry(
        id: m['id'] as int?,
        pdfFileId: m['pdfFileId'] as int,
        barcode: m['barcode'] as String,
        pageNumber: m['pageNumber'] as int,
        productInfo: m['productInfo'] as String?,
        pdfFileName: m['pdfFileName'] as String?,
      );
}

// 打印日志条目
class PrintLog {
  final int? id;
  final String barcode;
  final String pdfFileName;
  final int pageNumber;
  final String? printerName;
  final int copies;
  final String result; // "成功" / "失败-..."
  final DateTime printedAt;

  PrintLog({
    this.id,
    required this.barcode,
    required this.pdfFileName,
    required this.pageNumber,
    this.printerName,
    this.copies = 1,
    required this.result,
    DateTime? printedAt,
  }) : printedAt = printedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'barcode': barcode,
        'pdfFileName': pdfFileName,
        'pageNumber': pageNumber,
        'printerName': printerName ?? '',
        'copies': copies,
        'result': result,
        'printedAt': printedAt.toIso8601String(),
      };

  factory PrintLog.fromMap(Map<String, dynamic> m) => PrintLog(
        id: m['id'] as int?,
        barcode: m['barcode'] as String,
        pdfFileName: m['pdfFileName'] as String,
        pageNumber: m['pageNumber'] as int,
        printerName: m['printerName'] as String?,
        copies: m['copies'] as int? ?? 1,
        result: m['result'] as String,
        printedAt: DateTime.tryParse(m['printedAt'] as String? ?? ''),
      );
}

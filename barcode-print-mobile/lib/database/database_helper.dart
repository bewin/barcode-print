import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// SQLite 数据库管理
/// 表: pdf_files, barcode_index, print_logs
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Database? _db;
  Future<Database> get database async => _db ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'barcode_print.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pdf_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL UNIQUE,
        pageCount INTEGER DEFAULT 0,
        barcodeCount INTEGER DEFAULT 0,
        indexed INTEGER DEFAULT 0,
        addedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE barcode_index (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pdfFileId INTEGER NOT NULL,
        barcode TEXT NOT NULL,
        pageNumber INTEGER NOT NULL,
        productInfo TEXT DEFAULT '',
        FOREIGN KEY (pdfFileId) REFERENCES pdf_files(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_barcode ON barcode_index(barcode)
    ''');

    await db.execute('''
      CREATE TABLE print_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL,
        pdfFileName TEXT NOT NULL,
        pageNumber INTEGER NOT NULL,
        printerName TEXT DEFAULT '',
        copies INTEGER DEFAULT 1,
        result TEXT NOT NULL,
        printedAt TEXT NOT NULL
      )
    ''');
  }

  // ==================== PDF 文件 ====================

  Future<int> insertPdfFile(PdfFile file) async {
    final db = await database;
    return db.insert('pdf_files', file.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<PdfFile>> getPdfFiles() async {
    final db = await database;
    final rows = await db.query('pdf_files', orderBy: 'addedAt DESC');
    return rows.map((r) => PdfFile.fromMap(r)).toList();
  }

  Future<void> updatePdfFile(PdfFile file) async {
    final db = await database;
    await db.update('pdf_files', file.toMap(),
        where: 'id = ?', whereArgs: [file.id]);
  }

  Future<int> deletePdfFile(int id) async {
    final db = await database;
    await db.delete('barcode_index', where: 'pdfFileId = ?', whereArgs: [id]);
    return db.delete('pdf_files', where: 'id = ?', whereArgs: [id]);
  }

  Future<PdfFile?> getPdfFileById(int id) async {
    final db = await database;
    final rows = await db.query('pdf_files', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return PdfFile.fromMap(rows.first);
  }

  // ==================== 条码索引 ====================

  Future<void> insertBarcodeBatch(List<BarcodeEntry> entries) async {
    final db = await database;
    final batch = db.batch();
    for (final e in entries) {
      batch.insert('barcode_index', {
        'pdfFileId': e.pdfFileId,
        'barcode': e.barcode,
        'pageNumber': e.pageNumber,
        'productInfo': e.productInfo ?? '',
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteBarcodesByFileId(int pdfFileId) async {
    final db = await database;
    await db.delete('barcode_index',
        where: 'pdfFileId = ?', whereArgs: [pdfFileId]);
  }

  /// 查找条码，返回带 PDF 文件名的结果
  Future<List<BarcodeEntry>> searchBarcode(String barcode) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.*, f.fileName as pdfFileName
      FROM barcode_index b
      JOIN pdf_files f ON b.pdfFileId = f.id
      WHERE b.barcode = ?
      ORDER BY b.pageNumber
    ''', [barcode]);
    return rows.map((r) => BarcodeEntry.fromMap(r)).toList();
  }

  /// 搜索条码（模糊匹配）
  Future<List<BarcodeEntry>> searchBarcodeFuzzy(String query) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.*, f.fileName as pdfFileName
      FROM barcode_index b
      JOIN pdf_files f ON b.pdfFileId = f.id
      WHERE b.barcode LIKE ? OR b.productInfo LIKE ?
      ORDER BY b.pageNumber
      LIMIT 200
    ''', ['%$query%', '%$query%']);
    return rows.map((r) => BarcodeEntry.fromMap(r)).toList();
  }

  Future<int> getBarcodeCountByFileId(int pdfFileId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM barcode_index WHERE pdfFileId = ?',
        [pdfFileId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取某个 PDF 的所有条码（用于明细展示）
  Future<List<BarcodeEntry>> getBarcodesByFileId(int pdfFileId) async {
    final db = await database;
    final rows = await db.query('barcode_index',
        where: 'pdfFileId = ?',
        whereArgs: [pdfFileId],
        orderBy: 'pageNumber ASC');
    return rows.map((r) => BarcodeEntry.fromMap(r)).toList();
  }

  // ==================== 打印日志 ====================

  Future<int> insertPrintLog(PrintLog log) async {
    final db = await database;
    return db.insert('print_logs', log.toMap());
  }

  Future<List<PrintLog>> getPrintLogs({int limit = 200}) async {
    final db = await database;
    final rows = await db.query('print_logs',
        orderBy: 'printedAt DESC', limit: limit);
    return rows.map((r) => PrintLog.fromMap(r)).toList();
  }

  Future<void> clearPrintLogs() async {
    final db = await database;
    await db.delete('print_logs');
  }
}

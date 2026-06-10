import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

/// 摄像头扫码界面
/// 扫码 → 查数据库 → 显示结果 → 可选择打印
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  MobileScannerController? _cameraController;
  bool _scanning = true;
  List<BarcodeEntry>? _results;
  String _lastBarcode = '';

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 2000,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scanning) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty || raw == _lastBarcode) continue;
      _lastBarcode = raw;
      setState(() => _scanning = false);
      _searchBarcode(raw);
      break;
    }
  }

  Future<void> _searchBarcode(String barcode) async {
    final results = await _db.searchBarcode(barcode);
    setState(() => _results = results);
    if (results.isEmpty) {
      _showNotFound(barcode);
    }
  }

  void _showNotFound(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未找到'),
        content: Text('条码 $barcode\n未在索引中找到'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetScan();
            },
            child: const Text('继续扫码'),
          ),
        ],
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _scanning = true;
      _results = null;
      _lastBarcode = '';
    });
  }

  Future<void> _printPage(BarcodeEntry entry, int copies) async {
    // 打印通过 PrintService, 暂时跳转到系统打印
    // 完整实现需要 PrintService

    // 记录日志
    await _db.insertPrintLog(PrintLog(
      barcode: entry.barcode,
      pdfFileName: entry.pdfFileName ?? '',
      pageNumber: entry.pageNumber,
      printerName: '蓝牙打印机',
      copies: copies,
      result: '已发送',
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已发送打印: ${entry.barcode} → 第${entry.pageNumber}页')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('扫码查找')),
      body: Column(
        children: [
          // 摄像头区域
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: _onDetect,
                ),
                // 扫描框指示
                Center(
                  child: Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 最近扫码结果
          if (_lastBarcode.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.primaryContainer,
              child: Text(
                '最近扫码: $_lastBarcode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),

          // 结果列表
          if (_results != null)
            Expanded(
              child: _results!.isEmpty
                  ? const Center(child: Text('未在索引中找到此条码'))
                  : ListView.builder(
                      itemCount: _results!.length,
                      itemBuilder: (ctx, i) {
                        final r = _results![i];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.barcode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('来源: ${r.pdfFileName ?? "未知"}'),
                                Text('页码: 第 ${r.pageNumber} 页'),
                                if ((r.productInfo ?? '').isNotEmpty)
                                  Text('产品: ${r.productInfo}'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    FilledButton.icon(
                                      icon: const Icon(Icons.print),
                                      label: const Text('打印'),
                                      onPressed: () => _printPage(r, 1),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: _resetScan,
                                      child: const Text('继续扫码'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

          // 空闲状态
          if (_lastBarcode.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('将条码对准扫描框'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

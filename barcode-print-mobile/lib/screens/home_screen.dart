import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../services/pdf_indexer.dart';
import 'scan_screen.dart';
import 'detail_screen.dart';
import 'log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<PdfFile> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await _db.getPdfFiles();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _addPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    int added = 0;
    for (final file in result.files) {
      if (file.path == null) continue;
      final pdfFile = PdfFile(
        fileName: file.name,
        filePath: file.path!,
      );
      final id = await _db.insertPdfFile(pdfFile);
      if (id > 0) added++;
    }

    if (added > 0) {
      await _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 $added 个文件')),
        );
      }
      // 自动开始索引
      _indexAll();
    }
  }

  Future<void> _indexAll() async {
    final unindexed = _files.where((f) => !f.indexed).toList();
    if (unindexed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有文件已索引')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _IndexProgressDialog(
        files: unindexed,
        onComplete: _loadFiles,
      ),
    );
  }

  Future<void> _deleteFile(PdfFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定移除 ${file.fileName}？\n索引数据也会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('移除')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deletePdfFile(file.id!);
      await _loadFiles();
    }
  }

  int _totalBarcodes() {
    int sum = 0;
    for (final f in _files) {
      sum += f.barcodeCount;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('条码打印系统'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: '打印日志',
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LogScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 状态栏
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${_files.length} 个文件 · ${_totalBarcodes()} 个条码',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                // 文件列表
                Expanded(
                  child: _files.isEmpty
                      ? const Center(child: Text('暂无文件，点击右下角 + 添加'))
                      : ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (ctx, i) => _FileCard(
                            file: _files[i],
                            onDelete: () => _deleteFile(_files[i]),
                            onDetail: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(file: _files[i]),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 扫描按钮
          FloatingActionButton.extended(
            heroTag: 'scan',
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('扫码查找'),
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              );
              if (result != null) {
                // 扫描完成，结果已显示
              }
            },
          ),
          const SizedBox(height: 8),
          // 添加文件按钮
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addPdfFile,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// 文件列表卡片
class _FileCard extends StatelessWidget {
  final PdfFile file;
  final VoidCallback onDelete;
  final VoidCallback onDetail;

  const _FileCard({
    required this.file,
    required this.onDelete,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: file.indexed
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            file.indexed ? Icons.check : Icons.hourglass_empty,
            color: file.indexed
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(file.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          file.indexed
              ? '${file.barcodeCount} 个条码 · ${file.pageCount} 页'
              : '未索引',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.indexed)
              IconButton(
                icon: const Icon(Icons.table_chart_outlined),
                tooltip: '条码明细',
                onPressed: onDetail,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// 索引进度弹窗
class _IndexProgressDialog extends StatefulWidget {
  final List<PdfFile> files;
  final VoidCallback onComplete;

  const _IndexProgressDialog({required this.files, required this.onComplete});

  @override
  State<_IndexProgressDialog> createState() => _IndexProgressDialogState();
}

class _IndexProgressDialogState extends State<_IndexProgressDialog> {
  final PdfIndexer _indexer = PdfIndexer();
  String _status = '准备中...';
  double _progress = 0;
  int _currentFile = 0;

  @override
  void initState() {
    super.initState();
    _startIndexing();
  }

  Future<void> _startIndexing() async {
    for (int i = 0; i < widget.files.length; i++) {
      setState(() {
        _currentFile = i + 1;
        _status = '正在索引 ${widget.files[i].fileName}...';
      });
      await _indexer.indexPdf(widget.files[i], onProgress: (c, t, msg) {
        if (mounted) {
          setState(() {
            _status = msg;
            _progress = (i + c / t) / widget.files.length;
          });
        }
      });
    }

    setState(() => _progress = 1.0);
    widget.onComplete();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全部索引完成')),
      );
    }
  }

  @override
  void dispose() {
    _indexer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('索引进度 (${_currentFile}/${widget.files.length})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 12),
          Text(_status),
        ],
      ),
    );
  }
}

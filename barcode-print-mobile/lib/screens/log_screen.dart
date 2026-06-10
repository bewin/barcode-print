import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

/// 打印日志查看
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<PrintLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await _db.getPrintLogs();
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.clearPrintLogs();
      _loadLogs();
    }
  }

  Future<void> _exportCsv() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无日志可导出')),
      );
      return;
    }

    // 生成 CSV 内容
    final buffer = StringBuffer();
    buffer.writeln('时间,条码,来源文件,页码,结果');
    for (final log in _logs) {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(log.printedAt);
      buffer.writeln('$time,${log.barcode},${log.pdfFileName},${log.pageNumber},${log.result}');
    }

    // 写到临时文件
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/打印日志.csv');
    await file.writeAsString(buffer.toString());

    // 分享文件
    await Share.shareXFiles([XFile(file.path)], text: '打印日志');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打印日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导出CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空日志',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('暂无打印记录'))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final log = _logs[i];
                    final time =
                        DateFormat('HH:mm:ss').format(log.printedAt);
                    final isFail = log.result.contains('失败');
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isFail ? Icons.error_outline : Icons.check_circle_outline,
                        color: isFail ? Colors.red : Colors.green,
                      ),
                      title: Text(log.barcode,
                          style: const TextStyle(fontFamily: 'monospace')),
                      subtitle: Text(
                        '$time  ${log.pdfFileName}  第${log.pageNumber}页',
                      ),
                      trailing: Text(
                        log.result,
                        style: TextStyle(
                          color: isFail ? Colors.red : null,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

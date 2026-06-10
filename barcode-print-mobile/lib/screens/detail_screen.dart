import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

/// 条码明细查看
class DetailScreen extends StatefulWidget {
  final PdfFile file;
  const DetailScreen({super.key, required this.file});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<BarcodeEntry> _entries = [];
  List<BarcodeEntry> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filter);
  }

  Future<void> _loadData() async {
    final entries = await _db.getBarcodesByFileId(widget.file.id!);
    setState(() {
      _entries = entries;
      _filtered = entries;
      _loading = false;
    });
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _entries.where((e) {
        return e.barcode.contains(query) ||
            (e.productInfo ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.fileName),
        actions: [
          // 搜索条
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '搜索条码...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    '共 ${_entries.length} 个条码${_searchController.text.isNotEmpty ? ' · 筛选出 ${_filtered.length} 个' : ''}',
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('无数据'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final e = _filtered[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Text(
                                  '${e.pageNumber}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(
                                e.barcode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: (e.productInfo ?? '').isNotEmpty
                                  ? Text(e.productInfo!)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

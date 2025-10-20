import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VocabularyImagePicker extends StatefulWidget {
  final String title;
  final String? initialImageUrl;
  final String? initialImagePath;
  final String? suggestQuery;
  final ValueChanged<(String? imageUrl, String? imagePath)> onChanged;

  const VocabularyImagePicker({
    super.key,
    required this.title,
    required this.onChanged,
    this.initialImageUrl,
    this.initialImagePath,
    this.suggestQuery,
  });

  @override
  State<VocabularyImagePicker> createState() => _VocabularyImagePickerState();
}

class _VocabularyImagePickerState extends State<VocabularyImagePicker> {
  String? _imageUrl;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
    _imagePath = widget.initialImagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Từ máy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openPixabaySearch,
                icon: const Icon(Icons.image_search),
                label: const Text('Tìm ảnh'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_imagePath != null || _imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imagePath != null
                ? Image.file(
                    File(_imagePath!),
                    height: 160,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    _imageUrl!,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
          ),
      ],
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'vocab_${DateTime.now().millisecondsSinceEpoch}${p.extension(xfile.path)}';
    final destPath = p.join(directory.path, fileName);
    final file = await File(xfile.path).copy(destPath);
    setState(() {
      _imagePath = file.path;
      _imageUrl = null;
    });
    widget.onChanged((_imageUrl, _imagePath));
  }

  Future<void> _openPixabaySearch() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _PixabaySearchSheet(initialQuery: widget.suggestQuery ?? ''),
    );
    if (result != null) {
      setState(() {
        _imageUrl = result['url'];
        _imagePath = result['path'];
      });
      widget.onChanged((_imageUrl, _imagePath));
    }
  }
}

class _PixabaySearchSheet extends StatefulWidget {
  final String initialQuery;
  const _PixabaySearchSheet({required this.initialQuery});
  @override
  State<_PixabaySearchSheet> createState() => _PixabaySearchSheetState();
}

class _PixabaySearchSheetState extends State<_PixabaySearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _performSearch();
  }

  Future<void> _performSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
          'https://pixabay.com/api/?key=47236624-1103e4a021180072fed099242&q=' +
              Uri.encodeComponent(q) +
              '&image_type=photo&safesearch=true');
      final res = await Dio().getUri(uri);
      final hits = (res.data['hits'] as List).cast<dynamic>();
      _results = hits
          .map((e) => {
                'previewURL': e['previewURL'],
                'largeImageURL':
                    e['largeImageURL'] ?? e['webformatURL'] ?? e['previewURL'],
              })
          .toList();
    } catch (e) {
      _results = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectImage(String url) async {
    if (!mounted) return;
    Navigator.of(context).pop({'url': url});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Tìm ảnh theo từ vựng...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _performSearch,
                  child: const Text('Tìm'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  return GestureDetector(
                    onTap: () => _selectImage(item['largeImageURL'] as String),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['previewURL'] as String,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

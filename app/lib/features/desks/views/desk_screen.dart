// features/desks/desks_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/desk.dart';
import '../../../core/services/database_service.dart';
import 'desk_detail_screen.dart';

class DesksScreen extends StatefulWidget {
  const DesksScreen({super.key});

  @override
  State<DesksScreen> createState() => _DesksScreenState();
}

class _DesksScreenState extends State<DesksScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Desk> _desks = [];
  List<Desk> _filteredDesks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDesks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDesks() async {
    setState(() => _isLoading = true);
    try {
      final desks = await _databaseService.getAllDesks();
      setState(() {
        _desks = desks;
        _filteredDesks = desks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách desk: $e')),
        );
      }
    }
  }

  void _filterDesks(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDesks = _desks;
      } else {
        _filteredDesks = _desks
            .where((desk) =>
                desk.name.toLowerCase().contains(query.toLowerCase()) ||
                (desk.description
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  Future<void> _createNewDesk() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const _CreateDeskDialog(),
    );

    if (result != null) {
      try {
        final now = DateTime.now();
        final desk = Desk(
          name: result['name']!,
          description: result['description'],
          color: result['color'] ?? '#2196F3',
          createdAt: now,
          updatedAt: now,
        );

        await _databaseService.createDesk(desk);
        await _loadDesks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo desk thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi tạo desk: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Danh sách desk',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _filterDesks,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm desk...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: _createNewDesk,
              icon: const Icon(Icons.add),
              label: const Text('Tạo desk mới')),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_filteredDesks.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Chưa có desk nào'
                        : 'Không tìm thấy desk nào',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tạo desk đầu tiên để bắt đầu học từ vựng',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ],
              ),
            )
          else
            ..._filteredDesks.map((desk) => _DeskTile(
                  desk: desk,
                  onTap: () => _navigateToDeskDetail(desk),
                  onDelete: () => _deleteDesk(desk),
                )),
        ],
      ),
    );
  }

  void _navigateToDeskDetail(Desk desk) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeskDetailScreen(desk: desk),
      ),
    );
  }

  Future<void> _deleteDesk(Desk desk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa desk'),
        content: Text('Bạn có chắc chắn muốn xóa desk "${desk.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteDesk(desk.id!);
        await _loadDesks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa desk thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa desk: $e')),
          );
        }
      }
    }
  }
}

class _DeskTile extends StatelessWidget {
  final Desk desk;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeskTile({
    required this.desk,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(int.parse(desk.color.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          desk.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desk.description != null) ...[
              Text(desk.description!),
              const SizedBox(height: 4),
            ],
            FutureBuilder<Map<String, dynamic>>(
              future: DatabaseService().getDeskStats(desk.id!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  return Text(
                    '${stats['total']} từ vựng · ${stats['learned']} đã học\nTiến độ: ${(stats['progress'] * 100).round()}%',
                  );
                }
                return const Text('Đang tải...');
              },
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateDeskDialog extends StatefulWidget {
  const _CreateDeskDialog();

  @override
  State<_CreateDeskDialog> createState() => _CreateDeskDialogState();
}

class _CreateDeskDialogState extends State<_CreateDeskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = '#2196F3';

  final List<String> _colors = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#F44336', // Red
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#FFC107', // Amber
    '#795548', // Brown
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo desk mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên desk',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên desk';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Chọn màu:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final result = <String, String?>{
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                'color': _selectedColor,
              };
              Navigator.of(context).pop(result);
            }
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}

// features/desks/desks_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/models/desk.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/app_button.dart';
import 'desk_detail_screen.dart';
import '../widgets/create_desk_dialog.dart';

class DesksScreen extends StatefulWidget {
  const DesksScreen({super.key});

  @override
  State<DesksScreen> createState() => _DesksScreenState();
}

enum DeskSortOption {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
}

class _DesksScreenState extends State<DesksScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Desk> _desks = [];
  List<Desk> _filteredDesks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DeskSortOption _sortOption = DeskSortOption.nameAsc;

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
      _sortDesks();
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
            .where(
                (desk) => desk.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _sortDesks();
    });
  }

  void _sortDesks() {
    setState(() {
      _filteredDesks.sort((a, b) {
        switch (_sortOption) {
          case DeskSortOption.nameAsc:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case DeskSortOption.nameDesc:
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case DeskSortOption.dateAsc:
            return a.createdAt.compareTo(b.createdAt);
          case DeskSortOption.dateDesc:
            return b.createdAt.compareTo(a.createdAt);
        }
      });
    });
  }

  // Dropdown removed; keep for potential future use

  void _toggleNameSort() {
    setState(() {
      _sortOption = _sortOption == DeskSortOption.nameAsc
          ? DeskSortOption.nameDesc
          : DeskSortOption.nameAsc;
    });
    _sortDesks();
  }

  IconData _faSortIcon() {
    return _sortOption == DeskSortOption.nameAsc
        ? FontAwesomeIcons.arrowUpAZ
        : FontAwesomeIcons.arrowDownAZ;
  }

  Future<void> _createNewDesk() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const CreateDeskDialog(),
    );
    print("result: $result");

    if (result != null) {
      try {
        final now = DateTime.now();
        final desk = Desk(
          name: result['name']!,
          color: result['color'] ?? '#2196F3',
          createdAt: now,
          updatedAt: now,
        );

        await _databaseService.createDesk(desk);
        await _loadDesks();
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.blue.shade200),
                gapPadding: 10,
              ),
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppButton(
                  onPressed: _createNewDesk,
                  label: 'Tạo desk mới',
                  icon: Icons.add,
                  variant: AppButtonVariant.outlined),
              const SizedBox(width: 12),
              AppButton(
                  onPressed: _toggleNameSort,
                  label: 'Sắp xếp',
                  icon: _faSortIcon(),
                  variant: AppButtonVariant.text),
            ],
          ),
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
            // Description removed from model
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

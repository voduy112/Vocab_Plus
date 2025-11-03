import 'package:flutter/material.dart';
import '../../../core/models/deck.dart';
import '../views/add_vocabulary_screen.dart';
import '../views/deck_detail_screen.dart';
import '../../../core/widgets/context_menu_scaffold.dart';

class DeckContextMenu extends StatelessWidget {
  final Deck desk;
  final VoidCallback onDelete;

  const DeckContextMenu({
    super.key,
    required this.desk,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ContextMenuScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color:
                        Color(int.parse(desk.color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    desk.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Menu options
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: Icon(
                  Icons.list,
                  color: Colors.blue[600],
                ),
                title: const Text('Xem từ vựng'),
                subtitle: const Text('Xem và quản lý danh sách từ vựng'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DeckDetailScreen(desk: desk),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.add,
                  color: Colors.blue[600],
                ),
                title: const Text('Thêm từ vựng'),
                subtitle: const Text('Thêm từ vựng mới vào deck này'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddVocabularyScreen(desk: desk),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Colors.red[600],
                ),
                title: const Text('Xóa deck'),
                subtitle: const Text('Xóa deck và tất cả từ vựng bên trong'),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

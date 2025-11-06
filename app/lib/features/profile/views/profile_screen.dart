// features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../core/database/database_helper.dart';
import '../../decks/services/deck_service.dart';
import '../../decks/services/vocabulary_service.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/vocabulary.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            CircleAvatar(
                radius: 36,
                backgroundImage: auth.photoURL != null
                    ? NetworkImage(auth.photoURL!)
                    : null),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(auth.isLoggedIn ? 'Logged in' : 'Guest'),
            ])
          ]),
          const SizedBox(height: 16),
          if (!auth.isLoggedIn)
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập Google'),
              onPressed: () async {
                await context.read<AuthController>().signInWithGoogle();
                final api = ApiClient('http://10.0.2.2:5000');
                await api.dio.post('/users/me/upsert'); // upsert hồ sơ
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đăng nhập & upsert')));
              },
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              onPressed: () => context.read<AuthController>().signOut(),
            ),
          const SizedBox(height: 24),
          const ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Settings'),
              trailing: Icon(Icons.chevron_right)),
          const ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('Notifications'),
              trailing: Icon(Icons.chevron_right)),

          // Nút tạm thời để xóa database (chỉ dành cho development)
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xóa Database (Dev Only)'),
            subtitle: const Text('Xóa toàn bộ dữ liệu local'),
            trailing: const Icon(Icons.warning, color: Colors.orange),
            onTap: () => _showDeleteDatabaseDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.blue),
            title: const Text('Tạo Dữ Liệu Mẫu (Dev Only)'),
            subtitle: const Text('Tạo deck và từ vựng mẫu để test'),
            trailing: const Icon(Icons.science, color: Colors.blue),
            onTap: () => _createSampleData(context),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.green),
            title: const Text('Test Database Migration (Dev Only)'),
            subtitle: const Text('Kiểm tra migration database'),
            trailing: const Icon(Icons.bug_report, color: Colors.green),
            onTap: () => _testDatabaseMigration(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteDatabaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Xóa Database'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn có chắc chắn muốn xóa toàn bộ database?'),
              SizedBox(height: 8),
              Text(
                'Hành động này sẽ:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Xóa tất cả deck và từ vựng'),
              Text('• Xóa lịch sử học tập'),
              Text('• Không thể hoàn tác'),
              SizedBox(height: 8),
              Text(
                'Chỉ sử dụng trong quá trình phát triển!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteDatabase(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa Database'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDatabase(BuildContext context) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Xóa database
      await DatabaseHelper().deleteDatabase();

      // Đóng loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Hiển thị thông báo thành công
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database đã được xóa thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (context.mounted) Navigator.of(context).pop();

      // Hiển thị thông báo lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa database: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createSampleData(BuildContext context) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Import các service cần thiết
      final deckService = DeckService();
      final vocabularyService = VocabularyService();

      // Tạo deck mẫu
      final deck = Deck(
        name: 'Sample Vocabulary',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final deskId = await deckService.createDeck(deck);

      if (deskId > 0) {
        // Tạo 20 từ mẫu, đa dạng cardType và field schema hiện tại
        final now = DateTime.now();
        final sampleVocabularies = <Vocabulary>[
          // 1-8: Basis cards (có pronunciation/example/translation)
          Vocabulary(
            deskId: deskId,
            front: 'beautiful',
            back: 'đẹp; xinh đẹp',
            frontExtra: {
              'pronunciation': '/ˈbjuːtɪfəl/',
              'example': 'She is a beautiful girl.',
            },
            backExtra: {'translation': 'Cô ấy là một cô gái xinh đẹp.'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'run',
            back: 'chạy',
            frontExtra: {
              'pronunciation': '/rʌn/',
              'example': 'I run every morning.',
            },
            backExtra: {'translation': 'Tôi chạy mỗi sáng.'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'quickly',
            back: 'nhanh chóng',
            frontExtra: {
              'pronunciation': '/ˈkwɪkli/',
              'example': 'He quickly finished his work.',
            },
            backExtra: {
              'translation': 'Anh ấy nhanh chóng hoàn thành công việc.'
            },
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'book',
            back: 'quyển sách',
            frontExtra: {
              'pronunciation': '/bʊk/',
              'example': 'This book is interesting.',
            },
            backExtra: {'translation': 'Cuốn sách này rất thú vị.'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'teacher',
            back: 'giáo viên',
            frontExtra: {
              'pronunciation': '/ˈtiːtʃər/',
              'example': 'My teacher is very helpful.',
            },
            backExtra: {'translation': 'Giáo viên của tôi rất nhiệt tình.'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'learn',
            back: 'học',
            frontExtra: {
              'pronunciation': '/lɜːrn/',
              'example': 'We learn English every day.',
            },
            backExtra: {'translation': 'Chúng tôi học tiếng Anh mỗi ngày.'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'difficult',
            back: 'khó; khó khăn',
            frontExtra: {
              'pronunciation': '/ˈdɪfɪkəlt/',
              'example': 'This task is difficult.',
            },
            backExtra: {'translation': 'Nhiệm vụ này khó.'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'example',
            back: 'ví dụ',
            frontExtra: {
              'pronunciation': '/ɪɡˈzæmpəl/',
              'example': 'For example, apples are fruits.',
            },
            backExtra: {'translation': 'Ví dụ, táo là trái cây.'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.basis,
          ),

          // 9-14: Reverse cards (đơn giản 2 mặt)
          Vocabulary(
            deskId: deskId,
            front: 'cat',
            back: 'con mèo',
            createdAt: now,
            updatedAt: now,
            cardType: CardType.reverse,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'dog',
            back: 'con chó',
            createdAt: now,
            updatedAt: now,
            cardType: CardType.reverse,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'house',
            back: 'ngôi nhà',
            createdAt: now,
            updatedAt: now,
            cardType: CardType.reverse,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'car',
            back: 'xe hơi',
            createdAt: now,
            updatedAt: now,
            cardType: CardType.reverse,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'water',
            back: 'nước',
            createdAt: now,
            updatedAt: now,
            cardType: CardType.reverse,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'food',
            back: 'thức ăn',
            createdAt: now,
            updatedAt: now,
            cardType: CardType.reverse,
          ),

          // 15-20: Typing cards (có hint_text)
          Vocabulary(
            deskId: deskId,
            front: 'hello',
            back: 'xin chào',
            backExtra: {'hint_text': 'Lời chào thân thiện'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.typing,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'goodbye',
            back: 'tạm biệt',
            backExtra: {'hint_text': 'Lời chào tạm biệt'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.typing,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'thank you',
            back: 'cảm ơn',
            backExtra: {'hint_text': 'Lời cảm ơn lịch sự'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.typing,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'please',
            back: 'làm ơn',
            backExtra: {'hint_text': 'Dùng khi nhờ vả'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.typing,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'sorry',
            back: 'xin lỗi',
            backExtra: {'hint_text': 'Xin lỗi khi mắc lỗi'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.typing,
          ),
          Vocabulary(
            deskId: deskId,
            front: 'welcome',
            back: 'chào mừng',
            backExtra: {'hint_text': 'Chào đón ai đó'},
            createdAt: now,
            updatedAt: now,
            cardType: CardType.typing,
          ),
        ];

        // Tạo từ vựng
        for (final vocab in sampleVocabularies) {
          await vocabularyService.createVocabulary(vocab);
        }
      }

      // Đóng loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Hiển thị thông báo thành công
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo dữ liệu mẫu thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (context.mounted) Navigator.of(context).pop();

      // Hiển thị thông báo lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo dữ liệu mẫu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _testDatabaseMigration(BuildContext context) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Test tạo vocabulary với hintText và cardType
      final deckService = DeckService();

      // Tạo deck test
      final testDesk = Deck(
        name: 'Test Migration',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final deskId = await deckService.createDeck(testDesk);

      if (deskId > 0) {
        // Test tạo vocabulary với hintText
        final testVocab = Vocabulary(
          deskId: deskId,
          front: 'test',
          back: 'kiểm tra',
          backExtra: {
            'hint': 'Gợi ý test migration',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          cardType: CardType.typing,
        );

        final vocabularyService = VocabularyService();
        final vocabId = await vocabularyService.createVocabulary(testVocab);

        if (vocabId > 0) {
          // Test đọc lại vocabulary
          final retrievedVocab =
              await vocabularyService.getVocabularyById(vocabId);

          if (retrievedVocab != null) {
            // Kiểm tra các trường mới
            final hasHintText = retrievedVocab.backExtra != null &&
                retrievedVocab.backExtra!.containsKey('hint');
            final hasCardType = retrievedVocab.cardType != CardType.basis;

            // Đóng loading dialog
            if (context.mounted) Navigator.of(context).pop();

            // Hiển thị kết quả test
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Kết Quả Test Migration'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ Tạo vocabulary thành công: ID $vocabId'),
                      Text('✅ HintText: ${hasHintText ? "Có" : "Không"}'),
                      Text('✅ CardType: ${hasCardType ? "Có" : "Không"}'),
                      if (hasHintText)
                        Text(
                            '   - HintText value: "${retrievedVocab.backExtra!['hint']}"'),
                      if (hasCardType)
                        Text('   - CardType value: ${retrievedVocab.cardType}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          } else {
            throw Exception('Không thể đọc vocabulary sau khi tạo');
          }
        } else {
          throw Exception('Không thể tạo vocabulary');
        }
      } else {
        throw Exception('Không thể tạo desk');
      }
    } catch (e) {
      // Đóng loading dialog nếu có lỗi
      if (context.mounted) Navigator.of(context).pop();

      // Hiển thị thông báo lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi test migration: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

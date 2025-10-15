import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/desk.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/services/database_service.dart';
import '../widgets/card_forms/basis_card_form.dart';
import '../widgets/card_forms/reverse_card_form.dart';
import '../widgets/card_forms/typing_card_form.dart';

class AddVocabularyScreen extends StatefulWidget {
  final Desk desk;
  final Vocabulary? vocabulary;

  const AddVocabularyScreen({
    super.key,
    required this.desk,
    this.vocabulary,
  });

  @override
  State<AddVocabularyScreen> createState() => _AddVocabularyScreenState();
}

class _AddVocabularyScreenState extends State<AddVocabularyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _exampleController = TextEditingController();
  final _translationController = TextEditingController();
  final _hintTextController = TextEditingController();
  bool _isEditing = false;
  CardType _selectedCardType = CardType.basis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vocabulary != null;
    if (_isEditing) {
      final vocab = widget.vocabulary!;
      _frontController.text = vocab.word;
      _backController.text = vocab.meaning;
      _pronunciationController.text = vocab.pronunciation ?? '';
      _exampleController.text = vocab.example ?? '';
      _translationController.text = vocab.translation ?? '';
      _hintTextController.text = vocab.hintText ?? '';
      _selectedCardType = vocab.cardType;
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _pronunciationController.dispose();
    _exampleController.dispose();
    _translationController.dispose();
    _hintTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa từ vựng' : 'Thêm từ vựng mới'),
        backgroundColor:
            Color(int.parse(widget.desk.color.replaceFirst('#', '0xFF'))),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveVocabulary,
              child: Text(
                _isEditing ? 'Cập nhật' : 'Lưu',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thông tin desk
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(int.parse(
                          widget.desk.color.replaceFirst('#', '0xFF')))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(int.parse(
                            widget.desk.color.replaceFirst('#', '0xFF')))
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                            widget.desk.color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.desk.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Thêm từ vựng mới vào bộ sưu tập này',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Chọn loại thẻ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Loại thẻ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CardType>(
                        value: _selectedCardType,
                        isExpanded: true,
                        itemHeight: 48,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          helperText: 'Chọn loại thẻ phù hợp với cách học',
                        ),
                        items: CardType.values.map((e) {
                          String title;
                          String subtitle;
                          IconData icon;

                          switch (e) {
                            case CardType.basis:
                              title = 'Basis Card';
                              subtitle = 'Đầy đủ thông tin';
                              icon = Icons.description;
                              break;
                            case CardType.reverse:
                              title = 'Reverse Card';
                              subtitle = 'Đơn giản 2 mặt';
                              icon = Icons.swap_horiz;
                              break;
                            case CardType.typing:
                              title = 'Typing Card';
                              subtitle = 'Luyện gõ với gợi ý';
                              icon = Icons.keyboard;
                              break;
                          }

                          return DropdownMenuItem<CardType>(
                            value: e,
                            child: Row(
                              children: [
                                Icon(icon, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$title - $subtitle',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedCardType = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Form theo loại thẻ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Thông tin từ vựng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFormByType(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormByType() {
    switch (_selectedCardType) {
      case CardType.basis:
        return BasisCardForm(
          frontController: _frontController,
          backController: _backController,
          pronunciationController: _pronunciationController,
          exampleController: _exampleController,
          translationController: _translationController,
        );
      case CardType.reverse:
        return ReverseCardForm(
          frontController: _frontController,
          backController: _backController,
        );
      case CardType.typing:
        return TypingCardForm(
          frontController: _frontController,
          backController: _backController,
          hintTextController: _hintTextController,
        );
    }
  }

  Future<void> _saveVocabulary() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final vocabulary = Vocabulary(
        id: _isEditing ? widget.vocabulary!.id : null,
        deskId: widget.desk.id!,
        word: _frontController.text.trim(),
        meaning: _backController.text.trim(),
        pronunciation: _pronunciationController.text.trim().isEmpty
            ? null
            : _pronunciationController.text.trim(),
        example: _exampleController.text.trim().isEmpty
            ? null
            : _exampleController.text.trim(),
        translation: _translationController.text.trim().isEmpty
            ? null
            : _translationController.text.trim(),
        hintText: _hintTextController.text.trim().isEmpty
            ? null
            : _hintTextController.text.trim(),
        masteryLevel: _isEditing ? widget.vocabulary!.masteryLevel : 0,
        reviewCount: _isEditing ? widget.vocabulary!.reviewCount : 0,
        lastReviewed: _isEditing ? widget.vocabulary!.lastReviewed : null,
        nextReview: _isEditing ? widget.vocabulary!.nextReview : null,
        createdAt: _isEditing ? widget.vocabulary!.createdAt : now,
        updatedAt: now,
        cardType: _selectedCardType,
      );

      final databaseService = DatabaseService();

      if (_isEditing) {
        await databaseService.updateVocabulary(vocabulary);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật từ vựng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (_selectedCardType == CardType.reverse) {
          // Tạo 2 thẻ ngược nhau cho Reverse Card
          await databaseService.createVocabulary(vocabulary);
          final reversedVocabulary = Vocabulary(
            id: null,
            deskId: widget.desk.id!,
            word: _backController.text.trim(),
            meaning: _frontController.text.trim(),
            pronunciation: null,
            example: null,
            translation: null,
            hintText: null,
            masteryLevel: 0,
            reviewCount: 0,
            lastReviewed: null,
            nextReview: null,
            createdAt: now,
            updatedAt: now,
            isActive: true,
            cardType: CardType.reverse,
          );
          await databaseService.createVocabulary(reversedVocabulary);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm 2 thẻ Reverse (ngược nhau)!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await databaseService.createVocabulary(vocabulary);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm từ vựng thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }

      if (mounted) {
        context.pop(true); // Trả về true để báo hiệu đã thêm/sửa thành công
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

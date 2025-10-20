import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/desk.dart';
import '../../../core/models/vocabulary.dart';
import '../../../core/services/database_service.dart';
// removed local image picking imports; handled inside widget
import '../widgets/card_forms/basis_card_form.dart';
import '../widgets/card_forms/reverse_card_form.dart';
import '../widgets/card_forms/typing_card_form.dart';
import '../widgets/card_forms/dynamic_card_form.dart';
// removed dio import; handled inside widget
import '../widgets/image_picker_field.dart';

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
  bool _isEditing = false;
  CardType _selectedCardType = CardType.basis;
  bool _isLoading = false;
  String? _frontImagePath;
  String? _frontImageUrl;
  String? _backImagePath;
  String? _backImageUrl;
  bool _pickForFront = true; // chọn mặt để thêm ảnh
  DynamicFormState? _dynamicState;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vocabulary != null;
    if (_isEditing) {
      final vocab = widget.vocabulary!;
      _frontController.text = vocab.front;
      _backController.text = vocab.back;
      _selectedCardType = vocab.cardType;
      _frontImagePath = vocab.imagePath;
      _frontImageUrl = vocab.imageUrl;
      _backImagePath = vocab.backImagePath;
      _backImageUrl = vocab.backImageUrl;

      // Initialize dynamic state with existing data
      if (vocab.frontExtra != null || vocab.backExtra != null) {
        _dynamicState = DynamicFormState(
          frontFields: vocab.frontExtra?.keys
                  .map((key) => DynamicField(
                        id: key,
                        label: _getFieldLabel(key),
                        hint: _getFieldHint(key),
                        icon: _getFieldIcon(key),
                      ))
                  .toList() ??
              [],
          backFields: vocab.backExtra?.keys
                  .map((key) => DynamicField(
                        id: key,
                        label: _getFieldLabel(key),
                        hint: _getFieldHint(key),
                        icon: _getFieldIcon(key),
                      ))
                  .toList() ??
              [],
          frontValues: vocab.frontExtra ?? {},
          backValues: vocab.backExtra ?? {},
        );
      }
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case 'pronunciation':
        return 'Phiên âm';
      case 'example':
        return 'Ví dụ';
      case 'translation':
        return 'Bản dịch ví dụ';
      default:
        return key;
    }
  }

  String _getFieldHint(String key) {
    switch (key) {
      case 'pronunciation':
        return 'Nhập phiên âm của từ';
      case 'example':
        return 'Nhập câu ví dụ';
      case 'translation':
        return 'Nhập bản dịch của ví dụ';
      default:
        return 'Nhập thông tin';
    }
  }

  IconData _getFieldIcon(String key) {
    switch (key) {
      case 'pronunciation':
        return Icons.record_voice_over;
      case 'example':
        return Icons.format_quote;
      case 'translation':
        return Icons.translate;
      default:
        return Icons.text_fields;
    }
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
                      const SizedBox(height: 16),
                      Text(
                        'Thêm ảnh cho',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Mặt trước'),
                            selected: _pickForFront,
                            onSelected: (v) {
                              if (!v) return;
                              setState(() => _pickForFront = true);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Mặt sau'),
                            selected: !_pickForFront,
                            onSelected: (v) {
                              if (!v) return;
                              setState(() => _pickForFront = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      VocabularyImagePicker(
                        key: ValueKey(_pickForFront),
                        title: 'Ảnh (tuỳ chọn)',
                        initialImageUrl:
                            _pickForFront ? _frontImageUrl : _backImageUrl,
                        initialImagePath:
                            _pickForFront ? _frontImagePath : _backImagePath,
                        suggestQuery: _pickForFront
                            ? _frontController.text.trim()
                            : _backController.text.trim(),
                        onChanged: (value) {
                          setState(() {
                            if (_pickForFront) {
                              _frontImageUrl = value.$1;
                              _frontImagePath = value.$2;
                            } else {
                              _backImageUrl = value.$1;
                              _backImagePath = value.$2;
                            }
                          });
                        },
                      ),
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
          pronunciationController: TextEditingController(),
          exampleController: TextEditingController(),
          translationController: TextEditingController(),
          initialFrontExtra: _isEditing ? widget.vocabulary!.frontExtra : null,
          initialBackExtra: _isEditing ? widget.vocabulary!.backExtra : null,
          onChanged: (state) {
            setState(() => _dynamicState = state);
          },
        );
      case CardType.reverse:
        return ReverseCardForm(
          frontController: _frontController,
          backController: _backController,
          initialFrontExtra: _isEditing ? widget.vocabulary!.frontExtra : null,
          initialBackExtra: _isEditing ? widget.vocabulary!.backExtra : null,
          onChanged: (state) {
            setState(() => _dynamicState = state);
          },
        );
      case CardType.typing:
        return TypingCardForm(
          frontController: _frontController,
          backController: _backController,
          hintTextController: TextEditingController(),
          initialFrontExtra: _isEditing ? widget.vocabulary!.frontExtra : null,
          initialBackExtra: _isEditing ? widget.vocabulary!.backExtra : null,
          onChanged: (state) {
            setState(() => _dynamicState = state);
          },
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
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        masteryLevel: _isEditing ? widget.vocabulary!.masteryLevel : 0,
        reviewCount: _isEditing ? widget.vocabulary!.reviewCount : 0,
        lastReviewed: _isEditing ? widget.vocabulary!.lastReviewed : null,
        nextReview: _isEditing ? widget.vocabulary!.nextReview : null,
        createdAt: _isEditing ? widget.vocabulary!.createdAt : now,
        updatedAt: now,
        cardType: _selectedCardType,
        imageUrl: _frontImageUrl,
        imagePath: _frontImagePath,
        backImageUrl: _backImageUrl,
        backImagePath: _backImagePath,
        frontExtra: _dynamicState?.frontValues,
        backExtra: _dynamicState?.backValues,
      );
      print('vocabulary: ${vocabulary.toString()}');
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
            front: _backController.text.trim(),
            back: _frontController.text.trim(),
            masteryLevel: 0,
            reviewCount: 0,
            lastReviewed: null,
            nextReview: null,
            createdAt: now,
            updatedAt: now,
            isActive: true,
            cardType: CardType.reverse,
            imageUrl: _backImageUrl,
            imagePath: _backImagePath,
            backImageUrl: _frontImageUrl,
            backImagePath: _frontImagePath,
            frontExtra: _dynamicState?.backValues,
            backExtra: _dynamicState?.frontValues,
          );
          print('vocabulary: ${vocabulary.toString()}');
          print('reversedVocabulary: ${reversedVocabulary.toString()}');
          print('dynamicState: ${_dynamicState?.toString()}');
          print('dynamicState frontValues: ${_dynamicState?.frontValues}');
          print('dynamicState backValues: ${_dynamicState?.backValues}');

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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// preview nội dung chuyển qua widget riêng
import 'package:go_router/go_router.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/vocabulary.dart';
// database service chỉ dùng trong preview dialog (đã di chuyển)
// removed local image picking imports; handled inside widget
import '../widgets/card_forms/dynamic_card_form.dart';
// removed dio import; handled inside widget
import '../repositories/vocabulary_repository.dart';
import '../widgets/deck_info_header.dart';
import '../widgets/card_type_selector.dart';
import '../widgets/image_pick_section.dart';
import '../widgets/vocabulary_form_card.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/preview_dialog.dart';

class AddVocabularyScreen extends StatefulWidget {
  final Deck desk;
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
  final _hintTextController = TextEditingController();
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

      // Initialize hint text controller
      if (vocab.backExtra != null &&
          vocab.backExtra!.containsKey('hint_text')) {
        _hintTextController.text = vocab.backExtra!['hint_text']!;
      }

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
    _hintTextController.dispose();
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
      case 'hint_text':
        return 'Gợi ý';
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
      case 'hint_text':
        return 'Nhập gợi ý cho người học';
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
      case 'hint_text':
        return Icons.lightbulb_outline;
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
          AppBarActions(
            isLoading: _isLoading,
            onPreview: _showPreviewDialog,
            onSave: _saveVocabulary,
            saveLabel: _isEditing ? 'Cập nhật' : 'Lưu',
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
              DeskInfoHeader(desk: widget.desk),

              const SizedBox(height: 24),

              // Chọn loại thẻ
              CardTypeSelector(
                value: _selectedCardType,
                onChanged: (val) => setState(() => _selectedCardType = val),
              ),

              const SizedBox(height: 16),

              // Form + chọn ảnh
              VocabularyFormCard(
                cardType: _selectedCardType,
                frontController: _frontController,
                backController: _backController,
                hintTextController: _hintTextController,
                initialFrontExtra:
                    _isEditing ? widget.vocabulary!.frontExtra : null,
                initialBackExtra:
                    _isEditing ? widget.vocabulary!.backExtra : null,
                onChanged: (state) => setState(() => _dynamicState = state),
              ),
              const SizedBox(height: 16),
              ImagePickSection(
                pickForFront: _pickForFront,
                frontImageUrl: _frontImageUrl,
                frontImagePath: _frontImagePath,
                backImageUrl: _backImageUrl,
                backImagePath: _backImagePath,
                frontText: _frontController.text.trim(),
                backText: _backController.text.trim(),
                onToggleTarget: (v) => setState(() => _pickForFront = v),
                onChanged: (forFront, url, path) {
                  setState(() {
                    if (forFront) {
                      _frontImageUrl = url;
                      _frontImagePath = path;
                    } else {
                      _backImageUrl = url;
                      _backImagePath = path;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // form đã tách ra VocabularyFormCard

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
      print('=== SAVING VOCABULARY ===');
      print('Front image URL: $_frontImageUrl');
      print('Front image Path: $_frontImagePath');
      print('Back image URL: $_backImageUrl');
      print('Back image Path: $_backImagePath');
      print('Card type: $_selectedCardType');
      print('vocabulary: ${vocabulary.toString()}');
      final vocabRepo = context.read<VocabularyRepository>();

      if (_isEditing) {
        await vocabRepo.updateVocabulary(vocabulary);
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
          await vocabRepo.createVocabulary(vocabulary);

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

          await vocabRepo.createVocabulary(reversedVocabulary);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm 2 thẻ Reverse (ngược nhau)!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await vocabRepo.createVocabulary(vocabulary);
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

  void _showPreviewDialog() {
    final now = DateTime.now();
    final tempVocab = Vocabulary(
      id: null,
      deskId: widget.desk.id!,
      front: _frontController.text.trim(),
      back: _backController.text.trim(),
      imageUrl: _frontImageUrl,
      imagePath: _frontImagePath,
      backImageUrl: _backImageUrl,
      backImagePath: _backImagePath,
      frontExtra: _dynamicState?.frontValues,
      backExtra: _dynamicState?.backValues,
      createdAt: now,
      updatedAt: now,
      cardType: _selectedCardType,
    );

    final accent =
        Color(int.parse(widget.desk.color.replaceFirst('#', '0xFF')));
    showVocabularyPreviewDialog(
      context: context,
      vocabulary: tempVocab,
      cardType: _selectedCardType,
      accent: accent,
    );
  }
}

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
import '../../../core/services/cloud_storage_service.dart';

class AddVocabularyScreen extends StatefulWidget {
  final Deck deck;
  final Vocabulary? vocabulary;

  const AddVocabularyScreen({
    super.key,
    required this.deck,
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
  String? _originalFrontImageUrl;
  String? _originalBackImageUrl;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.vocabulary != null;
    if (_isEditing) {
      final vocab = widget.vocabulary!;
      _frontController.text = vocab.front;
      _backController.text = vocab.back;
      _selectedCardType = vocab.cardType;
      _frontImagePath = vocab.frontImagePath;
      _frontImageUrl = vocab.frontImageUrl;
      _backImagePath = vocab.backImagePath;
      _backImageUrl = vocab.backImageUrl;
      _originalFrontImageUrl = vocab.frontImageUrl;
      _originalBackImageUrl = vocab.backImageUrl;

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
              // Thông tin deck
              DeskInfoHeader(desk: widget.deck),

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
    // Kiểm tra form state
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra deck có ID không
    if (widget.deck.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Deck chưa có ID. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Kiểm tra front và back không rỗng
    final frontText = _frontController.text.trim();
    final backText = _backController.text.trim();

    if (frontText.isEmpty || backText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Vui lòng nhập đầy đủ thông tin từ vựng.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nowUtc = DateTime.now().toUtc();

      // Đảm bảo vocabulary không null khi editing
      final editingVocab =
          _isEditing && widget.vocabulary != null ? widget.vocabulary! : null;

      final vocabulary = Vocabulary(
        id: editingVocab?.id,
        deskId: widget.deck.id!,
        front: frontText,
        back: backText,
        masteryLevel: editingVocab?.masteryLevel ?? 0,
        reviewCount: editingVocab?.reviewCount ?? 0,
        lastReviewed: editingVocab?.lastReviewed,
        nextReview: editingVocab?.nextReview,
        createdAt: editingVocab?.createdAt ?? nowUtc,
        updatedAt: nowUtc,
        cardType: _selectedCardType,
        frontImageUrl: _frontImageUrl,
        frontImagePath: _frontImagePath,
        backImageUrl: _backImageUrl,
        backImagePath: _backImagePath,
        frontExtra: _dynamicState?.frontValues,
        backExtra: _dynamicState?.backValues,
      );
      print('=== SAVING VOCABULARY ===');
      print('Updated at: ${vocabulary.updatedAt}');
      print('Front image URL: $_frontImageUrl');
      print('Front image Path: $_frontImagePath');
      print('Back image URL: $_backImageUrl');
      print('Back image Path: $_backImagePath');
      print('Card type: $_selectedCardType');
      print('vocabulary: ${vocabulary.toString()}');
      final vocabRepo = context.read<VocabularyRepository>();

      if (_isEditing) {
        await vocabRepo.updateVocabulary(vocabulary);
        await _deleteReplacedImages(vocabulary);
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
            deskId: widget.deck.id!, // Đã kiểm tra null ở trên
            front: _backController.text.trim(),
            back: _frontController.text.trim(),
            masteryLevel: 0,
            reviewCount: 0,
            lastReviewed: null,
            nextReview: null,
            createdAt: nowUtc,
            updatedAt: nowUtc,
            isActive: true,
            cardType: CardType.reverse,
            frontImageUrl: _backImageUrl,
            frontImagePath: _backImagePath,
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
      print('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPreviewDialog() {
    // Kiểm tra deck có ID không
    if (widget.deck.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Deck chưa có ID. Không thể xem trước.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final tempVocab = Vocabulary(
      id: null,
      deskId: widget.deck.id!,
      front: _frontController.text.trim(),
      back: _backController.text.trim(),
      frontImageUrl: _frontImageUrl,
      frontImagePath: _frontImagePath,
      backImageUrl: _backImageUrl,
      backImagePath: _backImagePath,
      frontExtra: _dynamicState?.frontValues,
      backExtra: _dynamicState?.backValues,
      createdAt: now,
      updatedAt: now,
      cardType: _selectedCardType,
    );

    final accent = Theme.of(context).colorScheme.primary;
    showVocabularyPreviewDialog(
      context: context,
      vocabulary: tempVocab,
      cardType: _selectedCardType,
      accent: accent,
    );
  }

  bool _isFirebaseUrl(String? url) {
    if (url == null) return false;
    return url.contains('firebasestorage.googleapis.com');
  }

  Future<void> _deleteReplacedImages(Vocabulary newVocab) async {
    final storage = CloudStorageService();

    if (_originalFrontImageUrl != null &&
        _originalFrontImageUrl != newVocab.frontImageUrl &&
        _isFirebaseUrl(_originalFrontImageUrl)) {
      await storage.deleteByUrl(_originalFrontImageUrl!);
    }

    if (_originalBackImageUrl != null &&
        _originalBackImageUrl != newVocab.backImageUrl &&
        _isFirebaseUrl(_originalBackImageUrl)) {
      await storage.deleteByUrl(_originalBackImageUrl!);
    }
  }
}

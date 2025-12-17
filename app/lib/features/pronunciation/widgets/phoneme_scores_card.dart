import 'package:flutter/material.dart';

import '../../../core/models/pronunciation_result.dart';

class PhonemeScoresCard extends StatelessWidget {
  final PronunciationResult result;
  final int currentExerciseIndex;
  final bool Function(double score) isPhonemeCorrect;

  const PhonemeScoresCard({
    super.key,
    required this.result,
    required this.currentExerciseIndex,
    required this.isPhonemeCorrect,
  });

  @override
  Widget build(BuildContext context) {
    if (result.words.isEmpty) {
      return _emptyCard(context);
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phoneme scores',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildWordPhonemeRows(context),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Không có dữ liệu phoneme cho từ này.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  /// Xây từng dòng: \"từ vựng\" + phoneme tương ứng
  List<Widget> _buildWordPhonemeRows(BuildContext context) {
    final List<Widget> rows = [];
    final words = result.words;
    final phonemes = result.phonemes;

    for (int wi = 0; wi < words.length; wi++) {
      final word = words[wi];
      final wordPhonemes = phonemes.where((p) => p.wordIndex == wi).toList();
      if (wordPhonemes.isEmpty) continue;

      final isCurrent = wi == currentExerciseIndex;

      rows.add(
        Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800],
                    ),
              ),
              const SizedBox(height: 6),
              _buildPhonemeString(context, wordPhonemes),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      rows.add(
        Text(
          'Không có dữ liệu phoneme cho từ này.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return rows;
  }

  /// Hiển thị phoneme dưới dạng chuỗi ký tự liên tục
  Widget _buildPhonemeString(
      BuildContext context, List<PhonemeResult> wordPhonemes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < wordPhonemes.length; i++) ...[
            _buildPhonemeWithUnderline(wordPhonemes[i]),
            if (i != wordPhonemes.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  /// Xây dựng widget phoneme với gạch chân cách xa chữ
  Widget _buildPhonemeWithUnderline(PhonemeResult phoneme) {
    final wasPronounced = phoneme.score > 0;

    Color textColor;
    Color underlineColor;

    if (!wasPronounced) {
      // Phoneme không được nói: màu đỏ với gạch chân đỏ
      textColor = Colors.red;
      underlineColor = Colors.red;
    } else {
      // Phoneme đúng: màu xanh với gạch chân xanh
      textColor = Colors.green;
      underlineColor = Colors.green;
    }

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Text(
          phoneme.p,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        Positioned(
          bottom: -3,
          left: 0,
          child: Container(
            height: 2.5,
            width: _getTextWidth(phoneme.p, 18, FontWeight.w600),
            color: underlineColor,
          ),
        ),
      ],
    );
  }

  /// Tính toán chiều rộng của text
  double _getTextWidth(String text, double fontSize, FontWeight fontWeight) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
}

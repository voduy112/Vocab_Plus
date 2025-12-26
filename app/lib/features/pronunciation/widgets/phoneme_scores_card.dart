import 'package:flutter/material.dart';

import '../../../core/models/pronunciation_result.dart';

/// Map chuyển đổi ARPAbet sang IPA (International Phonetic Alphabet)
const Map<String, String> _arpaToIpaMap = {
  // Vowels
  'AA': 'ɑ', // father
  'AE': 'æ', // cat
  'AH': 'ʌ', // but
  'AO': 'ɔ', // law
  'AW': 'aʊ', // cow
  'AY': 'aɪ', // buy
  'EH': 'ɛ', // bed
  'ER': 'ɝ', // bird
  'EY': 'eɪ', // bait
  'IH': 'ɪ', // bit
  'IY': 'i', // beat
  'OW': 'oʊ', // boat
  'OY': 'ɔɪ', // boy
  'UH': 'ʊ', // book
  'UW': 'u', // boot
  'AH0': 'ə', // about (schwa, unstressed)
  'AH1': 'ʌ', // but (stressed)
  'AH2': 'ə', // about (schwa, secondary stress)

  // Consonants
  'B': 'b', // bat
  'CH': 'tʃ', // chair
  'D': 'd', // dog
  'DH': 'ð', // this
  'F': 'f', // fan
  'G': 'ɡ', // go
  'HH': 'h', // hat
  'JH': 'dʒ', // joy
  'K': 'k', // cat
  'L': 'l', // leg
  'M': 'm', // man
  'N': 'n', // no
  'NG': 'ŋ', // sing
  'P': 'p', // pen
  'R': 'ɹ', // red
  'S': 's', // sun
  'SH': 'ʃ', // ship
  'T': 't', // top
  'TH': 'θ', // think
  'V': 'v', // van
  'W': 'w', // wet
  'Y': 'j', // yes
  'Z': 'z', // zoo
  'ZH': 'ʒ', // measure
};

/// Chuyển đổi ARPAbet phoneme sang IPA
/// Nếu đã là IPA thì giữ nguyên
String _convertToIpa(String phoneme) {
  if (phoneme.isEmpty) return phoneme;

  // Nếu đã là IPA (chứa ký tự IPA đặc biệt), giữ nguyên
  // Kiểm tra xem có chứa ký tự IPA không
  final ipaChars = RegExp(r'[ɑæʌɔɛɝɪʊuəðθʃʒŋɹ]');
  if (ipaChars.hasMatch(phoneme)) {
    return phoneme; // Đã là IPA
  }

  // Chuyển đổi ARPAbet sang IPA
  final upperPhoneme = phoneme.toUpperCase();
  return _arpaToIpaMap[upperPhoneme] ??
      phoneme; // Nếu không tìm thấy, giữ nguyên
}

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
        crossAxisAlignment:
            CrossAxisAlignment.end, // Align bottom để underline thẳng hàng
        children: [
          for (int i = 0; i < wordPhonemes.length; i++) ...[
            _buildPhonemeWithUnderline(wordPhonemes[i]),
            if (i != wordPhonemes.length - 1)
              const SizedBox(width: 6), // Tăng khoảng cách giữa các phoneme
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

    // Font size và style tối ưu cho IPA
    const double fontSize = 20.0;
    const FontWeight fontWeight =
        FontWeight.w500; // Giảm weight để IPA hiển thị rõ hơn

    // Chuyển đổi phoneme sang IPA trước khi hiển thị
    final ipaPhoneme = _convertToIpa(phoneme.p);

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Text(
          ipaPhoneme,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
            fontFeatures: const [
              // Đảm bảo hỗ trợ Unicode/IPA tốt
            ],
            letterSpacing: 0.5, // Tăng khoảng cách giữa các ký tự để IPA rõ hơn
            height: 1.2, // Line height để không bị cắt
          ),
          textAlign: TextAlign.left,
        ),
        Positioned(
          bottom: -3,
          left: 0,
          child: Container(
            height: 2.5,
            width: _getTextWidth(ipaPhoneme, fontSize, fontWeight),
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
          letterSpacing:
              0.5, // Match với style trong _buildPhonemeWithUnderline
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }
}

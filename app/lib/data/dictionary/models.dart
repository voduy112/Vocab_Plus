import 'dart:convert';

class WordImage {
  final String? url;
  final String? local; // relative to assets/dictionary/
  final String? mime;
  final int? width;
  final int? height;
  final String? title;

  WordImage(
      {this.url, this.local, this.mime, this.width, this.height, this.title});

  factory WordImage.fromJson(Map<String, dynamic> json) => WordImage(
        url: json['url'] as String?,
        local: json['local'] as String?,
        mime: json['mime'] as String?,
        width: json['width'] as int?,
        height: json['height'] as int?,
        title: json['title'] as String?,
      );
}

class ExampleSentence {
  final String? text;
  final String? textVi;

  ExampleSentence({this.text, this.textVi});

  factory ExampleSentence.fromJson(Map<String, dynamic> json) =>
      ExampleSentence(
        text: json['text'] as String?,
        textVi: json['text_vi'] as String?,
      );
}

class Sense {
  final List<String> glosses;
  final List<String> glossesVi;
  final List<ExampleSentence> examples;
  final List<String> synonyms;
  final List<String>? antonyms;

  Sense({
    required this.glosses,
    required this.glossesVi,
    required this.examples,
    required this.synonyms,
    this.antonyms,
  });

  factory Sense.fromJson(Map<String, dynamic> json) => Sense(
        glosses:
            (json['glosses'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        glossesVi:
            (json['glosses_vi'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        examples: (json['examples'] as List?)
                ?.map((e) =>
                    ExampleSentence.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        synonyms: (json['synonyms'] as List?)
                ?.map((e) {
                  if (e is Map) {
                    final m = Map<String, dynamic>.from(e);
                    final w = m['word'];
                    if (w != null) return w.toString();
                  }
                  return e.toString();
                })
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
        antonyms: (json['antonyms'] as List?)
            ?.map((e) {
              if (e is Map) {
                final m = Map<String, dynamic>.from(e);
                final w = m['word'];
                if (w != null) return w.toString();
              }
              return e.toString();
            })
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

class WordForm {
  final String form;
  WordForm({required this.form});
  factory WordForm.fromJson(Map<String, dynamic> json) =>
      WordForm(form: json['form']?.toString() ?? '');
}

class WordEntry {
  final String word;
  final String? wordVi;
  final String? pos;
  final String? langCode;
  final List<WordForm> forms;
  final List<Sense> senses;
  final List<WordImage> images;
  final List<WordSound>? sounds;

  WordEntry({
    required this.word,
    this.wordVi,
    this.pos,
    this.langCode,
    required this.forms,
    required this.senses,
    required this.images,
    this.sounds,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        word: json['word']?.toString() ?? '',
        wordVi: json['word_vi'] as String?,
        pos: json['pos'] as String?,
        langCode: json['lang_code'] as String?,
        forms: (json['forms'] as List?)
                ?.map((e) => WordForm.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        senses: (json['senses'] as List?)
                ?.map((e) => Sense.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        images: (json['images'] as List?)
                ?.map((e) => WordImage.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        sounds: (json['sounds'] as List?)
            ?.map((e) => WordSound.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  static WordEntry? tryParseLine(String line) {
    if (line.trim().isEmpty) return null;
    final decoded = json.decode(line);
    if (decoded is Map<String, dynamic>) {
      return WordEntry.fromJson(decoded);
    }
    return null;
  }
}

class WordSound {
  final String? enpr;
  final String? ipa;
  final String? audio;
  final List<String> tags;

  WordSound({this.enpr, this.ipa, this.audio, required this.tags});

  factory WordSound.fromJson(Map<String, dynamic> json) => WordSound(
        enpr: json['enpr'] as String?,
        ipa: json['ipa'] as String?,
        audio: json['audio'] as String?,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
}

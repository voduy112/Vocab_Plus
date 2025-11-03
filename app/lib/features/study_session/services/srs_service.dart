import '../../../core/models/vocabulary.dart';
import '../../../core/models/srs_choice.dart';

class SrsService {
  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  int _currentLearningStep(int srsLeft, int srsRepetitions) {
    if (srsRepetitions == 0) return 1;
    final int remainder = srsLeft % 1000;
    if (remainder == 2) return 2;
    if (remainder == 1) return 3;
    return 1;
  }

  Map<String, dynamic> simulateSrs(Vocabulary vocab, SrsChoice choice,
      {DateTime? nowOverride}) {
    final DateTime now = nowOverride ?? DateTime.now();

    double ef = vocab.srsEaseFactor;
    int interval = vocab.srsIntervalDays;
    int reps = vocab.srsRepetitions;
    int lapses = vocab.srsLapses;
    int left = vocab.srsLeft;
    int srsType = vocab.srsType; // 0=new, 1=learning, 2=review
    int srsQueue = vocab.srsQueue; // 0=new, 1=learning, 2=review

    final bool isLearning = (srsType == 0 || srsType == 1 || reps == 0);
    DateTime due;
    bool dueIsMinutes = false;

    if (isLearning) {
      final int step = _currentLearningStep(left, reps);
      srsType = 1;
      srsQueue = 1;
      interval = 0;
      reps = reps + 1;

      if (step == 1) {
        if (choice == SrsChoice.again) {
          due = now.add(const Duration(minutes: 1));
          dueIsMinutes = true;
          left = 1000 + 3;
        } else if (choice == SrsChoice.hard) {
          due = now.add(const Duration(minutes: 6));
          dueIsMinutes = true;
          left = 1000 + 3;
        } else if (choice == SrsChoice.good) {
          due = now.add(const Duration(minutes: 10));
          dueIsMinutes = true;
          left = 1000 + 2;
        } else {
          srsType = 2;
          srsQueue = 2;
          interval = 4;
          due = _startOfDay(now.add(Duration(days: interval)));
          left = 0;
        }
      } else if (step == 2) {
        if (choice == SrsChoice.again) {
          due = now.add(const Duration(minutes: 1));
          dueIsMinutes = true;
          left = 1000 + 3;
        } else if (choice == SrsChoice.hard) {
          due = now.add(const Duration(minutes: 8));
          dueIsMinutes = true;
          left = 1000 + 2;
        } else if (choice == SrsChoice.good) {
          srsType = 2;
          srsQueue = 2;
          interval = 1;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        } else {
          srsType = 2;
          srsQueue = 2;
          interval = 4;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        }
      } else {
        if (choice == SrsChoice.again) {
          due = now.add(const Duration(minutes: 1));
          dueIsMinutes = true;
          left = 1000 + 3;
        } else if (choice == SrsChoice.hard) {
          due = _startOfDay(now.add(const Duration(days: 1)));
          dueIsMinutes = false;
          left = 1000 + 1;
        } else if (choice == SrsChoice.good) {
          srsType = 2;
          srsQueue = 2;
          interval = 1;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        } else {
          srsType = 2;
          srsQueue = 2;
          interval = 4;
          due = _startOfDay(now.add(Duration(days: interval)));
          dueIsMinutes = false;
          left = 0;
        }
      }
    } else {
      int q;
      switch (choice) {
        case SrsChoice.again:
          q = 1;
          break;
        case SrsChoice.hard:
          q = 3;
          break;
        case SrsChoice.good:
          q = 4;
          break;
        case SrsChoice.easy:
          q = 5;
          break;
      }

      ef = (ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))).clamp(1.3, 3.0);

      if (choice == SrsChoice.again) {
        lapses = lapses + 1;
        srsType = 1;
        srsQueue = 1;
        interval = 0;
        due = now.add(const Duration(minutes: 1));
        dueIsMinutes = true;
        reps = reps + 1;
        left = 1000 + 2;
      } else if (choice == SrsChoice.hard) {
        if (interval < 1) {
          interval = 1;
        } else {
          interval = (interval * 1.2).round();
          if (interval < 1) interval = 1;
        }
        due = _startOfDay(now.add(Duration(days: interval)));
        dueIsMinutes = false;
        reps = reps + 1;
      } else if (choice == SrsChoice.good) {
        if (interval < 1) {
          interval = 2;
        } else {
          interval = (interval * ef).round();
          if (interval < 1) interval = 1;
        }
        due = _startOfDay(now.add(Duration(days: interval)));
        dueIsMinutes = false;
        reps = reps + 1;
      } else {
        if (interval < 1) {
          interval = 4;
        } else {
          int goodInterval = (interval * ef).round();
          if (goodInterval < 1) goodInterval = 1;
          interval = (goodInterval * 1.3).round();
        }
        if (interval < 1) interval = 1;
        due = _startOfDay(now.add(Duration(days: interval)));
        dueIsMinutes = false;
        reps = reps + 1;
      }
      srsType = (choice == SrsChoice.again) ? 1 : 2;
      srsQueue = (choice == SrsChoice.again) ? 1 : 2;
    }

    return {
      'ef': ef,
      'interval': interval,
      'reps': reps,
      'lapses': lapses,
      'left': left,
      'srsType': srsType,
      'srsQueue': srsQueue,
      'due': due,
      'dueIsMinutes': dueIsMinutes,
    };
  }

  Map<SrsChoice, DateTime> previewChoiceDue(Vocabulary v) {
    final Map<SrsChoice, DateTime> map = {};
    for (final choice in SrsChoice.values) {
      final sim = simulateSrs(v, choice);
      map[choice] = sim['due'] as DateTime;
    }
    return map;
  }

  String _intervalLabel(Duration d) {
    if (d.inMinutes < 1) return '<1ph';
    if (d.inMinutes < 60) {
      final int minutesCeil = (d.inSeconds / 60).ceil();
      return '${minutesCeil}ph';
    }
    if (d.inDays < 1) return '1ng';
    final int daysCeil = (d.inHours / 24).ceil();
    if (daysCeil > 30) {
      final double monthsCeil = ((daysCeil / 30.0) * 10).ceil() / 10.0;
      final String label = monthsCeil.toStringAsFixed(1).replaceAll('.', ',');
      return '${label}th';
    }
    return '${daysCeil}ng';
  }

  Map<SrsChoice, String> previewChoiceLabels(Vocabulary vocab) {
    final preview = previewChoiceDue(vocab);
    final labels = <SrsChoice, String>{};
    final int step = _currentLearningStep(vocab.srsLeft, vocab.srsRepetitions);
    final bool isLearningState =
        (vocab.srsType == 0 || vocab.srsType == 1 || vocab.srsRepetitions == 0);
    preview.forEach((choice, due) {
      final Duration delta = due.difference(DateTime.now());
      if (isLearningState && delta.inMinutes > 0 && delta.inMinutes < 60) {
        switch (choice) {
          case SrsChoice.again:
            labels[choice] = '1ph';
            break;
          case SrsChoice.hard:
            labels[choice] = (step == 2) ? '8ph' : '6ph';
            break;
          case SrsChoice.good:
            labels[choice] = (step == 1) ? '10ph' : '1ng';
            break;
          case SrsChoice.easy:
            labels[choice] = '4ng';
            break;
        }
      } else {
        labels[choice] = _intervalLabel(delta);
      }
    });
    return labels;
  }
}

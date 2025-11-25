import 'dart:io';
import 'dart:typed_data';

/// Utility class for reading WAV file information
class WavInfoReader {
  static Future<Map<String, dynamic>> readWavInfo(File file) async {
    final header = await file.readAsBytes();
    final totalLen = header.length;

    if (totalLen < 44) {
      return {
        'totalLen': totalLen,
        'channels': null,
        'sr': null,
        'bits': null,
        'byteRate': null,
        'dataSize': null,
        'durationMsFromPayload': 0,
        'durationMsFromData': 0,
      };
    }

    String fourcc(List<int> b, int off) =>
        String.fromCharCodes(b.sublist(off, off + 4));

    int idx = 12;
    int? sampleRate;
    int? byteRate;
    int? numChannels;
    int? bitsPerSample;
    int? dataSize;

    while (idx + 8 <= totalLen) {
      final chunkId = fourcc(header, idx);
      final chunkSize = ByteData.sublistView(
        Uint8List.fromList(header),
        idx + 4,
        idx + 8,
      ).getUint32(0, Endian.little);

      final next = idx + 8 + chunkSize;

      if (chunkId == 'fmt ') {
        if ((idx + 8 + 16) <= totalLen) {
          final bd = ByteData.sublistView(
            Uint8List.fromList(header),
            idx + 8,
            idx + 8 + 16,
          );
          /* format */ bd.getUint16(0, Endian.little);
          final valueNumChannels = bd.getUint16(2, Endian.little);
          numChannels = valueNumChannels;
          sampleRate = bd.getUint32(4, Endian.little);
          byteRate = bd.getUint32(8, Endian.little);
          final blockAlign = bd.getUint16(12, Endian.little);
          if (blockAlign > 0 && valueNumChannels > 0) {
            bitsPerSample = blockAlign * 8 ~/ valueNumChannels;
          }
        }
      } else if (chunkId == 'data') {
        dataSize = chunkSize;
      }

      if (next <= idx || next > totalLen + 8) break;
      idx = next;
    }

    int durationMsFromPayload = 0;
    final payloadBytes = totalLen > 44 ? (totalLen - 44) : 0;
    if (payloadBytes > 0 &&
        sampleRate != null &&
        numChannels != null &&
        bitsPerSample != null &&
        sampleRate > 0 &&
        numChannels > 0 &&
        bitsPerSample > 0) {
      final sr = sampleRate;
      final ch = numChannels;
      final bps = bitsPerSample;
      final denom = sr * ch * (bps / 8);
      durationMsFromPayload = ((payloadBytes / denom) * 1000).round();
    }

    int durationMsFromData = 0;
    if (dataSize != null && byteRate != null && byteRate > 0) {
      final ds = dataSize;
      final br = byteRate;
      durationMsFromData = ((ds / br) * 1000).round();
    }

    return {
      'totalLen': totalLen,
      'channels': numChannels,
      'sr': sampleRate,
      'bits': bitsPerSample,
      'byteRate': byteRate,
      'dataSize': dataSize,
      'durationMsFromPayload': durationMsFromPayload,
      'durationMsFromData': durationMsFromData,
    };
  }
}

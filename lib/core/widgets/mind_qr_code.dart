import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';

/// Immutable QR matrix produced by [MindQrCodeEncoder].
@immutable
class MindQrMatrix {
  const MindQrMatrix({
    required this.version,
    required this.size,
    required this.modules,
  });

  final int version;
  final int size;
  final List<List<bool>> modules;

  bool isDark(int row, int col) => modules[row][col];
}

/// Pure-Dart ISO/IEC 18004 Byte-mode QR Code encoder (Versions 1–40, Error
/// Correction Level L, max 2,953 UTF-8 bytes) with zero external packages.
abstract final class MindQrCodeEncoder {
  static const int maxByteCapacity = 2953;

  // Per-version Level L RS spec: [ecCodewordsPerBlock, totalBlocks]
  static const List<List<int>> _levelLSpecs = [
    [7, 1], // V1
    [10, 1], // V2
    [15, 1], // V3
    [20, 1], // V4
    [26, 1], // V5
    [18, 2], // V6
    [20, 2], // V7
    [24, 2], // V8
    [30, 2], // V9
    [18, 4], // V10
    [20, 4], // V11
    [24, 4], // V12
    [26, 4], // V13
    [30, 4], // V14
    [22, 6], // V15
    [24, 6], // V16
    [28, 6], // V17
    [30, 6], // V18
    [28, 7], // V19
    [28, 8], // V20
    [28, 8], // V21
    [28, 9], // V22
    [30, 9], // V23
    [30, 10], // V24
    [26, 12], // V25
    [28, 12], // V26
    [30, 12], // V27
    [30, 13], // V28
    [30, 14], // V29
    [30, 15], // V30
    [30, 16], // V31
    [30, 17], // V32
    [30, 18], // V33
    [30, 19], // V34
    [30, 19], // V35
    [30, 20], // V36
    [30, 21], // V37
    [30, 22], // V38
    [30, 24], // V39
    [30, 25], // V40
  ];

  // ISO/IEC 18004 Annex E alignment pattern center coordinates per version (1..40).
  static const List<List<int>> _alignmentCenters = [
    [], // V1
    [6, 18], // V2
    [6, 22], // V3
    [6, 26], // V4
    [6, 30], // V5
    [6, 34], // V6
    [6, 22, 38], // V7
    [6, 24, 42], // V8
    [6, 26, 46], // V9
    [6, 28, 50], // V10
    [6, 30, 54], // V11
    [6, 32, 58], // V12
    [6, 34, 62], // V13
    [6, 26, 46, 66], // V14
    [6, 26, 48, 70], // V15
    [6, 26, 50, 74], // V16
    [6, 30, 54, 78], // V17
    [6, 30, 56, 82], // V18
    [6, 30, 58, 86], // V19
    [6, 34, 62, 90], // V20
    [6, 28, 50, 72, 94], // V21
    [6, 26, 50, 74, 98], // V22
    [6, 30, 54, 78, 102], // V23
    [6, 28, 54, 80, 106], // V24
    [6, 32, 58, 84, 110], // V25
    [6, 30, 58, 86, 114], // V26
    [6, 34, 62, 90, 118], // V27
    [6, 26, 50, 74, 98, 122], // V28
    [6, 30, 54, 78, 102, 126], // V29
    [6, 26, 52, 78, 104, 130], // V30
    [6, 30, 56, 82, 108, 134], // V31
    [6, 34, 60, 86, 112, 138], // V32
    [6, 30, 58, 86, 114, 142], // V33
    [6, 34, 62, 90, 118, 146], // V34
    [6, 30, 54, 78, 102, 126, 150], // V35
    [6, 24, 50, 76, 102, 128, 154], // V36
    [6, 28, 54, 80, 106, 132, 158], // V37
    [6, 32, 58, 84, 110, 136, 162], // V38
    [6, 26, 54, 82, 110, 138, 166], // V39
    [6, 30, 58, 86, 114, 142, 170], // V40
  ];

  // Exact GF(256) log/antilog lookup with primitive polynomial 0x11D.
  static final Uint8List _exp = _buildExp();
  static final Uint8List _log = _buildLog(_exp);

  static Uint8List _buildExp() {
    final table = Uint8List(256);
    var v = 1;
    for (var i = 0; i < 255; i++) {
      table[i] = v;
      v <<= 1;
      if (v >= 256) v ^= 0x11D;
    }
    table[255] = table[0];
    return table;
  }

  static Uint8List _buildLog(Uint8List exp) {
    final table = Uint8List(256);
    for (var i = 0; i < 255; i++) {
      table[exp[i]] = i;
    }
    return table;
  }

  static int _gfMul(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return _exp[(_log[a] + _log[b]) % 255];
  }

  static List<int> _rsGenerator(int ecCount) {
    var poly = <int>[1];
    for (var i = 0; i < ecCount; i++) {
      poly = _polyMul(poly, [1, _exp[i]]);
    }
    return poly;
  }

  static List<int> _polyMul(List<int> p, List<int> q) {
    final res = List<int>.filled(p.length + q.length - 1, 0);
    for (var i = 0; i < p.length; i++) {
      for (var j = 0; j < q.length; j++) {
        res[i + j] ^= _gfMul(p[i], q[j]);
      }
    }
    return res;
  }

  static List<int> _rsRemainder(List<int> data, int ecCount) {
    final gen = _rsGenerator(ecCount);
    final rem = List<int>.filled(ecCount, 0);
    for (final byte in data) {
      final factor = byte ^ rem[0];
      for (var i = 0; i < ecCount - 1; i++) {
        rem[i] = rem[i + 1] ^ _gfMul(gen[i + 1], factor);
      }
      rem[ecCount - 1] = _gfMul(gen[ecCount], factor);
    }
    return rem;
  }

  /// Exposes the exact byte-mode data capacity (Level L) for testing and UI.
  static int byteCapacityForVersion(int version) {
    final template = _FunctionGrid.build(version);
    final spec = _levelLSpecs[version - 1];
    final totalRawCodewords = template.dataModulesCount ~/ 8;
    final totalDataCodewords = totalRawCodewords - spec[0] * spec[1];
    final headerBits = version <= 9 ? 12 : 20;
    return ((totalDataCodewords * 8 - headerBits) ~/ 8);
  }

  /// Encodes UTF-8 text into a [MindQrMatrix] at Error Correction Level L,
  /// returning `null` if [data] exceeds [maxByteCapacity] UTF-8 bytes.
  static MindQrMatrix? encode(String data) {
    final payloadBytes = utf8.encode(data);
    if (payloadBytes.length > maxByteCapacity) {
      return null;
    }

    int? selectedVersion;
    _FunctionGrid? grid;
    for (var v = 1; v <= 40; v++) {
      if (payloadBytes.length <= byteCapacityForVersion(v)) {
        selectedVersion = v;
        grid = _FunctionGrid.build(v);
        break;
      }
    }
    if (selectedVersion == null || grid == null) {
      return null;
    }

    final spec = _levelLSpecs[selectedVersion - 1];
    final ecPerBlock = spec[0];
    final totalBlocks = spec[1];
    final totalRawCodewords = grid.dataModulesCount ~/ 8;
    final totalDataCodewords = totalRawCodewords - ecPerBlock * totalBlocks;

    // 1. Build byte-mode data bitstream (mode 0100 + count + bytes + terminator + pad)
    final bits = <int>[];
    void pushBits(int val, int count) {
      for (var i = count - 1; i >= 0; i--) {
        bits.add((val >> i) & 1);
      }
    }

    pushBits(0x4, 4); // Byte mode indicator
    pushBits(payloadBytes.length, selectedVersion <= 9 ? 8 : 16);
    for (final b in payloadBytes) {
      pushBits(b, 8);
    }
    final maxDataBits = totalDataCodewords * 8;
    final terminatorLen = math.min(4, maxDataBits - bits.length);
    pushBits(0, terminatorLen);
    while (bits.length % 8 != 0) {
      bits.add(0);
    }
    const padBytes = [0xEC, 0x11];
    var padIdx = 0;
    while (bits.length < maxDataBits) {
      pushBits(padBytes[padIdx % 2], 8);
      padIdx++;
    }

    final dataCodewords = List<int>.generate(totalDataCodewords, (i) {
      var byte = 0;
      for (var b = 0; b < 8; b++) {
        byte = (byte << 1) | bits[i * 8 + b];
      }
      return byte;
    });

    // 2. Partition into Group 1 / Group 2 RS blocks & compute EC bytes
    final numLongBlocks = totalDataCodewords % totalBlocks;
    final shortDataLen = totalDataCodewords ~/ totalBlocks;
    final dataBlocks = <List<int>>[];
    final ecBlocks = <List<int>>[];
    var offset = 0;
    for (var i = 0; i < totalBlocks; i++) {
      final len = shortDataLen + (i >= totalBlocks - numLongBlocks ? 1 : 0);
      final blockData = dataCodewords.sublist(offset, offset + len);
      offset += len;
      dataBlocks.add(blockData);
      ecBlocks.add(_rsRemainder(blockData, ecPerBlock));
    }

    // 3. Interleave data and EC codewords
    final interleaved = <int>[];
    final maxDataLen = shortDataLen + (numLongBlocks > 0 ? 1 : 0);
    for (var col = 0; col < maxDataLen; col++) {
      for (var b = 0; b < totalBlocks; b++) {
        if (col < dataBlocks[b].length) {
          interleaved.add(dataBlocks[b][col]);
        }
      }
    }
    for (var col = 0; col < ecPerBlock; col++) {
      for (var b = 0; b < totalBlocks; b++) {
        interleaved.add(ecBlocks[b][col]);
      }
    }

    final streamBits = <bool>[];
    for (final cw in interleaved) {
      for (var bit = 7; bit >= 0; bit--) {
        streamBits.add(((cw >> bit) & 1) == 1);
      }
    }

    // 4. Zig-zag data placement
    final size = grid.size;
    final baseModules = List<List<bool>>.generate(
      size,
      (r) => List<bool>.from(grid!.modules[r]),
    );

    var bitIndex = 0;
    var upward = true;
    for (var rightCol = size - 1; rightCol >= 1; rightCol -= 2) {
      if (rightCol == 6) rightCol = 5;
      for (var step = 0; step < size; step++) {
        final row = upward ? (size - 1 - step) : step;
        for (var dx = 0; dx < 2; dx++) {
          final col = rightCol - dx;
          if (!grid.isFunction[row][col]) {
            baseModules[row][col] =
                bitIndex < streamBits.length ? streamBits[bitIndex] : false;
            bitIndex++;
          }
        }
      }
      upward = !upward;
    }

    // 5. Evaluate masks 0..7 and select minimum ISO/IEC 18004 penalty
    var bestMask = 0;
    var bestPenalty = 1 << 30;
    List<List<bool>>? bestModules;

    for (var mask = 0; mask < 8; mask++) {
      final candidate = List<List<bool>>.generate(
        size,
        (r) => List<bool>.from(baseModules[r]),
      );
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (!grid.isFunction[r][c] && _maskBit(mask, r, c)) {
            candidate[r][c] = !candidate[r][c];
          }
        }
      }
      _applyFormatInfo(candidate, mask);
      if (selectedVersion >= 7) {
        _applyVersionInfo(candidate, selectedVersion);
      }

      final penalty = _computePenalty(candidate);
      if (penalty < bestPenalty) {
        bestPenalty = penalty;
        bestMask = mask;
        bestModules = candidate;
      }
    }

    assert(bestMask >= 0 && bestModules != null);
    return MindQrMatrix(
      version: selectedVersion,
      size: size,
      modules: bestModules!,
    );
  }

  static bool _maskBit(int mask, int r, int c) {
    return switch (mask) {
      0 => (r + c) % 2 == 0,
      1 => r % 2 == 0,
      2 => c % 3 == 0,
      3 => (r + c) % 3 == 0,
      4 => ((r ~/ 2) + (c ~/ 3)) % 2 == 0,
      5 => ((r * c) % 2) + ((r * c) % 3) == 0,
      6 => (((r * c) % 2) + ((r * c) % 3)) % 2 == 0,
      _ => (((r + c) % 2) + ((r * c) % 3)) % 2 == 0,
    };
  }

  static void _applyFormatInfo(List<List<bool>> m, int mask) {
    // Error Correction Level L = 01 (2 bits) followed by 3-bit mask.
    final data = (1 << 3) | mask;
    var rem = data;
    for (var i = 0; i < 10; i++) {
      rem = (rem << 1) ^ (((rem >> 9) & 1) * 0x537);
    }
    final bits = ((data << 10) | rem) ^ 0x5412;

    bool bit(int i) => ((bits >> i) & 1) == 1;
    final size = m.length;

    // Top-left horizontal & vertical
    for (var i = 0; i <= 5; i++) {
      m[8][i] = bit(14 - i);
    }
    m[8][7] = bit(8);
    m[8][8] = bit(7);
    m[7][8] = bit(6);
    for (var i = 9; i < 15; i++) {
      m[14 - i][8] = bit(14 - i);
    }

    // Top-right horizontal copy: bit 0 (LSB) at (8, size-1) .. bit 7 at (8, size-8)
    for (var i = 0; i < 8; i++) {
      m[8][size - 1 - i] = bit(i);
    }
    // Bottom-left vertical copy: bit 14 (MSB) at (size-1, 8) .. bit 8 at (size-7, 8)
    for (var i = 0; i < 7; i++) {
      m[size - 1 - i][8] = bit(14 - i);
    }
  }

  static void _applyVersionInfo(List<List<bool>> m, int version) {
    var rem = version;
    for (var i = 0; i < 12; i++) {
      rem = (rem << 1) ^ (((rem >> 11) & 1) * 0x1F25);
    }
    final bits = (version << 12) | rem;
    final size = m.length;

    for (var i = 0; i < 18; i++) {
      final bit = ((bits >> i) & 1) == 1;
      final a = size - 11 + (i % 3);
      final b = i ~/ 3;
      m[b][a] = bit;
      m[a][b] = bit;
    }
  }

  static int _computePenalty(List<List<bool>> m) {
    final size = m.length;
    var penalty = 0;

    // Rule 1: 5+ consecutive same-color modules in rows/cols
    for (var r = 0; r < size; r++) {
      var runColor = m[r][0];
      var runLen = 1;
      for (var c = 1; c < size; c++) {
        if (m[r][c] == runColor) {
          runLen++;
        } else {
          if (runLen >= 5) penalty += 3 + (runLen - 5);
          runColor = m[r][c];
          runLen = 1;
        }
      }
      if (runLen >= 5) penalty += 3 + (runLen - 5);
    }
    for (var c = 0; c < size; c++) {
      var runColor = m[0][c];
      var runLen = 1;
      for (var r = 1; r < size; r++) {
        if (m[r][c] == runColor) {
          runLen++;
        } else {
          if (runLen >= 5) penalty += 3 + (runLen - 5);
          runColor = m[r][c];
          runLen = 1;
        }
      }
      if (runLen >= 5) penalty += 3 + (runLen - 5);
    }

    // Rule 2: 2x2 same-color blocks
    for (var r = 0; r < size - 1; r++) {
      for (var c = 0; c < size - 1; c++) {
        final v = m[r][c];
        if (m[r][c + 1] == v && m[r + 1][c] == v && m[r + 1][c + 1] == v) {
          penalty += 3;
        }
      }
    }

    // Rule 3: 1:1:3:1:1 finder-like ratios with 4 light modules on either side
    for (var r = 0; r < size; r++) {
      for (var c = 0; c <= size - 11; c++) {
        if (_isFinderLikeRow(m, r, c) || _isFinderLikeRowRev(m, r, c)) {
          penalty += 40;
        }
        if (_isFinderLikeCol(m, r, c) || _isFinderLikeColRev(m, r, c)) {
          penalty += 40;
        }
      }
    }

    // Rule 4: dark ratio balance around 50%
    var dark = 0;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (m[r][c]) dark++;
      }
    }
    final pct = (dark * 100) / (size * size);
    final prev5 = (pct / 5).floor() * 5;
    final next5 = prev5 + 5;
    final dev = math.min((prev5 - 50).abs(), (next5 - 50).abs()) ~/ 5;
    penalty += dev * 10;

    return penalty;
  }

  static bool _isFinderLikeRow(List<List<bool>> m, int r, int c) {
    return m[r][c] &&
        !m[r][c + 1] &&
        m[r][c + 2] &&
        m[r][c + 3] &&
        m[r][c + 4] &&
        !m[r][c + 5] &&
        m[r][c + 6] &&
        !m[r][c + 7] &&
        !m[r][c + 8] &&
        !m[r][c + 9] &&
        !m[r][c + 10];
  }

  static bool _isFinderLikeRowRev(List<List<bool>> m, int r, int c) {
    return !m[r][c] &&
        !m[r][c + 1] &&
        !m[r][c + 2] &&
        !m[r][c + 3] &&
        m[r][c + 4] &&
        !m[r][c + 5] &&
        m[r][c + 6] &&
        m[r][c + 7] &&
        m[r][c + 8] &&
        !m[r][c + 9] &&
        m[r][c + 10];
  }

  static bool _isFinderLikeCol(List<List<bool>> m, int c, int r) {
    return m[r][c] &&
        !m[r + 1][c] &&
        m[r + 2][c] &&
        m[r + 3][c] &&
        m[r + 4][c] &&
        !m[r + 5][c] &&
        m[r + 6][c] &&
        !m[r + 7][c] &&
        !m[r + 8][c] &&
        !m[r + 9][c] &&
        !m[r + 10][c];
  }

  static bool _isFinderLikeColRev(List<List<bool>> m, int c, int r) {
    return !m[r][c] &&
        !m[r + 1][c] &&
        !m[r + 2][c] &&
        !m[r + 3][c] &&
        m[r + 4][c] &&
        !m[r + 5][c] &&
        m[r + 6][c] &&
        m[r + 7][c] &&
        m[r + 8][c] &&
        !m[r + 9][c] &&
        m[r + 10][c];
  }
}

class _FunctionGrid {
  _FunctionGrid._(
    this.size,
    this.modules,
    this.isFunction,
    this.dataModulesCount,
  );

  final int size;
  final List<List<bool>> modules;
  final List<List<bool>> isFunction;
  final int dataModulesCount;

  static _FunctionGrid build(int version) {
    final size = 17 + 4 * version;
    final modules = List.generate(size, (_) => List<bool>.filled(size, false));
    final isFunc = List.generate(size, (_) => List<bool>.filled(size, false));

    void setFunc(int r, int c, bool dark) {
      modules[r][c] = dark;
      isFunc[r][c] = true;
    }

    void drawFinder(int top, int left) {
      for (var dy = -1; dy <= 7; dy++) {
        for (var dx = -1; dx <= 7; dx++) {
          final r = top + dy;
          final c = left + dx;
          if (r < 0 || r >= size || c < 0 || c >= size) continue;
          final inSquare = dy >= 0 && dy <= 6 && dx >= 0 && dx <= 6;
          if (!inSquare) {
            setFunc(r, c, false); // separator
          } else {
            final onOuter = dy == 0 || dy == 6 || dx == 0 || dx == 6;
            final onInner = dy >= 2 && dy <= 4 && dx >= 2 && dx <= 4;
            setFunc(r, c, onOuter || onInner);
          }
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(0, size - 7);
    drawFinder(size - 7, 0);

    // Timing patterns
    for (var i = 8; i < size - 8; i++) {
      final dark = i.isEven;
      setFunc(6, i, dark);
      setFunc(i, 6, dark);
    }

    // Alignment patterns
    final centers = MindQrCodeEncoder._alignmentCenters[version - 1];
    for (var i = 0; i < centers.length; i++) {
      for (var j = 0; j < centers.length; j++) {
        // Skip the 3 corners occupied by finder patterns
        final isCorner = (i == 0 && j == 0) ||
            (i == 0 && j == centers.length - 1) ||
            (i == centers.length - 1 && j == 0);
        if (isCorner) continue;
        final cr = centers[i];
        final cc = centers[j];
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            final onBorder = dy.abs() == 2 || dx.abs() == 2;
            final isCenter = dy == 0 && dx == 0;
            setFunc(cr + dy, cc + dx, onBorder || isCenter);
          }
        }
      }
    }

    // Dark module always at (size - 8, 8)
    setFunc(size - 8, 8, true);

    // Reserve Format Information slots
    for (var i = 0; i <= 8; i++) {
      isFunc[8][i] = true;
      isFunc[i][8] = true;
    }
    for (var i = 0; i < 8; i++) {
      isFunc[8][size - 1 - i] = true;
    }
    for (var i = 0; i < 7; i++) {
      isFunc[size - 1 - i][8] = true;
    }

    // Reserve Version Information slots (V >= 7)
    if (version >= 7) {
      for (var a = size - 11; a < size - 8; a++) {
        for (var b = 0; b < 6; b++) {
          isFunc[b][a] = true;
          isFunc[a][b] = true;
        }
      }
    }

    var remaining = 0;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (!isFunc[r][c]) remaining++;
      }
    }

    return _FunctionGrid._(size, modules, isFunc, remaining);
  }
}

/// High-contrast camera-scannable QR widget rendered onto a strict white quiet
/// zone (intentional optical scanner contrast exception) framed inside [MindTokens].
class MindQrCodeView extends StatelessWidget {
  const MindQrCodeView({
    super.key,
    required this.data,
    required this.semanticLabel,
    this.overflowNotice,
    this.size = 200.0,
  });

  final String data;
  final String semanticLabel;
  final String? overflowNotice;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final matrix = MindQrCodeEncoder.encode(data);

    if (matrix == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: BorderRadius.circular(tokens.chipRadius),
          border: Border.all(color: tokens.line),
        ),
        child: Row(
          children: [
            Icon(Icons.qr_code_2_outlined, size: 18, color: tokens.ink2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                overflowNotice ??
                    'Payload exceeds QR capacity; share the encrypted text code instead.',
                style: TextStyle(fontSize: 12, color: tokens.ink2, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Pure optical white quiet zone required by ISO/IEC 18004 scanners.
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.line),
          ),
          child: CustomPaint(
            size: Size.square(size),
            painter: _MindQrPainter(matrix),
          ),
        ),
      ),
    );
  }
}

class _MindQrPainter extends CustomPainter {
  const _MindQrPainter(this.matrix);

  final MindQrMatrix matrix;

  @override
  void paint(Canvas canvas, Size size) {
    final quietModules = 2;
    final total = matrix.size + quietModules * 2;
    final cell = size.width / total;

    final darkPaint = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;

    for (var r = 0; r < matrix.size; r++) {
      for (var c = 0; c < matrix.size; c++) {
        if (matrix.isDark(r, c)) {
          canvas.drawRect(
            Rect.fromLTWH(
              (c + quietModules) * cell,
              (r + quietModules) * cell,
              cell + 0.2,
              cell + 0.2,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MindQrPainter oldDelegate) =>
      oldDelegate.matrix != matrix;
}

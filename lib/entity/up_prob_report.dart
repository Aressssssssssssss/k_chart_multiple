// up_prob_report.dart
import '../flutter_k_chart.dart'; // 为了用 SecondaryState

class UpProbReport {
  final double? mainUp; // 主图上涨概率 [0,1]，null 表示当前主图无定义
  final Map<SecondaryState, double?> secondaryUps; // 每个副图的上涨概率
  final int index; // 当前bar索引（一般=可视区最后一根）
  final int? time; // 当前bar时间戳(毫秒)

  const UpProbReport({
    required this.index,
    this.time,
    this.mainUp,
    required this.secondaryUps,
  });

  bool almostEquals(UpProbReport other, {double eps = 1e-3}) {
    if (!_almostEq(mainUp, other.mainUp, eps)) return false;
    if (secondaryUps.length != other.secondaryUps.length) return false;
    for (final e in secondaryUps.entries) {
      if (!_almostEq(e.value, other.secondaryUps[e.key], eps)) return false;
    }
    return true;
  }

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('UpProbReport(')
      ..write('index: $index, ')
      ..write('time: ${time ?? '-'}, ')
      ..write('mainUp: ${_formatProb(mainUp)}, ')
      ..write('secondaryUps: {');

    final entries = secondaryUps.entries
        .map((e) =>
            '${e.key.toString().split('.').last}: ${_formatProb(e.value)}')
        .join(', ');
    buffer
      ..write(entries)
      ..write('})');
    return buffer.toString();
  }
}

bool _almostEq(double? a, double? b, double eps) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return (a - b).abs() <= eps;
}

String _formatProb(double? value) {
  if (value == null) return '—';
  return '${(value * 100).toStringAsFixed(2)}%';
}

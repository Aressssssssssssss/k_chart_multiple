import 'dart:math' as math;

import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

/// MA 金叉（短 MA 从下向上穿过中 MA）；死叉反之
class MaCrossSignalProvider implements MainSignalProvider {
  @override
  bool isBuy(List<KLineEntity> allData, int index) {
    if (index < 1) return false;
    final prev = allData[index - 1];
    final cur = allData[index];
    final pMA = prev.maValueList;
    final cMA = cur.maValueList;
    if (pMA == null || cMA == null || pMA.length < 2 || cMA.length < 2) {
      return false;
    }
    return pMA[0] <= pMA[1] && cMA[0] > cMA[1];
  }

  @override
  bool isSell(List<KLineEntity> allData, int index) {
    if (index < 1) return false;
    final prev = allData[index - 1];
    final cur = allData[index];
    final pMA = prev.maValueList;
    final cMA = cur.maValueList;
    if (pMA == null || cMA == null || pMA.length < 2 || cMA.length < 2) {
      return false;
    }
    return pMA[0] >= pMA[1] && cMA[0] < cMA[1];
  }

  @override
  double? upProb(List<KLineEntity> all, int i) {
    final c = all[i];
    final ma = c.maValueList;
    if (ma == null || ma.length < 2) return null;
    final fast = ma[0], slow = ma[1];
    final base = (c.close.abs() <= 1e-12) ? 1.0 : c.close.abs();
    final ratio = (fast - slow) / base; // 相对差
    // 放大一点再 sigmoid（越正越接近1）
    final s = (ratio * 50.0).clamp(-10.0, 10.0);
    final p = 1.0 / (1.0 + math.exp(-s));
    return p.clamp(0.0, 1.0);
  }
}

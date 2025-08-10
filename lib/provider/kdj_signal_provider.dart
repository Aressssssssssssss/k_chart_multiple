// kdj_signal_provider.dart
import 'dart:math' as math;
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class KdjSignalProvider implements SecondarySignalProvider {
  @override
  bool isBuy(List<KLineEntity> all, int i) {
    if (i < 1) return false;
    final p = all[i - 1], c = all[i];
    if (p.k == null || p.d == null || c.k == null || c.d == null) return false;
    return p.k! <= p.d! && c.k! > c.d!;
  }

  @override
  bool isSell(List<KLineEntity> all, int i) {
    if (i < 1) return false;
    final p = all[i - 1], c = all[i];
    if (p.k == null || p.d == null || c.k == null || c.d == null) return false;
    return p.k! >= p.d! && c.k! < c.d!;
  }

  @override
  double? upProb(List<KLineEntity> all, int i) {
    final c = all[i];
    final k = c.k, d = c.d;
    if (k == null || d == null) return null;
    final diff = (k - d); // 负表示偏空，正偏多
    final s = diff / 10.0; // 缩放，10 可按经验调整
    final p = 1.0 / (1.0 + math.exp(-s)); // sigmoid
    return p.clamp(0.0, 1.0);
  }
}

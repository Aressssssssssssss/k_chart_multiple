// provider/kdj_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class KdjSignalProvider implements SecondarySignalProvider {
  const KdjSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.k) || !isF(p.d) || !isF(c.k) || !isF(c.d)) return false;
    return p.k! <= p.d! && c.k! > c.d!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.k) || !isF(p.d) || !isF(c.k) || !isF(c.d)) return false;
    return p.k! >= p.d! && c.k! < c.d!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];
    final kd = (isF(c.k) && isF(c.d)) ? (c.k! - c.d!) : 0.0; // [-100,100]
    final base = clamp01((kd + 100) / 200);
    // 轻微加入K相对50的偏离
    final kBias = isF(c.k) ? ((c.k! - 50) / 100).clamp(-0.2, 0.2) : 0.0;
    return clamp01(base + kBias);
  }
}

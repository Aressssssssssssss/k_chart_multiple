// provider/stoch_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class StochSignalProvider implements SecondarySignalProvider {
  const StochSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.stochK) || !isF(p.stochD) || !isF(c.stochK) || !isF(c.stochD))
      return false;
    return p.stochK! <= p.stochD! && c.stochK! > c.stochD!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.stochK) || !isF(p.stochD) || !isF(c.stochK) || !isF(c.stochD))
      return false;
    return p.stochK! >= p.stochD! && c.stochK! < c.stochD!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];
    final diff =
        (isF(c.stochK) && isF(c.stochD)) ? (c.stochK! - c.stochD!) : 0.0;
    final base = clamp01((diff + 100) / 200);
    final bias =
        isF(c.stochK) ? ((c.stochK! - 50) / 100).clamp(-0.2, 0.2) : 0.0;
    return clamp01(base + bias);
  }
}

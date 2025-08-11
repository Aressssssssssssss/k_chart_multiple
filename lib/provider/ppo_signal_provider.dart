// provider/ppo_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class PpoSignalProvider implements SecondarySignalProvider {
  const PpoSignalProvider();
  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.ppo) || !isF(p.ppoSignal) || !isF(c.ppo) || !isF(c.ppoSignal))
      return false;
    return p.ppo! <= p.ppoSignal! && c.ppo! > c.ppoSignal!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.ppo) || !isF(p.ppoSignal) || !isF(c.ppo) || !isF(c.ppoSignal))
      return false;
    return p.ppo! >= p.ppoSignal! && c.ppo! < c.ppoSignal!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final mm = minMax(a, i,
        (e) => (isF(e.ppo) && isF(e.ppoSignal)) ? e.ppo! - e.ppoSignal! : null);
    final diff = (isF(a[i].ppo) && isF(a[i].ppoSignal))
        ? a[i].ppo! - a[i].ppoSignal!
        : 0.0;
    return norm01Linear(diff, mm.min, mm.max);
  }
}

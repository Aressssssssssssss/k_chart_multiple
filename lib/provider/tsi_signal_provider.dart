// provider/tsi_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class TsiSignalProvider implements SecondarySignalProvider {
  const TsiSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.tsi) || !isF(p.tsiSignal) || !isF(c.tsi) || !isF(c.tsiSignal))
      return false;
    return p.tsi! <= p.tsiSignal! && c.tsi! > c.tsiSignal!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.tsi) || !isF(p.tsiSignal) || !isF(c.tsi) || !isF(c.tsiSignal))
      return false;
    return p.tsi! >= p.tsiSignal! && c.tsi! < c.tsiSignal!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final mm = minMax(a, i,
        (e) => (isF(e.tsi) && isF(e.tsiSignal)) ? e.tsi! - e.tsiSignal! : null);
    final diff = (isF(a[i].tsi) && isF(a[i].tsiSignal))
        ? a[i].tsi! - a[i].tsiSignal!
        : 0.0;
    return norm01Linear(diff, mm.min, mm.max);
  }
}

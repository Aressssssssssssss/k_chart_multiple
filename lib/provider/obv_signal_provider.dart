// provider/obv_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class ObvSignalProvider implements SecondarySignalProvider {
  const ObvSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.obv) || !isF(p.obvEma) || !isF(c.obv) || !isF(c.obvEma))
      return false;
    return p.obv! <= p.obvEma! && c.obv! > c.obvEma!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.obv) || !isF(p.obvEma) || !isF(c.obv) || !isF(c.obvEma))
      return false;
    return p.obv! >= p.obvEma! && c.obv! < c.obvEma!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final mm = minMax(
        a, i, (e) => (isF(e.obv) && isF(e.obvEma)) ? e.obv! - e.obvEma! : null);
    final diff =
        (isF(a[i].obv) && isF(a[i].obvEma)) ? a[i].obv! - a[i].obvEma! : 0.0;
    return norm01Linear(diff, mm.min, mm.max);
  }
}

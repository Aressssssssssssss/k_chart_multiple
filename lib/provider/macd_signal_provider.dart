// provider/macd_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class MacdSignalProvider implements SecondarySignalProvider {
  const MacdSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.dif) || !isF(p.dea) || !isF(c.dif) || !isF(c.dea)) return false;
    return p.dif! <= p.dea! && c.dif! > c.dea!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.dif) || !isF(p.dea) || !isF(c.dif) || !isF(c.dea)) return false;
    return p.dif! >= p.dea! && c.dif! < c.dea!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final hist = a[i].osma ??
        ((isF(a[i].dif) && isF(a[i].dea)) ? a[i].dif! - a[i].dea! : 0.0);
    final mm = minMax(a, i,
        (e) => e.osma ?? ((isF(e.dif) && isF(e.dea)) ? e.dif! - e.dea! : null));
    var p = norm01Linear(hist, mm.min, mm.max);
    // DIF>DEA 时给微弱加分
    if (isF(a[i].dif) && isF(a[i].dea) && a[i].dif! > a[i].dea!)
      p = (p + 0.05).clamp(0, 1);
    return p;
  }
}

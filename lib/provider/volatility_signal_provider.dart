// provider/volatility_signal_provider.dart  (VOLI: volIndicator)
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class VolatilitySignalProvider implements SecondarySignalProvider {
  const VolatilitySignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].volIndicator) || !isF(a[i].volIndicator))
      return false;
    return a[i].volIndicator! <= a[i - 1].volIndicator! &&
        a[i].close > a[i - 1].close;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].volIndicator) || !isF(a[i].volIndicator))
      return false;
    return a[i].volIndicator! >= a[i - 1].volIndicator! &&
        a[i].close < a[i - 1].close;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final p = a[i > 0 ? i - 1 : i], c = a[i];
    final calm = (isF(p.volIndicator) &&
            isF(c.volIndicator) &&
            c.volIndicator! <= p.volIndicator!)
        ? 0.6
        : 0.4;
    final px = c.close > p.close ? 0.6 : 0.4;
    return clamp01(0.5 * calm + 0.5 * px);
  }
}

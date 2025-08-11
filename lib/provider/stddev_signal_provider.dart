// provider/stddev_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class StdDevSignalProvider implements SecondarySignalProvider {
  const StdDevSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].stdDev) || !isF(a[i].stdDev)) return false;
    return a[i].stdDev! <= a[i - 1].stdDev! && a[i].close > a[i - 1].close;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].stdDev) || !isF(a[i].stdDev)) return false;
    return a[i].stdDev! >= a[i - 1].stdDev! && a[i].close < a[i - 1].close;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final p = a[i - 1], c = a[i];
    final mm = minMax(a, i, (e) => e.stdDev);
    final volLow =
        1 - norm01Linear(isF(c.stdDev) ? c.stdDev! : mm.max, mm.min, mm.max);
    final priceUp = c.close > p.close ? 0.6 : 0.4;
    return clamp01(0.6 * volLow + 0.4 * priceUp);
  }
}

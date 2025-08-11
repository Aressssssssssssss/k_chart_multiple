// provider/atr_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class AtrSignalProvider implements SecondarySignalProvider {
  const AtrSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].atr) || !isF(a[i].atr)) return false;
    return a[i].atr! <= a[i - 1].atr! && a[i].close > a[i - 1].close;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].atr) || !isF(a[i].atr)) return false;
    return a[i].atr! >= a[i - 1].atr! && a[i].close < a[i - 1].close;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final p = a[i > 0 ? i - 1 : i], c = a[i];
    final volDown =
        (isF(p.atr) && isF(c.atr) && c.atr! <= p.atr!) ? 0.65 : 0.45;
    final px = c.close > p.close ? 0.65 : 0.35;
    return clamp01(0.5 * volDown + 0.5 * px);
  }
}

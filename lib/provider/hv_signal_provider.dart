// provider/hv_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class HvSignalProvider implements SecondarySignalProvider {
  const HvSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].hv) || !isF(a[i].hv)) return false;
    return a[i].hv! <= a[i - 1].hv! && a[i].close > a[i - 1].close;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].hv) || !isF(a[i].hv)) return false;
    return a[i].hv! >= a[i - 1].hv! && a[i].close < a[i - 1].close;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final p = a[i > 0 ? i - 1 : i], c = a[i];
    final volDown = (isF(p.hv) && isF(c.hv) && c.hv! <= p.hv!) ? 0.6 : 0.4;
    final px = c.close > p.close ? 0.6 : 0.4;
    return clamp01(0.5 * volDown + 0.5 * px);
  }
}

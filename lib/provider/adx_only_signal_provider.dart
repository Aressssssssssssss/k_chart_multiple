// provider/adx_only_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class AdxOnlySignalProvider implements SecondarySignalProvider {
  const AdxOnlySignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i].adx)) return false;
    return a[i].close > a[i - 1].close &&
        a[i].adx! >= (a[i - 1].adx ?? a[i].adx!);
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i].adx)) return false;
    return a[i].close < a[i - 1].close &&
        a[i].adx! >= (a[i - 1].adx ?? a[i].adx!);
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i], p = a[i > 0 ? i - 1 : i];
    final adx = isF(c.adx) ? c.adx! : 0.0; // [0,100]常见
    var strength = clamp01(adx / 100);
    final dir = c.close >= p.close ? 1.0 : 0.0;
    return clamp01(0.5 + 0.4 * (strength - 0.5) + 0.1 * (dir - 0.5));
  }
}

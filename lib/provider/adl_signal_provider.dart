// provider/adl_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class AdlSignalProvider implements SecondarySignalProvider {
  const AdlSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].adl) || !isF(a[i].adl)) return false;
    return a[i].adl! > a[i - 1].adl! && a[i].close > a[i - 1].close;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].adl) || !isF(a[i].adl)) return false;
    return a[i].adl! < a[i - 1].adl! && a[i].close < a[i - 1].close;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final mm = minMax(a, i, (e) => e.adl);
    final x = isF(a[i].adl) ? a[i].adl! : (mm.min + mm.max) / 2;
    return norm01Linear(x, mm.min, mm.max);
  }
}

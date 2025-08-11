// provider/vix_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class VixSignalProvider implements SecondarySignalProvider {
  const VixSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].vix) || !isF(a[i].vix)) return false;
    return a[i].vix! <= a[i - 1].vix! && a[i].close > a[i - 1].close;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].vix) || !isF(a[i].vix)) return false;
    return a[i].vix! >= a[i - 1].vix! && a[i].close < a[i - 1].close;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final mm = minMax(a, i, (e) => e.vix);
    final v = isF(a[i].vix) ? a[i].vix! : (mm.min + mm.max) / 2;
    // VIX 越低越偏多
    return 1 - norm01Linear(v, mm.min, mm.max);
  }
}

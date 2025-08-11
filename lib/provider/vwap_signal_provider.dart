// provider/vwap_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class VwapSignalProvider implements SecondarySignalProvider {
  const VwapSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].vwap) || !isF(a[i].vwap)) return false;
    return a[i - 1].close <= a[i - 1].vwap! && a[i].close > a[i].vwap!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].vwap) || !isF(a[i].vwap)) return false;
    return a[i - 1].close >= a[i - 1].vwap! && a[i].close < a[i].vwap!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    return priceAboveToProb(a[i], a[i].vwap, pct: 0.005);
  }
}

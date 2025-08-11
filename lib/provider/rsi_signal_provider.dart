// provider/rsi_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class RsiSignalProvider implements SecondarySignalProvider {
  final double center, oversold, overbought;
  const RsiSignalProvider(
      {this.center = 50, this.oversold = 30, this.overbought = 70});

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].rsi) || !isF(a[i].rsi)) return false;
    final p = a[i - 1].rsi!, c = a[i].rsi!;
    return (p <= oversold && c > oversold) || (p <= center && c > center);
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].rsi) || !isF(a[i].rsi)) return false;
    final p = a[i - 1].rsi!, c = a[i].rsi!;
    return (p >= overbought && c < overbought) || (p >= center && c < center);
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final r = isF(a[i].rsi) ? a[i].rsi! : 50.0;
    return clamp01((r - 0) / 100);
  }
}

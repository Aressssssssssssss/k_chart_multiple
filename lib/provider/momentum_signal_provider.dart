// provider/momentum_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class MomentumSignalProvider implements SecondarySignalProvider {
  const MomentumSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].momentum) || !isF(a[i].momentum)) return false;
    return a[i - 1].momentum! <= 0 && a[i].momentum! > 0;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].momentum) || !isF(a[i].momentum)) return false;
    return a[i - 1].momentum! >= 0 && a[i].momentum! < 0;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final mm = minMax(a, i, (e) => e.momentum);
    final x = isF(a[i].momentum) ? a[i].momentum! : 0.0;
    return norm01Linear(x, mm.min, mm.max);
  }
}

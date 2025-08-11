// provider/dem_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class DemSignalProvider implements SecondarySignalProvider {
  const DemSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].dem) || !isF(a[i].dem)) return false;
    return a[i - 1].dem! <= .3 && a[i].dem! > .3;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].dem) || !isF(a[i].dem)) return false;
    return a[i - 1].dem! >= .7 && a[i].dem! < .7;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final d = isF(a[i].dem) ? a[i].dem! : 0.5; // [0,1]
    return clamp01(d);
  }
}

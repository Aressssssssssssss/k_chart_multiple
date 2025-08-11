// provider/wpr_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class WprSignalProvider implements SecondarySignalProvider {
  const WprSignalProvider();
  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].wpr) || !isF(a[i].wpr)) return false;
    return a[i - 1].wpr! <= -80 && a[i].wpr! > -80;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].wpr) || !isF(a[i].wpr)) return false;
    return a[i - 1].wpr! >= -20 && a[i].wpr! < -20;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final r = isF(a[i].wpr) ? a[i].wpr! : -50.0;
    return clamp01((r + 100) / 100);
  }
}

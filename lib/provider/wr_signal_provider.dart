// provider/wr_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class WrSignalProvider implements SecondarySignalProvider {
  const WrSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].r) || !isF(a[i].r)) return false;
    return a[i - 1].r! <= -80 && a[i].r! > -80;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].r) || !isF(a[i].r)) return false;
    return a[i - 1].r! >= -20 && a[i].r! < -20;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final r = isF(a[i].r) ? a[i].r! : -50.0; // [-100,0]
    return clamp01((r + 100) / 100); // r越接近0越弱，这里反向：-100最强→1，0最弱→0
  }
}

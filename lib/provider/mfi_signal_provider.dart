// provider/mfi_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class MfiSignalProvider implements SecondarySignalProvider {
  const MfiSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].mfi) || !isF(a[i].mfi)) return false;
    return a[i - 1].mfi! <= 20 && a[i].mfi! > 20;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].mfi) || !isF(a[i].mfi)) return false;
    return a[i - 1].mfi! >= 80 && a[i].mfi! < 80;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final v = isF(a[i].mfi) ? a[i].mfi! : 50.0;
    return clamp01(v / 100);
  }
}

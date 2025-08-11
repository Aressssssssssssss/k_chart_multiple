// provider/cci_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class CciSignalProvider implements SecondarySignalProvider {
  const CciSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].cci) || !isF(a[i].cci)) return false;
    final p = a[i - 1].cci!, c = a[i].cci!;
    return (p <= -100 && c > -100) || (p <= 0 && c > 0);
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1 || !isF(a[i - 1].cci) || !isF(a[i].cci)) return false;
    final p = a[i - 1].cci!, c = a[i].cci!;
    return (p >= 100 && c < 100) || (p >= 0 && c < 0);
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final x = isF(a[i].cci) ? a[i].cci! : 0.0;
    return norm01Linear(x, -200, 200);
  }
}

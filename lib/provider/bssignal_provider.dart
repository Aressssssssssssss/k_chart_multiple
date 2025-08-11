// provider/bssignal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class BsSignalProvider implements SecondarySignalProvider {
  const BsSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) => a[i].buySignal == true;

  @override
  bool isSell(List<KLineEntity> a, int i) => a[i].sellSignal == true;

  @override
  double upProb(List<KLineEntity> a, int i) {
    if (a[i].buySignal == true) return 0.95;
    if (a[i].sellSignal == true) return 0.05;
    return 0.5;
  }
}

// provider/vortex_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class VortexSignalProvider implements SecondarySignalProvider {
  const VortexSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.viPlus) || !isF(p.viMinus) || !isF(c.viPlus) || !isF(c.viMinus))
      return false;
    return p.viPlus! <= p.viMinus! && c.viPlus! > c.viMinus!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.viPlus) || !isF(p.viMinus) || !isF(c.viPlus) || !isF(c.viMinus))
      return false;
    return p.viPlus! >= p.viMinus! && c.viPlus! < c.viMinus!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];
    if (!isF(c.viPlus) || !isF(c.viMinus)) return 0.5;
    final sum = (c.viPlus! + c.viMinus!);
    if (sum <= 0) return 0.5;
    return clamp01(c.viPlus! / sum); // 0..1
  }
}

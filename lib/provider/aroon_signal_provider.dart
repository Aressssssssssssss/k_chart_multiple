// provider/aroon_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class AroonSignalProvider implements SecondarySignalProvider {
  const AroonSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.aroonUp) ||
        !isF(p.aroonDown) ||
        !isF(c.aroonUp) ||
        !isF(c.aroonDown)) return false;
    return p.aroonUp! <= p.aroonDown! && c.aroonUp! > c.aroonDown!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.aroonUp) ||
        !isF(p.aroonDown) ||
        !isF(c.aroonUp) ||
        !isF(c.aroonDown)) return false;
    return p.aroonUp! >= p.aroonDown! && c.aroonUp! < c.aroonDown!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];
    final diff = (isF(c.aroonUp) && isF(c.aroonDown))
        ? (c.aroonUp! - c.aroonDown!)
        : 0.0; // [-100,100]
    return clamp01((diff + 100) / 200);
  }
}

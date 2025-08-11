// provider/trix_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class TrixSignalProvider implements SecondarySignalProvider {
  const TrixSignalProvider();
  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.trix) ||
        !isF(p.trixSignal) ||
        !isF(c.trix) ||
        !isF(c.trixSignal)) return false;
    return p.trix! <= p.trixSignal! && c.trix! > c.trixSignal!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.trix) ||
        !isF(p.trixSignal) ||
        !isF(c.trix) ||
        !isF(c.trixSignal)) return false;
    return p.trix! >= p.trixSignal! && c.trix! < c.trixSignal!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final mm = minMax(
        a,
        i,
        (e) => (isF(e.trix) && isF(e.trixSignal))
            ? e.trix! - e.trixSignal!
            : null);
    final diff = (isF(a[i].trix) && isF(a[i].trixSignal))
        ? a[i].trix! - a[i].trixSignal!
        : 0.0;
    return norm01Linear(diff, mm.min, mm.max);
  }
}

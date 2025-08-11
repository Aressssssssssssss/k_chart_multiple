// provider/dmi_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class DmiSignalProvider implements SecondarySignalProvider {
  final double adxTh;
  const DmiSignalProvider({this.adxTh = 20});

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.pdi) || !isF(p.mdi) || !isF(c.pdi) || !isF(c.mdi)) return false;
    final crossUp = p.pdi! <= p.mdi! && c.pdi! > c.mdi!;
    final adxOk = isF(c.adx) ? c.adx! >= adxTh : true;
    return crossUp && adxOk;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.pdi) || !isF(p.mdi) || !isF(c.pdi) || !isF(c.mdi)) return false;
    final crossDown = p.pdi! >= p.mdi! && c.pdi! < c.mdi!;
    final adxOk = isF(c.adx) ? c.adx! >= adxTh : true;
    return crossDown && adxOk;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];
    final diff =
        (isF(c.pdi) && isF(c.mdi)) ? (c.pdi! - c.mdi!) : 0.0; // [-100,100]
    var p = clamp01((diff + 100) / 200);
    if (isF(c.adx)) p = clamp01(p + (c.adx! / 200)); // ADX 强则略加分
    return p;
  }
}

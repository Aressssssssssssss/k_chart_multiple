// provider/ichimoku_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';
import 'dart:math' as math;

class IchimokuSignalProvider implements SecondarySignalProvider {
  const IchimokuSignalProvider();

  bool _aboveCloud(KLineEntity c) {
    if (!isF(c.ichimokuSpanA) || !isF(c.ichimokuSpanB)) return false;
    final top = math.max(c.ichimokuSpanA!, c.ichimokuSpanB!);
    return c.close > top;
  }

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.ichimokuTenkan) ||
        !isF(p.ichimokuKijun) ||
        !isF(c.ichimokuTenkan) ||
        !isF(c.ichimokuKijun)) return false;
    final crossUp = p.ichimokuTenkan! <= p.ichimokuKijun! &&
        c.ichimokuTenkan! > c.ichimokuKijun!;
    return crossUp && _aboveCloud(c);
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.ichimokuTenkan) ||
        !isF(p.ichimokuKijun) ||
        !isF(c.ichimokuTenkan) ||
        !isF(c.ichimokuKijun)) return false;
    final crossDown = p.ichimokuTenkan! >= p.ichimokuKijun! &&
        c.ichimokuTenkan! < c.ichimokuKijun!;
    if (!isF(c.ichimokuSpanA) || !isF(c.ichimokuSpanB)) return crossDown;
    final bottom = math.min(c.ichimokuSpanA!, c.ichimokuSpanB!);
    return crossDown && c.close < bottom;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];
    final tk = isF(c.ichimokuTenkan) ? c.ichimokuTenkan! : 0.0;
    final kj = isF(c.ichimokuKijun) ? c.ichimokuKijun! : 0.0;
    var p = clamp01(
        ((tk - kj) / (0.01 * math.max(1e-9, c.close))).clamp(-1, 1) * 0.5 +
            0.5);
    if (_aboveCloud(c)) p = (p + 0.15).clamp(0, 1);
    return p;
  }
}

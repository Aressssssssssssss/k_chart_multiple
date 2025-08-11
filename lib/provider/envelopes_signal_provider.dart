// provider/envelopes_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';
import 'dart:math' as math;

class EnvelopesSignalProvider implements SecondarySignalProvider {
  const EnvelopesSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.envMid) || !isF(c.envMid)) return false;
    return p.close <= p.envMid! && c.close > c.envMid!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];
    if (!isF(p.envMid) || !isF(c.envMid)) return false;
    return p.close >= p.envMid! && c.close < c.envMid!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];
    if (!isF(c.envMid)) return 0.5;
    // 若有上下轨，用距中轨的相对位置做归一
    if (isF(c.envUp) && isF(c.envDn)) {
      final top = math.max(c.envUp!, c.envDn!);
      final bot = math.min(c.envUp!, c.envDn!);
      final mid = c.envMid!;
      final spanUp = top - mid, spanDn = mid - bot;
      final pos = c.close >= mid
          ? (spanUp <= 0 ? 1 : (c.close - mid) / spanUp)
          : (spanDn <= 0 ? 0 : 1 - (mid - c.close) / spanDn);
      return clamp01(pos.toDouble());
    }
    return priceAboveToProb(c, c.envMid!, pct: 0.004);
  }
}

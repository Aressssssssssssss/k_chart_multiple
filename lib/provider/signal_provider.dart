// provider/signal_provider.dart
import '../entity/k_line_entity.dart';
import 'dart:math' as math;

/// 统一接口
abstract class SecondarySignalProvider {
  bool isBuy(List<KLineEntity> all, int i);
  bool isSell(List<KLineEntity> all, int i);

  /// 返回 [0,1] 的上涨概率
  double upProb(List<KLineEntity> all, int i);
}

abstract class MainSignalProvider {
  bool isBuy(List<KLineEntity> allData, int index);
  bool isSell(List<KLineEntity> allData, int index);

  double? upProb(List<KLineEntity> allData, int index);
}

/// ===== 常用工具函数（轻量、无状态） =====
double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

bool isF(double? x) => x != null && x.isFinite;

double norm01Linear(double v, double lo, double hi) {
  if (!v.isFinite) return 0.5;
  if (!hi.isFinite || !lo.isFinite || hi <= lo) return 0.5;
  return clamp01((v - lo) / (hi - lo));
}

/// 取最近 lookback 根中，某个指标的 min/max
typedef _Pick = double? Function(KLineEntity e);

({double min, double max}) minMax(List<KLineEntity> all, int i, _Pick pick,
    {int lookback = 50}) {
  int s = math.max(0, i - lookback + 1);
  double mn = double.infinity, mx = -double.infinity;
  for (int k = s; k <= i; k++) {
    final v = pick(all[k]);
    if (isF(v)) {
      if (v! < mn) mn = v;
      if (v > mx) mx = v;
    }
  }
  if (!mn.isFinite) mn = 0;
  if (!mx.isFinite) mx = 0;
  if (mx < mn) mx = mn;
  return (min: mn, max: mx);
}

/// 价差归一： (close - ref) / (k * close)，k=0.5%默认
double priceAboveToProb(KLineEntity c, double? ref, {double pct = 0.005}) {
  if (!isF(ref)) return 0.5;
  final base = (c.close - ref!) / (math.max(1e-9, c.close * pct));
  return clamp01((base.clamp(-1, 1) + 1) / 2);
}

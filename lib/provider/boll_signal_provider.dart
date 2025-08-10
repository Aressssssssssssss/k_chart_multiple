import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

/// BOLL 突破：收盘价上穿上轨为买入，下穿下轨为卖出
class BollSignalProvider implements MainSignalProvider {
  @override
  bool isBuy(List<KLineEntity> allData, int index) {
    final prev = index > 0 ? allData[index - 1] : allData[index];
    final cur = allData[index];
    final lastUp = prev.up ?? double.infinity;
    final curUp = cur.up ?? double.infinity;
    return prev.close <= lastUp && cur.close > curUp;
  }

  @override
  bool isSell(List<KLineEntity> allData, int index) {
    final prev = index > 0 ? allData[index - 1] : allData[index];
    final cur = allData[index];
    final lastDn = prev.dn ?? -double.infinity;
    final curDn = cur.dn ?? -double.infinity;
    return prev.close >= lastDn && cur.close < curDn;
  }

  @override
  double? upProb(List<KLineEntity> all, int i) {
    final c = all[i];
    final up = c.up, dn = c.dn;
    if (up == null || dn == null) return null;
    final range = up - dn;
    if (range.abs() <= 1e-12) return null;
    return ((c.close - dn) / range).clamp(0.0, 1.0);
  }
}

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
}

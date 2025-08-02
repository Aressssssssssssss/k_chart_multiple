import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

/// 完整版 KDJ 信号提供者：自己在这里做穿叉判断
class KdjSignalProvider implements SecondarySignalProvider {
  /// 买入信号：当前这根 K 线的 K 值（%K）向上穿过 D 值（%D）
  @override
  bool isBuy(List<KLineEntity> allData, int index) {
    if (index < 1) return false;
    final prev = allData[index - 1];
    final cur = allData[index];

    // 要求两根都有 k 和 d
    if (prev.k == null || prev.d == null || cur.k == null || cur.d == null) {
      return false;
    }
    // 前一根 K ≤ D 且 本根 K > D
    return prev.k! <= prev.d! && cur.k! > cur.d!;
  }

  /// 卖出信号：当前这根 K 线的 K 值向下穿过 D 值
  @override
  bool isSell(List<KLineEntity> allData, int index) {
    if (index < 1) return false;
    final prev = allData[index - 1];
    final cur = allData[index];

    if (prev.k == null || prev.d == null || cur.k == null || cur.d == null) {
      return false;
    }
    // 前一根 K ≥ D 且 本根 K < D
    return prev.k! >= prev.d! && cur.k! < cur.d!;
  }
}

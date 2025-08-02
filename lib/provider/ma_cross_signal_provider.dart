import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

/// MA 金叉（短 MA 从下向上穿过中 MA）；死叉反之
class MaCrossSignalProvider implements MainSignalProvider {
  @override
  bool isBuy(List<KLineEntity> allData, int index) {
    if (index < 1) return false;
    final prev = allData[index - 1];
    final cur = allData[index];
    final pMA = prev.maValueList;
    final cMA = cur.maValueList;
    if (pMA == null || cMA == null || pMA.length < 2 || cMA.length < 2) {
      return false;
    }
    return pMA[0] <= pMA[1] && cMA[0] > cMA[1];
  }

  @override
  bool isSell(List<KLineEntity> allData, int index) {
    if (index < 1) return false;
    final prev = allData[index - 1];
    final cur = allData[index];
    final pMA = prev.maValueList;
    final cMA = cur.maValueList;
    if (pMA == null || cMA == null || pMA.length < 2 || cMA.length < 2) {
      return false;
    }
    return pMA[0] >= pMA[1] && cMA[0] < cMA[1];
  }
}

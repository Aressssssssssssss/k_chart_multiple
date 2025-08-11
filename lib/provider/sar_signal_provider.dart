// provider/sar_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class SarSignalProvider implements SecondarySignalProvider {
  const SarSignalProvider();

  @override
  bool isBuy(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];

    // 情况1：有布尔位 psarIsUp，直接用趋势翻转判断
    if (p.psarIsUp != null && c.psarIsUp != null) {
      return p.psarIsUp == false && c.psarIsUp == true;
    }

    // 情况2：没有 psarIsUp，用价格与 psar 的穿越判断
    if (!isF(p.psar) || !isF(c.psar)) return false;
    return p.close <= p.psar! && c.close > c.psar!;
  }

  @override
  bool isSell(List<KLineEntity> a, int i) {
    if (i < 1) return false;
    final p = a[i - 1], c = a[i];

    if (p.psarIsUp != null && c.psarIsUp != null) {
      return p.psarIsUp == true && c.psarIsUp == false;
    }

    if (!isF(p.psar) || !isF(c.psar)) return false;
    return p.close >= p.psar! && c.close < c.psar!;
  }

  @override
  double upProb(List<KLineEntity> a, int i) {
    final c = a[i];

    // 如果有布尔位，就给一个偏置的概率
    if (c.psarIsUp != null) {
      return c.psarIsUp! ? 0.7 : 0.3;
    }

    // 否则，用价格相对 psar 的位置做归一
    return priceAboveToProb(c, c.psar);
  }
}

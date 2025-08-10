// 新增 rsi_signal_provider.dart
import '../entity/k_line_entity.dart';
import 'signal_provider.dart';

class RsiSignalProvider implements SecondarySignalProvider {
  @override
  bool isBuy(List<KLineEntity> all, int i) {
    if (i < 1) return false;
    final p = all[i - 1].rsi, c = all[i].rsi;
    if (p == null || c == null) return false;
    return p <= 50 && c > 50; // 穿越50
  }

  @override
  bool isSell(List<KLineEntity> all, int i) {
    if (i < 1) return false;
    final p = all[i - 1].rsi, c = all[i].rsi;
    if (p == null || c == null) return false;
    return p >= 50 && c < 50;
  }

  @override
  double? upProb(List<KLineEntity> all, int i) {
    final r = all[i].rsi;
    if (r == null) return null;
    return (r / 100).clamp(0.0, 1.0);
  }
}

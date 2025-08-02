import '../entity/k_line_entity.dart';

/// 副图信号提供者接口：全量 K 线列表 + 当前索引
abstract class SecondarySignalProvider {
  /// allData：完整 K 线列表；index：当前要判断信号的索引
  bool isBuy(List<KLineEntity> allData, int index);
  bool isSell(List<KLineEntity> allData, int index);
}

/// 主图信号提供者接口：同上
abstract class MainSignalProvider {
  bool isBuy(List<KLineEntity> allData, int index);
  bool isSell(List<KLineEntity> allData, int index);
}

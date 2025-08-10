import '../entity/k_line_entity.dart';

/// 副图信号提供者接口：全量 K 线列表 + 当前索引
abstract class SecondarySignalProvider {
  /// allData：完整 K 线列表；index：当前要判断信号的索引
  bool isBuy(List<KLineEntity> allData, int index);
  bool isSell(List<KLineEntity> allData, int index);

  /// 返回上涨概率(0~1)。为 null 表示无法给出(缺数据/不适用)。
  double? upProb(List<KLineEntity> allData, int index);
}

/// 主图信号提供者接口：同上
abstract class MainSignalProvider {
  bool isBuy(List<KLineEntity> allData, int index);
  bool isSell(List<KLineEntity> allData, int index);

  /// 返回上涨概率(0~1)。为 null 表示无法给出(缺数据/不适用)。
  double? upProb(List<KLineEntity> allData, int index);
}

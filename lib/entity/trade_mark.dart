import 'package:flutter/material.dart';

enum TradeAction { entry, tp, exitWin, exitLoss, timeStop, trailStop }

enum TradeSide { long, short }

class TradeMark {
  /// 对应K线索引（你的回测里：先用time映射到index）
  final int index;

  /// 发生价格（绘制Y坐标）
  final double price;

  /// 做多/做空（当前只做多也可以都传TradeSide.long）
  final TradeSide side;

  /// 行为：入场/止盈/止损/时间止损等
  final TradeAction action;

  /// 可选：文字标签（例如“TP1 0.3”）
  final String? label;

  /// 可选：颜色（不传用默认）
  final Color? color;

  const TradeMark({
    required this.index,
    required this.price,
    required this.side,
    required this.action,
    this.label,
    this.color,
  });
}

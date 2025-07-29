import '../entity/k_entity.dart';

class KLineEntity extends KEntity {
  late double open;
  late double high;
  late double low;
  late double close;
  late double vol;
  late double? amount;
  double? change;
  double? ratio;
  int? time;
  double? osma; // Moving Average of Oscillator, i.e. MACD(柱) = dif - dea
  double? probability;

  KLineEntity.fromCustom({
    this.amount,
    required this.open,
    required this.close,
    this.change,
    this.ratio,
    required this.time,
    required this.high,
    required this.low,
    required this.vol,
  });

  KLineEntity.fromJson(Map<String, dynamic> json) {
    open = double.tryParse(json['open'] ?? "0") ?? 0;
    high = double.tryParse(json['high'] ?? "0") ?? 0;
    low = double.tryParse(json['low'] ?? "0") ?? 0;
    close = double.tryParse(json['close'] ?? "0") ?? 0;
    vol = double.tryParse(json['vol'] ?? "0") ?? 0;
    amount = double.tryParse(json['amount'] ?? "0") ?? 0;
    int? tempTime = int.tryParse(json['time'] ?? "0") ?? 0;
    //兼容火币数据
    if (tempTime == null) {
      tempTime = int.tryParse(json['id'] ?? "0") ?? 0;
      tempTime = tempTime! * 1000;
    }
    time = tempTime;
    ratio = double.tryParse(json['ratio'] ?? "0") ?? 0;
    change = double.tryParse(json['change'] ?? "0") ?? 0;

    // 如果后端也返回了 'pdi', 'mdi', 'adx', 'adxr' 字段:
    pdi = double.tryParse(json['pdi'] ?? "0") ?? 0;
    mdi = double.tryParse(json['mdi'] ?? "0") ?? 0;
    adx = double.tryParse(json['adx'] ?? "0") ?? 0;
    adxr = double.tryParse(json['adxr'] ?? "0") ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['time'] = this.time;
    data['open'] = this.open;
    data['close'] = this.close;
    data['high'] = this.high;
    data['low'] = this.low;
    data['vol'] = this.vol;
    data['amount'] = this.amount;
    data['ratio'] = this.ratio;
    data['change'] = this.change;

    // 如果需要把 DMI 字段也序列化
    data['pdi'] = this.pdi;
    data['mdi'] = this.mdi;
    data['adx'] = this.adx;
    data['adxr'] = this.adxr;

    return data;
  }

  @override
  String toString() {
    return 'MarketModel{open: $open, high: $high, low: $low, close: $close, vol: $vol, time: $time, amount: $amount, ratio: $ratio, change: $change}';
  }
}

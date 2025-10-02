import '../entity/k_entity.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

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

  bool? buySignal; // ★ add
  bool? sellSignal; // ★ add

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
    open = _parseDouble(json['open']);
    high = _parseDouble(json['high']);
    low = _parseDouble(json['low']);
    close = _parseDouble(json['close']);
    vol = _parseDouble(json['vol']);
    amount = _parseNullableDouble(json['amount']);

    int? tempTime = _parseInt(json['time']);
    if (tempTime == null) {
      final id = _parseInt(json['id']);
      if (id != null) {
        tempTime = id * 1000;
      }
    }
    time = tempTime ?? 0;

    ratio = _parseNullableDouble(json['ratio']);
    change = _parseNullableDouble(json['change']);

    // 如果后端也返回了 'pdi', 'mdi', 'adx', 'adxr' 字段:
    pdi = _parseNullableDouble(json['pdi']);
    mdi = _parseNullableDouble(json['mdi']);
    adx = _parseNullableDouble(json['adx']);
    adxr = _parseNullableDouble(json['adxr']);
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

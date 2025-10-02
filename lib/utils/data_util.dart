import 'dart:math' as math;

import '../entity/index.dart';

class DataUtil {
  static calculate(List<KLineEntity> dataList,
      [List<int> maDayList = const [5, 10, 20], int n = 20, k = 2]) {
    calcMA(dataList, maDayList);
    calcBOLL(dataList, n, k);
    calcVolumeMA(dataList);
    calcKDJ(dataList);
    calcMACD(dataList);
    calcRSI(dataList);
    calcWR(dataList);
    calcCCI(dataList);
    _computePPO(dataList);
    _computeTRIX(dataList);
    _computeDMIAdvanced(dataList);
    _computeDMI(dataList);
    _computeTSI(dataList);
    _computeIchimoku(dataList);
    _computePSAR(dataList);
    _computeVortex(dataList);
    _computeATR(dataList);
    _computeHV(dataList);
    _computeVWAP(dataList);
    _computeOBVAdvanced(dataList);
    _computeADLine(dataList);
    _computeVIXLocally(dataList);
    _computeADX(dataList);
    _computeStdDev(dataList);
    _computeOsMA(dataList);
    _computeStochastic(dataList);
    _computeWPR(dataList);
    _computeDeMarker(dataList);
    _computeMomentum(dataList);
    _computeMFI(dataList);
    _computeEnvelopes(dataList);
    _computeVolIndicator(dataList);
    _computeAroonAdvanced(dataList);
    _computeChaikinMoneyFlow(dataList);
    _computeChaikinOscillator(dataList);
    _computeKlingerOscillator(dataList);
    _computeVpt(dataList);
    _computeForceIndex(dataList);
    _computeRoc(dataList);
    _computeUltimateOsc(dataList);
    _computeConnorsRsi(dataList);
    _computeStochRsi(dataList);
    _computeRvi(dataList);
    _computeDpo(dataList);
    _computeKama(dataList);
    _computeHma(dataList);
    _computeKeltnerChannel(dataList);
    _computeDonchianChannel(dataList);
    _computeBollingerBandwidth(dataList);
    _computeChaikinVolatility(dataList);
    _computeHvPercentile(dataList);
    _computeAtrPercentile(dataList);
    _computeElderRay(dataList);
    _computeIchimokuSpanDiff(dataList);
    _computePivotPoints(dataList);
    _computeGannFan(dataList);

    _calculateProbabilities(dataList);
  }

  static void _calculateProbabilities(List<KLineEntity> dataList) {
    if (dataList.length < 3) {
      return;
    }

    // 保存过去的概率以进行平滑处理
    List<double> previousProbabilities = [];

    for (int i = 2; i < dataList.length; i++) {
      final cur = dataList[i];
      double upProbability = 0;
      double totalWeight = 0;

      String marketCondition = _determineMarketCondition(dataList, i);
      final Map<String, double> weightConfig =
          _getIndicatorWeights(marketCondition);

      for (var entry in weightConfig.entries) {
        String indicator = entry.key;
        double weight = entry.value;

        Map<String, double> params = _getParamsForIndicator(cur, indicator);
        double signal = _calculateSignal(indicator, params);

        upProbability += signal * weight;
        totalWeight += weight;
      }

      upProbability = (upProbability / totalWeight).clamp(0.01, 0.99);

      // 平滑处理
      if (previousProbabilities.isNotEmpty) {
        upProbability = (upProbability + previousProbabilities.last) / 2.0;
      }

      if (i > 2) {
        // 使用前一根蜡烛的概率值进行平滑
        upProbability = (upProbability + dataList[i - 1].probability!) / 2.0;
      }

      previousProbabilities.add(upProbability);

      cur.probability = upProbability;
      // print('Probability: $upProbability');
    }
  }

  /// 改进后的市场状态判断
  /// 动态判断市场状态
  static String _determineMarketCondition(List<KLineEntity> data, int index) {
    final KLineEntity entity = data[index];
    final KLineEntity? previous = index > 0 ? data[index - 1] : null;
    // 默认阈值（可以根据需求调整）
    const double adxTrendThreshold = 25.0; // ADX 趋势强度阈值
    const double macdTrendThreshold = 0.02; // MACD 信号阈值（DIF 和 DEA 差值）
    const double sidewaysRange = 0.005; // 横盘整理的价格变动范围（百分比）
    const double volatilityThreshold = 0.03; // 波动性阈值（ATR 占价格比例）
    const double weakTrendThreshold = 0.01; // 弱趋势阈值（价格变动比例）

    // 提取指标数据
    final double adx = entity.adx ?? 0.0;
    final double dif = entity.dif ?? 0.0;
    final double dea = entity.dea ?? 0.0;
    final double closePrice = entity.close;
    final double prevClosePrice = previous?.close ?? closePrice;
    final double atr = entity.atr ?? 0.0;

    // 计算市场状态指标
    double macdHist = dif - dea; // MACD 柱状图
    double priceChange = 0.0;
    final double priceBase = prevClosePrice.abs() < 1e-12
        ? (closePrice.abs() < 1e-12 ? 1 : closePrice)
        : prevClosePrice;
    if (priceBase != 0) {
      priceChange = (closePrice - prevClosePrice).abs() / priceBase.abs();
    }
    final double volatility =
        closePrice.abs() < 1e-12 ? 0.0 : (atr / closePrice.abs());

    // 判断市场状态
    if (adx >= adxTrendThreshold) {
      // ADX 显示明显趋势
      if (macdHist > macdTrendThreshold) {
        return 'trendingUp'; // 明显上升趋势
      } else if (macdHist < -macdTrendThreshold) {
        return 'trendingDown'; // 明显下降趋势
      }
    } else if (priceChange <= weakTrendThreshold) {
      // 缓慢价格变动
      if (macdHist > 0) {
        return 'weakTrendingUp'; // 缓慢上升趋势
      } else if (macdHist < 0) {
        return 'weakTrendingDown'; // 缓慢下降趋势
      }
    } else if (priceChange <= sidewaysRange) {
      // 横盘整理
      return 'sideways';
    } else if (volatility >= volatilityThreshold) {
      // 波动较大
      return 'volatile';
    }

    // 默认返回横盘整理状态
    return 'sideways';
  }

  /// 根据市场条件获取指标权重配置
  /// 获取指标权重
  static Map<String, double> _getIndicatorWeights(String marketCondition) {
    switch (marketCondition) {
      case 'trendingUp': // 市场处于明显上升趋势
        return {
          'MACD': 0.4, // MACD 更重要
          'ADX': 0.3, // 趋势强度
          'RSI': 0.2, // 超买超卖
          'Ichimoku': 0.1, // 云图确认趋势
          'WR': 0.0, // 辅助指标
          'TRIX': 0.0, // 辅助指标
          'CCI': 0.0, // 辅助指标
        };
      case 'trendingDown': // 市场处于明显下降趋势
        return {
          'MACD': 0.4, // MACD 强化趋势信号
          'ADX': 0.3, // 趋势强度
          'RSI': 0.2, // 超买超卖
          'Ichimoku': 0.1, // 云图确认趋势
          'WR': 0.0,
          'TRIX': 0.0,
          'CCI': 0.0,
        };
      case 'sideways': // 市场横盘整理
        return {
          'RSI': 0.3, // RSI 重要
          'WR': 0.3, // 威廉指标
          'CCI': 0.2, // CCI 捕捉波动
          'Ichimoku': 0.1, // 云图辅助信号
          'MACD': 0.1, // 次要
          'ADX': 0.0, // 趋势信号不重要
          'TRIX': 0.0, // 辅助
        };
      case 'volatile': // 市场波动较大
        return {
          'RSI': 0.25, // RSI 超买超卖
          'WR': 0.25, // 威廉指标
          'CCI': 0.2, // CCI 波动信号
          'TRIX': 0.2, // TRIX 平滑信号
          'Ichimoku': 0.1, // 云图
          'MACD': 0.0, // 趋势指标不重要
          'ADX': 0.0,
        };
      case 'weakTrendingUp': // 市场缓慢上升
        return {
          'Ichimoku': 0.3, // 云图较为重要
          'MACD': 0.25,
          'ADX': 0.2,
          'RSI': 0.15,
          'WR': 0.05,
          'TRIX': 0.05,
          'CCI': 0.0,
        };
      case 'weakTrendingDown': // 市场缓慢下降
        return {
          'Ichimoku': 0.3, // 云图较为重要
          'MACD': 0.25,
          'ADX': 0.2,
          'RSI': 0.15,
          'WR': 0.05,
          'TRIX': 0.05,
          'CCI': 0.0,
        };
      default: // 默认情况
        return {
          'MACD': 0.2,
          'RSI': 0.2,
          'Ichimoku': 0.2,
          'ADX': 0.2,
          'WR': 0.1,
          'TRIX': 0.05,
          'CCI': 0.05,
        };
    }
  }

  static double _calculateSignal(String indicator, Map<String, double> params) {
    switch (indicator) {
      case 'MACD':
        // 使用动态缩放，确保信号在 [-1, 1] 范围内
        double dif = params['DIF'] ?? 0.0;
        double dea = params['DEA'] ?? 0.0;
        double hist = dif - dea; // 柱状图信号
        return hist / (hist.abs() + 1.0); // 动态缩放信号值

      case 'RSI':
        // RSI 信号基于超买（>70）和超卖（<30）区域，缩放至 [-1, 1]
        double rsi = params['RSI'] ?? 50.0;
        if (rsi > 70) {
          return (rsi - 70) / 30.0; // 超买区 [0, 1]
        } else if (rsi < 30) {
          return (rsi - 30) / 30.0; // 超卖区 [-1, 0]
        } else {
          return 0.0; // 中性信号
        }

      case 'ADX':
        // ADX 趋势强度信号，动态缩放至 [-1, 1]
        double adx = params['ADX'] ?? 0.0;
        return (adx - 25) / (adx.abs() + 25.0); // 确保信号平滑

      case 'Ichimoku':
        // Ichimoku 云图信号，通过价格与 SpanA/SpanB 的关系判断趋势
        double price = params['price'] ?? 0.0;
        double spanA = params['SpanA'] ?? 0.0;
        double spanB = params['SpanB'] ?? 0.0;
        double midPoint = (spanA + spanB) / 2.0;
        if (price > spanA && price > spanB) {
          return 0.9; // 在云区上方（强势看涨）
        } else if (price < spanA && price < spanB) {
          return -0.9; // 在云区下方（强势看跌）
        } else {
          // 在云区内，根据价格距离中心线的线性评分
          return (price - midPoint) /
              (spanA - spanB).abs().clamp(0.1, double.infinity);
        }

      case 'WR': // 威廉指标
        // WR 基于超买（<20）和超卖（>80）区域，线性缩放至 [-1, 1]
        double wr = params['WR'] ?? 50.0;
        if (wr < 20) {
          return (20 - wr) / 20.0; // 超买区 [0, 1]
        } else if (wr > 80) {
          return (wr - 80) / 20.0; // 超卖区 [-1, 0]
        } else {
          return 0.0; // 中性信号
        }

      case 'TRIX':
        // TRIX 动量指标，基于信号差值动态缩放
        double trix = params['TRIX'] ?? 0.0;
        double signal = params['Signal'] ?? 0.0;
        double diff = trix - signal;
        return diff / (signal.abs() + 0.1); // 动态缩放避免除零

      case 'CCI':
        // CCI 基于 [-100, 100] 范围，动态缩放至 [-1, 1]
        double cci = params['CCI'] ?? 0.0;
        if (cci > 100) {
          return (cci - 100) / 200.0; // 强势上涨 [0, 1]
        } else if (cci < -100) {
          return (cci + 100) / 200.0; // 强势下跌 [-1, 0]
        } else {
          return cci / 100.0; // 中性 [-1.0, 1.0]
        }

      default:
        // 未知指标，打印日志并返回中性信号
        // print('==============================Unknown indicator: $indicator');
        return 0.0; // 默认中性信号
    }
  }

  /// 获取当前实体的指标参数
  static Map<String, double> _getParamsForIndicator(
      KLineEntity entity, String indicator) {
    switch (indicator) {
      case 'MACD':
        return {'DIF': entity.dif ?? 0, 'DEA': entity.dea ?? 0};
      case 'RSI':
        return {'RSI': entity.rsi ?? 0};
      case 'ADX':
        return {'ADX': entity.adx ?? 0};
      case 'Ichimoku':
        return {
          'price': entity.close,
          'SpanA': entity.ichimokuSpanA ?? 0,
          'SpanB': entity.ichimokuSpanB ?? 0
        };
      case 'WR':
        return {'WR': entity.wpr ?? 0};
      case 'TRIX':
        return {'TRIX': entity.trix ?? 0, 'Signal': entity.trixSignal ?? 0};
      case 'CCI':
        return {'CCI': entity.cci ?? 0};
      default:
        // print("===================this indicator didn't get value : " +
        //     indicator);
        return {};
    }
  }

  static calcMA(List<KLineEntity> dataList, List<int> maDayList) {
    List<double> ma = List<double>.filled(maDayList.length, 0);

    if (dataList.isNotEmpty) {
      for (int i = 0; i < dataList.length; i++) {
        KLineEntity entity = dataList[i];
        final closePrice = entity.close;
        entity.maValueList = List<double>.filled(maDayList.length, 0);

        for (int j = 0; j < maDayList.length; j++) {
          ma[j] += closePrice;
          if (i == maDayList[j] - 1) {
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else if (i >= maDayList[j]) {
            ma[j] -= dataList[i - maDayList[j]].close;
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else {
            entity.maValueList?[j] = 0;
          }
        }
      }
    }
  }

  static void calcBOLL(List<KLineEntity> dataList, int n, int k) {
    _calcBOLLMA(n, dataList);
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      if (i >= n) {
        double md = 0;
        for (int j = i - n + 1; j <= i; j++) {
          double c = dataList[j].close;
          double m = entity.BOLLMA!;
          double value = c - m;
          md += value * value;
        }
        md = md / (n - 1);
        md = math.sqrt(md);
        entity.mb = entity.BOLLMA!;
        entity.up = entity.mb! + k * md;
        entity.dn = entity.mb! - k * md;
      }
    }
  }

  static void _calcBOLLMA(int day, List<KLineEntity> dataList) {
    double ma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      ma += entity.close;
      if (i == day - 1) {
        entity.BOLLMA = ma / day;
      } else if (i >= day) {
        ma -= dataList[i - day].close;
        entity.BOLLMA = ma / day;
      } else {
        entity.BOLLMA = null;
      }
    }
  }

  static void calcMACD(List<KLineEntity> dataList) {
    double ema12 = 0;
    double ema26 = 0;
    double dif = 0;
    double dea = 0;
    double macd = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final closePrice = entity.close;
      if (i == 0) {
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        // EMA（12） = 前一日EMA（12） X 11/13 + 今日收盘价 X 2/13
        ema12 = ema12 * 11 / 13 + closePrice * 2 / 13;
        // EMA（26） = 前一日EMA（26） X 25/27 + 今日收盘价 X 2/27
        ema26 = ema26 * 25 / 27 + closePrice * 2 / 27;
      }
      // DIF = EMA（12） - EMA（26） 。
      // 今日DEA = （前一日DEA X 8/10 + 今日DIF X 2/10）
      // 用（DIF-DEA）*2即为MACD柱状图。
      dif = ema12 - ema26;
      dea = dea * 8 / 10 + dif * 2 / 10;
      macd = (dif - dea) * 2;
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
    }
  }

  static void calcVolumeMA(List<KLineEntity> dataList) {
    double volumeMa5 = 0;
    double volumeMa10 = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == 4) {
        entry.MA5Volume = (volumeMa5 / 5);
      } else if (i > 4) {
        volumeMa5 -= dataList[i - 5].vol;
        entry.MA5Volume = volumeMa5 / 5;
      } else {
        entry.MA5Volume = 0;
      }

      if (i == 9) {
        entry.MA10Volume = volumeMa10 / 10;
      } else if (i > 9) {
        volumeMa10 -= dataList[i - 10].vol;
        entry.MA10Volume = volumeMa10 / 10;
      } else {
        entry.MA10Volume = 0;
      }
    }
  }

  static void calcRSI(List<KLineEntity> dataList) {
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final double closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double rMax =
            math.max(0, closePrice - dataList[i - 1].close.toDouble());
        double rAbs = (closePrice - dataList[i - 1].close.toDouble()).abs();

        rsiMaxEma = (rMax + (14 - 1) * rsiMaxEma) / 14;
        rsiABSEma = (rAbs + (14 - 1) * rsiABSEma) / 14;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < 13) rsi = null;
      if (rsi != null && rsi.isNaN) rsi = null;
      entity.rsi = rsi;
    }
  }

  static void calcKDJ(List<KLineEntity> dataList) {
    var preK = 50.0;
    var preD = 50.0;
    final tmp = dataList.first;
    tmp.k = preK;
    tmp.d = preD;
    tmp.j = 50.0;
    for (int i = 1; i < dataList.length; i++) {
      final entity = dataList[i];
      final n = math.max(0, i - 8);
      var low = entity.low;
      var high = entity.high;
      for (int j = n; j < i; j++) {
        final t = dataList[j];
        if (t.low < low) {
          low = t.low;
        }
        if (t.high > high) {
          high = t.high;
        }
      }
      final cur = entity.close;
      var rsv = (cur - low) * 100.0 / (high - low);
      rsv = rsv.isNaN ? 0 : rsv;
      final k = (2 * preK + rsv) / 3.0;
      final d = (2 * preD + k) / 3.0;
      final j = 3 * k - 2 * d;
      preK = k;
      preD = d;
      entity.k = k;
      entity.d = d;
      entity.j = j;
    }
  }

  static void calcWR(List<KLineEntity> dataList) {
    double r;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      int startIndex = i - 14;
      if (startIndex < 0) {
        startIndex = 0;
      }
      double max14 = double.minPositive;
      double min14 = double.maxFinite;
      for (int index = startIndex; index <= i; index++) {
        max14 = math.max(max14, dataList[index].high);
        min14 = math.min(min14, dataList[index].low);
      }
      if (i < 13) {
        entity.r = -10;
      } else {
        r = -100 * (max14 - dataList[i].close) / (max14 - min14);
        if (r.isNaN) {
          entity.r = null;
        } else {
          entity.r = r;
        }
      }
    }
  }

  static void calcCCI(List<KLineEntity> dataList) {
    final size = dataList.length;
    final count = 14;
    for (int i = 0; i < size; i++) {
      final kline = dataList[i];
      final tp = (kline.high + kline.low + kline.close) / 3;
      final start = math.max(0, i - count + 1);
      var amount = 0.0;
      var len = 0;
      for (int n = start; n <= i; n++) {
        amount += (dataList[n].high + dataList[n].low + dataList[n].close) / 3;
        len++;
      }
      final ma = amount / len;
      amount = 0.0;
      for (int n = start; n <= i; n++) {
        amount +=
            (ma - (dataList[n].high + dataList[n].low + dataList[n].close) / 3)
                .abs();
      }
      final md = amount / len;
      kline.cci = ((tp - ma) / 0.015 / md);
      if (kline.cci!.isNaN) {
        kline.cci = 0.0;
      }
    }
  }

  /// 计算 Percentage Price Oscillator (PPO)
  /// [fastPeriod]   PPO 快周期，常见默认 12
  /// [slowPeriod]   PPO 慢周期，常见默认 26
  /// [signalPeriod] PPO 信号线周期，常见默认 9
  static void _computePPO(List<KLineEntity> data,
      {int fastPeriod = 12, int slowPeriod = 26, int signalPeriod = 9}) {
    if (data.isEmpty) return;

    final length = data.length;
    // Step1: 先计算快/慢两条 EMA
    List<double> emaFast = List.filled(length, 0);
    List<double> emaSlow = List.filled(length, 0);

    double alphaFast = 2.0 / (fastPeriod + 1);
    double alphaSlow = 2.0 / (slowPeriod + 1);

    // 初始化
    emaFast[0] = data[0].close;
    emaSlow[0] = data[0].close;
    data[0].ppo = 0;
    data[0].ppoSignal = 0;

    // 计算快周期EMA和慢周期EMA
    for (int i = 1; i < length; i++) {
      double c = data[i].close;

      emaFast[i] = emaFast[i - 1] + alphaFast * (c - emaFast[i - 1]);
      emaSlow[i] = emaSlow[i - 1] + alphaSlow * (c - emaSlow[i - 1]);
    }

    // Step2: 计算 PPO 主线: ((EMAfast - EMAslow) / EMAslow) * 100
    List<double> ppoLine = List.filled(length, 0);
    for (int i = 0; i < length; i++) {
      double slow = emaSlow[i];
      if (slow.abs() < 1e-12) {
        // 防止除 0 或极端爆炸 => 设为0
        ppoLine[i] = 0;
      } else {
        double ratio = (emaFast[i] - slow) / slow * 100;
        // 可做一下防爆保护
        if (ratio.isInfinite || ratio.isNaN) {
          ratio = 0;
        } else if (ratio.abs() > 1e5) {
          // 你可以自定义一个最大绝对值
          ratio = ratio > 0 ? 1e5 : -1e5;
        }
        ppoLine[i] = ratio;
      }
      data[i].ppo = ppoLine[i];
    }

    // Step3: 计算 PPO信号线 (再对ppoLine做EMA平滑)
    final double alphaSignal = 2.0 / (signalPeriod + 1);
    if (length > 1) {
      data[1].ppoSignal = ppoLine[1]; // 初始化
      for (int i = 2; i < length; i++) {
        double prevSignal = data[i - 1].ppoSignal ?? 0;
        double curPPO = ppoLine[i];
        double sig = prevSignal + alphaSignal * (curPPO - prevSignal);

        // 防止溢出
        if (!sig.isFinite) sig = 0;

        data[i].ppoSignal = sig;
      }
    }
  }

  /// 计算 TRIX 指标和信号线
  /// [period]       计算TRIX的周期(常见默认12)
  /// [signalPeriod] 信号线周期(常见默认9)
  static void _computeTRIX(List<KLineEntity> data,
      {int period = 12, int signalPeriod = 9}) {
    if (data.isEmpty) return;

    // 1) 先建3个临时数组保存中间结果(三次EMA)
    final int length = data.length;
    List<double> ema1 = List.filled(length, 0);
    List<double> ema2 = List.filled(length, 0);
    List<double> ema3 = List.filled(length, 0);

    // EMA参数 (2/(period+1))，也可做Wilder等其它平滑
    final double alpha = 2.0 / (period + 1);

    // 初始化(第一条无从计算, 先直接等于close)
    ema1[0] = data[0].close;
    ema2[0] = data[0].close;
    ema3[0] = data[0].close;
    data[0].trix = 0; // 第0条没法算TRIX
    data[0].trixSignal = 0; // 信号线也初始化

    // 2) 计算三重EMA
    for (int i = 1; i < length; i++) {
      double c = data[i].close;

      // 第一次EMA
      ema1[i] = ema1[i - 1] + alpha * (c - ema1[i - 1]);

      // 第二次EMA
      ema2[i] = ema2[i - 1] + alpha * (ema1[i] - ema2[i - 1]);

      // 第三次EMA
      ema3[i] = ema3[i - 1] + alpha * (ema2[i] - ema3[i - 1]);
    }

    // 3) 根据第三次EMA来计算 TRIX
    // for (int i = 1; i < length; i++) {
    //   double prev3 = ema3[i - 1];
    //   // if (prev3 != 0) {
    //   //   double trixVal = (ema3[i] - prev3) / prev3 * 100;
    //   //   data[i].trix = trixVal;
    //   // } else {
    //   //   data[i].trix = 0;
    //   // }

    //   // 如果 |(ema3[i] - prev3)/prev3| 超过某阈值，就直接截断
    //   if (prev3.abs() > 1e-12) {
    //     double ratio = (ema3[i] - prev3) / prev3;
    //     if (ratio.abs() > 1e4) {
    //       // 说明波动太大，直接截断
    //       ratio = ratio > 0 ? 1e4 : -1e4;
    //     }
    //     data[i].trix = ratio * 100;
    //   } else {
    //     data[i].trix = 0;
    //   }

    //   // 调试打印
    //   print('TRIX[$i]: ${data[i].trix}');
    // }
    for (int i = 1; i < length; i++) {
      double prev3 = ema3[i - 1];
      if (prev3.abs() < 1e-12) {
        // 防止分母过小 => 爆炸
        data[i].trix = 0;
      } else {
        double ratio = (ema3[i] - prev3) / prev3;
        // 如果你想做强行截断:
        if (ratio.isInfinite || ratio.isNaN) {
          ratio = 0;
        } else if (ratio.abs() > 1e4) {
          // 自定义最大绝对值，避免过大
          ratio = ratio > 0 ? 1e4 : -1e4;
        }
        data[i].trix = ratio * 100;
      }
    }

    // 4) 计算信号线(对 TRIX 做一条EMA)
    double alphaSignal = 2.0 / (signalPeriod + 1);
    // 让第0条 or 第1条初始化
    // 这里让第1条 = data[1].trix, 再从第2条开始
    if (length > 1) {
      data[1].trixSignal = data[1].trix ?? 0;
      for (int i = 2; i < length; i++) {
        double prevSignal = data[i - 1].trixSignal ?? 0;
        double currTrix = data[i].trix ?? 0;
        double signal = prevSignal + alphaSignal * (currTrix - prevSignal);
        data[i].trixSignal = signal;
      }
    }
  }

  /// 计算 DMI/ADX 的增强版
  /// [period]        常见默认14
  /// [useAdxr]       是否计算并保存ADXR
  /// [smoothMethod]  使用何种平滑算法:
  ///                  - "wilder"   经典Wilder平滑 (默认)
  ///                  - "ema"      指数平滑(EMA)
  ///                  - "double"   先Wilder后EMA的双重平滑
  ///
  /// [adxrPeriod]    当 useAdxr=true 时，用于计算 ADXR(i) = (ADX(i) + ADX(i - adxrPeriod)) / 2
  static void _computeDMIAdvanced(
    List<KLineEntity> data, {
    int period = 14,
    bool useAdxr = true,
    int adxrPeriod = 14,
    String smoothMethod = 'wilder',
  }) {
    if (data.isEmpty) return;

    // --- 第一条数据无法算DM, 先给默认0 ---
    data[0].pdi = 0;
    data[0].mdi = 0;
    data[0].adx = 0;
    data[0].adxr = 0;

    // 平滑序列: TR14, +DM14, -DM14
    // 用于保存累计值, 后续根据 smoothMethod 进行不同的平滑处理
    double trAccum = 0;
    double plusDMAccum = 0;
    double minusDMAccum = 0;

    // 上一个 KLine（用于计算DM/TR）
    double prevHigh = data[0].high;
    double prevLow = data[0].low;
    double prevClose = data[0].close;

    // ------------------------------
    //  第一次循环: 初步计算 DI 和 DX, 并做指定的平滑
    // ------------------------------
    for (int i = 1; i < data.length; i++) {
      final cur = data[i];

      final curHigh = cur.high;
      final curLow = cur.low;

      // 1) +DM / -DM
      double upMove = curHigh - prevHigh;
      double downMove = prevLow - curLow;
      double plusDM = 0, minusDM = 0;
      if (upMove > downMove && upMove > 0) {
        plusDM = upMove;
      }
      if (downMove > upMove && downMove > 0) {
        minusDM = downMove;
      }

      // 2) TR
      final range1 = (curHigh - curLow).abs();
      final range2 = (curHigh - prevClose).abs();
      final range3 = (curLow - prevClose).abs();
      final tr = [range1, range2, range3].reduce((a, b) => a > b ? a : b);

      // ============= 根据选择的平滑方式，累加/衰减 =============
      if (i == 1) {
        // 初始化
        trAccum = tr;
        plusDMAccum = plusDM;
        minusDMAccum = minusDM;
        // 直接给第二条的pdi/mdi=0, 这条会在下一步中算
        data[1].pdi = 0;
        data[1].mdi = 0;
        data[1].adx = 0;
      } else {
        switch (smoothMethod) {
          case 'ema':
            // ======== 直接用EMA衰减 ========
            // 由于EMA需要一个alpha(2/(period+1))，可根据经验选
            final alpha = 2.0 / (period + 1);
            trAccum = trAccum + alpha * (tr - trAccum);
            plusDMAccum = plusDMAccum + alpha * (plusDM - plusDMAccum);
            minusDMAccum = minusDMAccum + alpha * (minusDM - minusDMAccum);
            break;

          case 'double':
            // ======== 先Wilder再EMA（双重） ========
            // 先用Wilder公式更新, 再对累加量做一次EMA平滑
            double oldTR = trAccum,
                oldPlus = plusDMAccum,
                oldMinus = minusDMAccum;
            // (a) Wilder
            oldTR = oldTR - (oldTR / period) + tr;
            oldPlus = oldPlus - (oldPlus / period) + plusDM;
            oldMinus = oldMinus - (oldMinus / period) + minusDM;

            // (b) 在Wilder结果上再做EMA
            final alpha = 2.0 / (period + 1);
            trAccum = trAccum + alpha * (oldTR - trAccum);
            plusDMAccum = plusDMAccum + alpha * (oldPlus - plusDMAccum);
            minusDMAccum = minusDMAccum + alpha * (oldMinus - minusDMAccum);
            break;

          case 'wilder':
          default:
            // ======== Wilder经典处理 ========
            trAccum = trAccum - (trAccum / period) + tr;
            plusDMAccum = plusDMAccum - (plusDMAccum / period) + plusDM;
            minusDMAccum = minusDMAccum - (minusDMAccum / period) + minusDM;
            break;
        }
      }

      // 3) 计算 +DI / -DI
      double plusDI = trAccum == 0 ? 0 : (100 * plusDMAccum / trAccum);
      double minusDI = trAccum == 0 ? 0 : (100 * minusDMAccum / trAccum);

      // 4) 计算DX
      double sumDI = plusDI + minusDI;
      double diffDI = (plusDI - minusDI).abs();
      double dx = (sumDI == 0) ? 0 : (100 * diffDI / sumDI);

      // 5) 计算或平滑 ADX
      if (i == 1) {
        // 对第二条先初始化
        cur.adx = dx;
      } else {
        double prevAdx = data[i - 1].adx ?? 0;
        // 这里也可根据smoothMethod来衰减 ADX，示例中继续Wilder:
        cur.adx = ((prevAdx * (period - 1)) + dx) / period;
      }

      // 赋值到实体
      cur.pdi = plusDI;
      cur.mdi = minusDI;

      // 更新 prev
      prevHigh = curHigh;
      prevLow = curLow;
      prevClose = cur.close;
    }

    // ---------------------------------
    // 如果需要计算 ADXR
    // ADXR(i) = (ADX(i) + ADX(i - adxrPeriod)) / 2
    // ---------------------------------
    if (useAdxr) {
      for (int i = adxrPeriod; i < data.length; i++) {
        double adxI = data[i].adx ?? 0;
        double adxIMinusPeriod = data[i - adxrPeriod].adx ?? 0;
        data[i].adxr = (adxI + adxIMinusPeriod) / 2.0;
      }
    }
  }

  static void _computeDMI(List<KLineEntity> data, {int period = 14}) {
    if (data.isEmpty) return;

    double tr14 = 0; // 14周期的 TR 平滑
    double plusDM14 = 0; // 14周期的 +DM 平滑
    double minusDM14 = 0; // 14周期的 -DM 平滑

    // 第一个点无法算DMI，先记录当前值
    double prevHigh = data[0].high;
    double prevLow = data[0].low;
    double prevClose = data[0].close;

    // 让第0条暂时为 0
    data[0].pdi = 0;
    data[0].mdi = 0;
    data[0].adx = 0;
    data[0].adxr = 0;

    for (int i = 1; i < data.length; i++) {
      final cur = data[i];
      final curHigh = cur.high;
      final curLow = cur.low;

      // ============ 1) 计算 +DM / -DM ============
      double upMove = curHigh - prevHigh;
      double downMove = prevLow - curLow;
      double plusDM = 0, minusDM = 0;
      if (upMove > downMove && upMove > 0) {
        plusDM = upMove;
      }
      if (downMove > upMove && downMove > 0) {
        minusDM = downMove;
      }

      // ============ 2) 计算 TR ============
      double range1 = (curHigh - curLow).abs();
      double range2 = (curHigh - prevClose).abs();
      double range3 = (curLow - prevClose).abs();
      double tr = [range1, range2, range3].reduce((a, b) => a > b ? a : b);

      // ============ 3) Wilder 平滑处理 ============
      if (i == 1) {
        // 初始化
        tr14 = tr;
        plusDM14 = plusDM;
        minusDM14 = minusDM;
      } else {
        tr14 = tr14 - (tr14 / period) + tr;
        plusDM14 = plusDM14 - (plusDM14 / period) + plusDM;
        minusDM14 = minusDM14 - (minusDM14 / period) + minusDM;
      }

      // ============ 4) +DI / -DI ============
      double plusDI = tr14 == 0 ? 0 : (100 * plusDM14 / tr14);
      double minusDI = tr14 == 0 ? 0 : (100 * minusDM14 / tr14);

      // ============ 5) 计算当日 DX ============
      double sumDI = plusDI + minusDI;
      double diffDI = (plusDI - minusDI).abs();
      double dx = sumDI == 0 ? 0 : (100 * diffDI / sumDI);

      // ============ 6) 平滑 ADX ============
      if (i == 1) {
        cur.adx = dx; // 第二条先初始化
      } else {
        double prevAdx = data[i - 1].adx ?? 0;
        cur.adx = ((prevAdx * (period - 1)) + dx) / period;
      }

      // ============ 如果还需 ADXR, 这里或单独一轮再算 ============

      // 存到 KLineEntity
      cur.pdi = plusDI;
      cur.mdi = minusDI;
      // cur.adxr = ...

      // 记录上一条
      prevHigh = curHigh;
      prevLow = curLow;
      prevClose = cur.close;
    }
  }

  /// 计算 TSI (True Strength Index) 指标
  /// [r]            第一次EMA的周期(常用25)
  /// [s]            第二次EMA的周期(常用13)
  /// [signalPeriod] 信号线EMA周期(常用9)
  static void _computeTSI(List<KLineEntity> data,
      {int r = 25, int s = 13, int signalPeriod = 9}) {
    if (data.length < 2) return;

    final length = data.length;
    // 第1步: 计算每根K线的 mom(i) = close(i) - close(i-1)
    List<double> mom = List.filled(length, 0);
    List<double> absMom = List.filled(length, 0);

    for (int i = 1; i < length; i++) {
      double diff = data[i].close - data[i - 1].close;
      mom[i] = diff;
      absMom[i] = diff.abs();
    }

    // 第2步: 对 mom 和 absMom 各做 "双重EMA"：先周期r，再周期s
    // 先建数组, 分两轮
    List<double> emaR_mom = List.filled(length, 0);
    List<double> emaR_abs = List.filled(length, 0);
    double alphaR = 2.0 / (r + 1);

    // (a) 第一次EMA(周期r)
    emaR_mom[0] = mom[0]; // 第0条mom=0
    emaR_abs[0] = absMom[0]; // 第0条absMom=0

    for (int i = 1; i < length; i++) {
      emaR_mom[i] = emaR_mom[i - 1] + alphaR * (mom[i] - emaR_mom[i - 1]);
      emaR_abs[i] = emaR_abs[i - 1] + alphaR * (absMom[i] - emaR_abs[i - 1]);
    }

    // (b) 第二次EMA(周期s)
    List<double> emaRS_mom = List.filled(length, 0);
    List<double> emaRS_abs = List.filled(length, 0);
    double alphaS = 2.0 / (s + 1);

    emaRS_mom[0] = emaR_mom[0];
    emaRS_abs[0] = emaR_abs[0];
    for (int i = 1; i < length; i++) {
      emaRS_mom[i] =
          emaRS_mom[i - 1] + alphaS * (emaR_mom[i] - emaRS_mom[i - 1]);
      emaRS_abs[i] =
          emaRS_abs[i - 1] + alphaS * (emaR_abs[i] - emaRS_abs[i - 1]);
    }

    // 第3步: 计算 TSI 主线: 100 * (emaRS_mom / emaRS_abs)
    for (int i = 0; i < length; i++) {
      double denom = emaRS_abs[i];
      double tsiValue;
      if (denom.abs() < 1e-12) {
        tsiValue = 0;
      } else {
        tsiValue = (emaRS_mom[i] / denom) * 100;
      }
      // 防爆保护
      if (!tsiValue.isFinite) tsiValue = 0;
      data[i].tsi = tsiValue;
    }

    // 第4步: 计算 TSI 的信号线(对 TSI 做个 EMA)
    double alphaSignal = 2.0 / (signalPeriod + 1);
    data[0].tsiSignal = data[0].tsi ?? 0; // 初始化
    for (int i = 1; i < length; i++) {
      double prevSig = data[i - 1].tsiSignal ?? 0;
      double curTsi = data[i].tsi ?? 0;
      double sig = prevSig + alphaSignal * (curTsi - prevSig);
      if (!sig.isFinite) sig = 0;
      data[i].tsiSignal = sig;
    }
  }

  /// 计算 Ichimoku (一目均衡表/云图)
  /// [tenkanPeriod]  默认9
  /// [kijunPeriod]   默认26
  /// [senkouBPeriod] 默认52
  /// [smoothMethod]  平滑方法: 'wilder', 'ema', 'double', 'none'
  static void _computeIchimoku(
    List<KLineEntity> data, {
    int tenkanPeriod = 9,
    int kijunPeriod = 26,
    int senkouBPeriod = 52,
    String smoothMethod = 'ema',
  }) {
    final length = data.length;
    if (length == 0) return;

    // Helper functions for highest and lowest prices
    double highestHigh(List<KLineEntity> list, int endIndex, int period) {
      double hh = -double.infinity;
      int start = endIndex - period + 1;
      if (start < 0) start = 0;
      for (int idx = start; idx <= endIndex; idx++) {
        if (list[idx].high > hh) hh = list[idx].high;
      }
      return hh;
    }

    double lowestLow(List<KLineEntity> list, int endIndex, int period) {
      double ll = double.infinity;
      int start = endIndex - period + 1;
      if (start < 0) start = 0;
      for (int idx = start; idx <= endIndex; idx++) {
        if (list[idx].low < ll) ll = list[idx].low;
      }
      return ll;
    }

    // Helper function for smoothing
    double smooth(
        List<double> values, int period, String method, double lastValue) {
      if (values.isEmpty) return lastValue;
      double newValue = values.last;
      switch (method) {
        case 'wilder':
          return (lastValue * (period - 1) + newValue) / period;
        case 'ema':
          double alpha = 2 / (period + 1);
          return alpha * newValue + (1 - alpha) * lastValue;
        case 'double':
          double wilderValue = (lastValue * (period - 1) + newValue) / period;
          double alpha = 2 / (period + 1);
          return alpha * wilderValue + (1 - alpha) * lastValue;
        case 'none':
        default:
          return newValue;
      }
    }

    for (int i = 0; i < length; i++) {
      // 1) Compute Tenkan-sen (Conversion Line)
      if (i >= tenkanPeriod - 1) {
        double hh = highestHigh(data, i, tenkanPeriod);
        double ll = lowestLow(data, i, tenkanPeriod);
        double tenkan = (hh + ll) / 2.0;
        data[i].ichimokuTenkan = smooth([tenkan], tenkanPeriod, smoothMethod,
            i > 0 ? data[i - 1].ichimokuTenkan ?? 0 : 0);
      } else {
        data[i].ichimokuTenkan = null;
      }

      // 2) Compute Kijun-sen (Base Line)
      if (i >= kijunPeriod - 1) {
        double hh = highestHigh(data, i, kijunPeriod);
        double ll = lowestLow(data, i, kijunPeriod);
        double kijun = (hh + ll) / 2.0;
        data[i].ichimokuKijun = smooth([kijun], kijunPeriod, smoothMethod,
            i > 0 ? data[i - 1].ichimokuKijun ?? 0 : 0);
      } else {
        data[i].ichimokuKijun = null;
      }

      // 3) Compute Senkou Span A (Leading Span A)
      if (data[i].ichimokuTenkan != null && data[i].ichimokuKijun != null) {
        double spanA = (data[i].ichimokuTenkan! + data[i].ichimokuKijun!) / 2.0;
        data[i].ichimokuSpanA = smooth(
            [spanA],
            (tenkanPeriod + kijunPeriod) ~/ 2,
            smoothMethod,
            i > 0 ? data[i - 1].ichimokuSpanA ?? 0 : 0);
      } else {
        data[i].ichimokuSpanA = null;
      }

      // 4) Compute Senkou Span B (Leading Span B)
      if (i >= senkouBPeriod - 1) {
        double hh = highestHigh(data, i, senkouBPeriod);
        double ll = lowestLow(data, i, senkouBPeriod);
        double spanB = (hh + ll) / 2.0;
        data[i].ichimokuSpanB = smooth([spanB], senkouBPeriod, smoothMethod,
            i > 0 ? data[i - 1].ichimokuSpanB ?? 0 : 0);
      } else {
        data[i].ichimokuSpanB = null;
      }

      // 5) Chikou Span (Lagging Span) - no smoothing needed as it's just the closing price
      data[i].ichimokuChikou = data[i].close;
    }
  }

  /// 计算Parabolic SAR(抛物线转向指标)
  /// [accInit]    初始加速因子(默认0.02)
  /// [accStep]    每次更新的加速步长(默认0.02)
  /// [accMax]     最大加速因子(默认0.2)
  static void _computePSAR(
    List<KLineEntity> data, {
    double accInit = 0.02,
    double accStep = 0.02,
    double accMax = 0.2,
  }) {
    final length = data.length;
    if (length < 2) return;

    // 第1步：根据前两根K线判断初始趋势:
    // 如果 close(1) > close(0)，就Up，否则Down
    bool isUp = data[1].close > data[0].close;
    // 初始psar等
    // sar指示值, ep表示极点(最高价或最低价), af=加速因子
    double sar = isUp ? data[0].low : data[0].high;
    double ep = isUp ? data[0].high : data[0].low;
    double af = accInit;

    // 先给第0条、1条一个初始值
    data[0].psar = sar; // 或设置为null也可
    data[1].psar = sar; // 这样第1条不会缺失

    for (int i = 2; i < length; i++) {
      data[i].psarIsUp = isUp;
      final cur = data[i];

      // 2) 计算新的sar
      double newSar = sar + af * (ep - sar);

      // 防止溢出
      if (!newSar.isFinite) {
        newSar = sar;
      }

      // 3) 判断趋势(如果当前是上升趋势)
      if (isUp) {
        // 新的SAR不能高于 前2根k线的最低价
        double min1 = data[i - 1].low;
        double min2 = data[i - 2].low;
        if (newSar > min1) newSar = min1;
        if (newSar > min2) newSar = min2;

        // 如果现在的SAR >= 当前k线的low(说明趋势可能翻转)
        if (newSar > cur.low) {
          // 趋势翻转
          isUp = false;
          newSar = ep; // sar重置为上一轮的ep
          // ep改为当前的low
          ep = cur.low;
          af = accInit; // 加速因子重置
        } else {
          // 趋势未翻转
          // 如果当前high > 旧的ep => ep=high & 加速因子+=step
          if (cur.high > ep) {
            ep = cur.high;
            af += accStep;
            if (af > accMax) af = accMax;
          }
        }
      } else {
        // 当前是下行趋势
        // 新的SAR不能低于 前2根k线的最高价
        double max1 = data[i - 1].high;
        double max2 = data[i - 2].high;
        if (newSar < max1) newSar = max1;
        if (newSar < max2) newSar = max2;

        // 如果新的SAR <= 当前k线的high => 趋势翻转
        if (newSar < cur.high) {
          isUp = true;
          newSar = ep; // sar重置
          ep = cur.high;
          af = accInit;
        } else {
          // 下行趋势继续
          if (cur.low < ep) {
            ep = cur.low;
            af += accStep;
            if (af > accMax) af = accMax;
          }
        }
      }

      sar = newSar;
      cur.psar = sar;
    }
  }

  /// 计算 Vortex 指标 (+VI, -VI)
  /// [period] 通常默认为 14
  static void _computeVortex(List<KLineEntity> data,
      {int period = 14, String smoothMethod = 'wilder'}) {
    final length = data.length;
    if (length < 2) {
      // 数据太少, 全部置0或null
      for (int i = 0; i < length; i++) {
        data[i].viPlus = 0;
        data[i].viMinus = 0;
      }
      return;
    }

    // 1) 先构建数组存 +VM, -VM, TR
    List<double> plusVM = List.filled(length, 0);
    List<double> minusVM = List.filled(length, 0);
    List<double> trArr = List.filled(length, 0);

    // 第0条K线没法计算VM / TR
    plusVM[0] = 0;
    minusVM[0] = 0;
    trArr[0] = 0;

    for (int i = 1; i < length; i++) {
      double high = data[i].high;
      double low = data[i].low;
      double prevHigh = data[i - 1].high;
      double prevLow = data[i - 1].low;
      double prevClose = data[i - 1].close;

      // +VM_i = |High_i - Low_{i-1}|
      plusVM[i] = (high - prevLow).abs();
      // -VM_i = |Low_i - High_{i-1}|
      minusVM[i] = (low - prevHigh).abs();

      // TR_i = max( High_i - Low_i, |High_i - Close_{i-1}|, |Low_i - Close_{i-1}| )
      double a = high - low;
      double b = (high - prevClose).abs();
      double c = (low - prevClose).abs();
      trArr[i] = [a, b, c].reduce((x, y) => x > y ? x : y);
    }

    // 2) 计算 +VI / -VI with smoothing
    for (int i = 0; i < length; i++) {
      if (i < period - 1) {
        // 前 period-1 条数据不足
        data[i].viPlus = 0;
        data[i].viMinus = 0;
      } else {
        // sum +VM, -VM, TR from i-period+1..i
        double sumPlus = 0, sumMinus = 0, sumTR = 0;
        int start = i - period + 1;
        for (int j = start; j <= i; j++) {
          sumPlus += plusVM[j];
          sumMinus += minusVM[j];
          sumTR += trArr[j];
        }
        double viP = 0, viM = 0;
        if (sumTR.abs() < 1e-12) {
          // 避免分母0
          viP = 0;
          viM = 0;
        } else {
          viP = sumPlus / sumTR;
          viM = sumMinus / sumTR;
        }

        // 应用平滑处理
        if (i > period - 1) {
          switch (smoothMethod) {
            case 'wilder':
              viP = (data[i - 1].viPlus! * (period - 1) + viP) / period;
              viM = (data[i - 1].viMinus! * (period - 1) + viM) / period;
              break;
            // Here you could add other smoothing methods like 'ema' or 'double' if needed
          }
        }

        // 防止溢出
        if (!viP.isFinite) viP = 0;
        if (!viM.isFinite) viM = 0;

        data[i].viPlus = viP;
        data[i].viMinus = viM;
      }
    }
  }

  /// 计算 ATR (Average True Range) 指标
  /// [period] 默认14 (Wilder平滑)
  /// [smoothMethod] 平滑方法: 'wilder', 'ema', 'double', 'none'
  static void _computeATR(List<KLineEntity> data,
      {int period = 14, String smoothMethod = 'ema'}) {
    final length = data.length;
    if (length == 0) return;

    // 存放每条 K 的 TR 值
    List<double> trArr = List.filled(length, 0);

    // 1) 计算TR
    // 第0条K线没有前一日close, 通常 TR= high-low
    if (length > 0) {
      trArr[0] = data[0].high - data[0].low;
    }
    for (int i = 1; i < length; i++) {
      double high = data[i].high;
      double low = data[i].low;
      double prevClose = data[i - 1].close;

      double range1 = high - low;
      double range2 = (high - prevClose).abs();
      double range3 = (low - prevClose).abs();
      double tr = [range1, range2, range3].reduce((a, b) => a > b ? a : b);
      trArr[i] = tr;
    }

    // 2) 计算ATR with different smoothing methods
    data[0].atr = trArr[0]; // No smoothing for the first data point

    double sumTR = trArr[0];
    for (int i = 1; i < length; i++) {
      sumTR += trArr[i];
      if (i < period) {
        // i=1~13 => 直接简单平均, applicable for all smoothMethods
        data[i].atr = sumTR / (i + 1);
      } else {
        double prevAtr = data[i - 1].atr ?? 0;
        double curAtr = 0;
        switch (smoothMethod) {
          case 'wilder':
            // Wilder Smoothing: ATR(i)=((prevAtr*(period-1)) + TR(i)) / period
            curAtr = (prevAtr * (period - 1) + trArr[i]) / period;
            break;
          case 'ema':
            // EMA Smoothing
            double alpha = 2 / (period + 1);
            curAtr = alpha * trArr[i] + (1 - alpha) * prevAtr;
            break;
          case 'double':
            // Double Smoothing: Wilder then EMA
            double wilderAtr = (prevAtr * (period - 1) + trArr[i]) / period;
            double alpha = 2 / (period + 1);
            curAtr = alpha * wilderAtr + (1 - alpha) * prevAtr;
            break;
          case 'none':
            // No smoothing, just use TR directly
            curAtr = trArr[i];
            break;
        }

        // 防止NaN / Infinity
        if (!curAtr.isFinite) {
          curAtr = prevAtr;
        }
        data[i].atr = curAtr;
      }
    }
  }

  /// 计算 Historical Volatility (HV)
  /// [period] 窗口期, 默认14
  /// [annualFactor] 年化系数, 常见252(交易日), 或365(自然日)
  /// [smoothMethod] 平滑方法: 'wilder', 'ema', 'double'
  /// 例如: HV= stdev( ln(close_i/close_{i-1}) ) over `period` * sqrt(annualFactor)
  static void _computeHV(
    List<KLineEntity> data, {
    int period = 14,
    double annualFactor = 365.0,
    String smoothMethod = 'none',
  }) {
    final length = data.length;
    if (length < 2) return;

    // 1) 先构建对数收益数组(从第1条开始)
    // 第0条无法算对数收益, 设为0或null
    List<double> logReturns = List.filled(length, 0.0);

    for (int i = 1; i < length; i++) {
      double cPrev = data[i - 1].close;
      double cCur = data[i].close;
      if (cPrev <= 0 || cCur <= 0) {
        // 防止除0或负数(极端情况下)
        logReturns[i] = 0;
      } else {
        double r = (cCur / cPrev).abs(); // abs() 避免负
        if (r > 0) {
          double lr = math.log(r);
          if (!lr.isFinite) lr = 0;
          logReturns[i] = lr;
        } else {
          logReturns[i] = 0;
        }
      }
    }

    // 2) 对 i >= period, 计算过去 [i-period+1 .. i] 的 stdev(logReturns)
    // 并 annualize, 存到 data[i].hv with smoothing
    for (int i = 0; i < length; i++) {
      if (i < period) {
        data[i].hv = 0; // 或 null
      } else {
        // 取 period 个对数收益
        int start = i - period + 1;
        double sumR = 0;
        for (int j = start; j <= i; j++) {
          sumR += logReturns[j];
        }
        double meanR = sumR / period;

        // 计算方差
        double sumVar = 0;
        for (int j = start; j <= i; j++) {
          double diff = logReturns[j] - meanR;
          sumVar += diff * diff;
        }
        double variance = sumVar / (period - 1); // 或 period

        // 标准差
        double stdDev = variance >= 0 ? math.sqrt(variance) : 0;

        // Apply smoothing on the standard deviation before annualizing
        double smoothedStdDev = stdDev;
        if (i > period) {
          switch (smoothMethod) {
            case 'wilder':
              smoothedStdDev =
                  (data[i - 1].hv! / 100 * (period - 1) + stdDev) / period;
              break;
            case 'ema':
              double alpha = 2 / (period + 1);
              smoothedStdDev =
                  alpha * stdDev + (1 - alpha) * (data[i - 1].hv! / 100);
              break;
            case 'double':
              // First, Wilder smoothing
              double wilderStdDev =
                  (data[i - 1].hv! / 100 * (period - 1) + stdDev) / period;
              // Then, EMA smoothing
              double alpha = 2 / (period + 1);
              smoothedStdDev =
                  alpha * wilderStdDev + (1 - alpha) * (data[i - 1].hv! / 100);
              break;
            default:
              smoothedStdDev = stdDev;
          }
        }

        // annualize
        double hvVal = smoothedStdDev * math.sqrt(annualFactor);

        // 如果想要显示百分比 => hvVal*=100;
        hvVal *= 100; //常见做法: 乘100再显示 -> 25.3 表示25.3%

        // 防止溢出
        if (!hvVal.isFinite) hvVal = 0;
        data[i].hv = hvVal;
      }
    }
  }

  /// 计算VWAP(Volume Weighted Average Price)
  /// [useTypicalPrice] 是否用 typicalPrice=(high+low+close)/3 (常见)
  ///                   或也可以用 (open+close)/2, 看需求
  /// 本示例默认 typicalPrice=(H+L+C)/3.
  static void _computeVWAP(List<KLineEntity> data,
      {bool useTypicalPrice = true}) {
    final length = data.length;
    if (length == 0) return;

    double cumulativeVol = 0; // 累计成交量
    double cumulativeVolPrice = 0; // 累计 (price * vol)

    for (int i = 0; i < length; i++) {
      double vol = data[i].vol;
      if (vol < 0) vol = 0; // 防止极端或错误数据

      double price;
      if (useTypicalPrice) {
        price = (data[i].high + data[i].low + data[i].close) / 3.0;
      } else {
        // 若想使用(open+close)/2, 或 purely close,可以写:
        // price = (data[i].open + data[i].close)/2;
        price = data[i].close;
      }

      cumulativeVol += vol;
      cumulativeVolPrice += vol * price;

      if (cumulativeVol.abs() < 1e-12) {
        // 防止分母过小/为0
        data[i].vwap = price; // or 0
      } else {
        double v = cumulativeVolPrice / cumulativeVol;
        if (!v.isFinite) v = price; // 防NaN/Infinity
        data[i].vwap = v;
      }
    }
  }

  /// 计算OBV(能量潮) + 对OBV再做EMA平滑(可选, periodObvEma)
  /// [periodObvEma] 若为null或<=1, 表示不做平滑
  static void _computeOBVAdvanced(
    List<KLineEntity> data, {
    bool useFirstVolumeAsInitial = true,
    int? periodObvEma = 10,
  }) {
    final length = data.length;
    if (length == 0) return;

    // 1) 基础 OBV
    double obvPrev = useFirstVolumeAsInitial && length > 0 ? data[0].vol : 0;
    if (length > 0) {
      data[0].obv = obvPrev;
    }

    for (int i = 1; i < length; i++) {
      final cur = data[i];
      final prev = data[i - 1];

      double obv = obvPrev; // 默认继承上一个

      if (cur.close > prev.close) {
        obv = obvPrev + cur.vol;
      } else if (cur.close < prev.close) {
        obv = obvPrev - cur.vol;
      }
      // else close相等 => obv不变

      cur.obv = obv;
      obvPrev = obv;
    }

    // 2) 对 OBV 做EMA平滑 (可选)
    // periodObvEma=10为例, alpha=2/(10+1)=0.1818...
    if (periodObvEma != null && periodObvEma > 1) {
      final double alpha = 2.0 / (periodObvEma + 1);
      data[0].obvEma = data[0].obv; // 初始化

      for (int i = 1; i < length; i++) {
        double prevEma = data[i - 1].obvEma ?? data[i - 1].obv ?? 0;
        double curObv = data[i].obv ?? 0;
        double newEma = prevEma + alpha * (curObv - prevEma);

        // 防止NaN/Infinity
        if (!newEma.isFinite) {
          newEma = prevEma;
        }
        data[i].obvEma = newEma;
      }
    } else {
      // 不做平滑, 直接把 obvEma = obv
      for (int i = 0; i < length; i++) {
        data[i].obvEma = data[i].obv;
      }
    }
  }

  /// 计算 Accumulation/Distribution (A/D) Line
  /// A/D(i) = A/D(i-1) + ((close - low) - (high - close))/(high - low) * volume
  static void _computeADLine(List<KLineEntity> data) {
    final length = data.length;
    if (length == 0) return;

    double adPrev = 0;
    if (length > 0) {
      data[0].adl = 0; // 或把 0 作为初始
    }
    for (int i = 1; i < length; i++) {
      final cur = data[i];

      double h = cur.high;
      double l = cur.low;
      double c = cur.close;
      double v = cur.vol;

      double multiplier = 0;
      double hlRange = (h - l).abs();
      if (hlRange > 1e-12) {
        multiplier = ((c - l) - (h - c)) / hlRange;
        // => (2c - h - l)/(h-l)
      }
      double moneyFlowVol = multiplier * v;
      double adVal = adPrev + moneyFlowVol;

      cur.adl = adVal;
      adPrev = adVal;
    }
  }

  /// 用本地历史波动率当作"VIX"近似
  /// 仅作演示，不代表真实CBOE VIX
  static void _computeVIXLocally(List<KLineEntity> data,
      {int period = 14, double annualFactor = 252}) {
    if (data.length < 2) return;

    // 先算出 logReturns, 类似 HV
    List<double> logReturns = List.filled(data.length, 0);
    for (int i = 1; i < data.length; i++) {
      double cPrev = data[i - 1].close;
      double cCur = data[i].close;
      if (cPrev <= 0 || cCur <= 0) {
        logReturns[i] = 0;
      } else {
        double r = (cCur / cPrev).abs();
        double lr = math.log(r);
        if (!lr.isFinite) lr = 0;
        logReturns[i] = lr;
      }
    }

    // 计算 rolling 标准差 -> annualize -> (可再乘100)
    for (int i = 0; i < data.length; i++) {
      if (i < period) {
        data[i].vix = 0;
      } else {
        int start = i - period + 1;
        double sumR = 0;
        for (int j = start; j <= i; j++) {
          sumR += logReturns[j];
        }
        double meanR = sumR / period;
        double sumVar = 0;
        for (int j = start; j <= i; j++) {
          double diff = logReturns[j] - meanR;
          sumVar += diff * diff;
        }
        double variance = sumVar / (period - 1);
        double stdDev = variance >= 0 ? math.sqrt(variance) : 0;
        double localVIX =
            stdDev * math.sqrt(annualFactor) * 100; // => 如 22.5表示22.5%

        if (!localVIX.isFinite) localVIX = 0;
        data[i].vix = localVIX;
      }
    }
  }

  /// 仅计算 ADX (不再输出 +DI, -DI 字段)，以便单独用作副图
  /// [period] 常见默认14
  static void _computeADX(List<KLineEntity> data, {int period = 14}) {
    final length = data.length;
    if (length < 2) return;

    // 1) 准备存 DM/TR
    List<double> plusDM = List.filled(length, 0);
    List<double> minusDM = List.filled(length, 0);
    List<double> trArr = List.filled(length, 0);

    // 2) 计算每根K线的 +DM, -DM, TR
    // 第0条无法算DM/TR，先给0
    for (int i = 1; i < length; i++) {
      double high = data[i].high;
      double low = data[i].low;
      double prevHigh = data[i - 1].high;
      double prevLow = data[i - 1].low;
      double upMove = high - prevHigh;
      double downMove = prevLow - low;
      plusDM[i] = (upMove > downMove && upMove > 0) ? upMove : 0;
      minusDM[i] = (downMove > upMove && downMove > 0) ? downMove : 0;

      double range1 = (high - low).abs();
      double range2 = (high - data[i - 1].close).abs();
      double range3 = (low - data[i - 1].close).abs();
      trArr[i] = [range1, range2, range3].reduce((a, b) => a > b ? a : b);
    }

    // 3) Wilder 平滑(累加) => DM14 / TR14
    double plusDM14 = 0;
    double minusDM14 = 0;
    double tr14 = 0;

    // 前面 period-1 条先做初始化
    for (int i = 1; i <= period; i++) {
      plusDM14 += plusDM[i];
      minusDM14 += minusDM[i];
      tr14 += trArr[i];
    }
    double plusDI = (tr14 == 0) ? 0 : (100 * plusDM14 / tr14);
    double minusDI = (tr14 == 0) ? 0 : (100 * minusDM14 / tr14);

    // 计算第 period 根 dx & adx
    double dx = ((plusDI - minusDI).abs() /
            (plusDI + minusDI == 0 ? 1 : (plusDI + minusDI))) *
        100;
    data[period].adx = dx; // 第 period 条上才第一次有 ADX

    double adxPrev = dx; // 用于后续平滑
    for (int i = period + 1; i < length; i++) {
      // 逐根用 Wilder 方式更新 DM14, TR14
      plusDM14 = plusDM14 - (plusDM14 / period) + plusDM[i];
      minusDM14 = minusDM14 - (minusDM14 / period) + minusDM[i];
      tr14 = tr14 - (tr14 / period) + trArr[i];

      plusDI = (tr14 == 0) ? 0 : (100 * plusDM14 / tr14);
      minusDI = (tr14 == 0) ? 0 : (100 * minusDM14 / tr14);

      dx = ((plusDI - minusDI).abs() /
              (plusDI + minusDI == 0 ? 1 : (plusDI + minusDI))) *
          100;

      double adx = ((adxPrev * (period - 1)) + dx) / period;
      if (!adx.isFinite) adx = adxPrev;
      data[i].adx = adx;
      adxPrev = adx;
    }
  }

  /// 计算标准差(StdDev) 对 close 做 rolling (period)
  /// [period] 默认14
  /// [sample] 是否用Sample标准差(分母=period-1)，否则Population(分母=period)
  static void _computeStdDev(List<KLineEntity> data,
      {int period = 14, bool sample = true}) {
    final length = data.length;
    if (length < 2) return;

    for (int i = 0; i < length; i++) {
      if (i < period - 1) {
        // 数据不足period条时，可设为null或0
        data[i].stdDev = 0;
      } else {
        double sumClose = 0;
        int start = i - period + 1;
        for (int j = start; j <= i; j++) {
          sumClose += data[j].close;
        }
        double mean = sumClose / period;

        double sumVar = 0;
        for (int j = start; j <= i; j++) {
          double diff = data[j].close - mean;
          sumVar += diff * diff;
        }
        num divisor = sample ? (period - 1) : period; // sample or population
        double variance = sumVar / (divisor == 0 ? 1 : divisor);
        double stdv = variance >= 0 ? math.sqrt(variance) : 0;

        if (!stdv.isFinite) stdv = 0;
        data[i].stdDev = stdv;
      }
    }
  }

  /// 计算 OsMA = (DIF - DEA)
  /// 也可叫 "MACD 柱状图"
  static void _computeOsMA(List<KLineEntity> data,
      {int shortPeriod = 12, int longPeriod = 26, int signalPeriod = 9}) {
    final length = data.length;
    if (length == 0) return;

    // 1) 先算出 EMA(short) & EMA(long)
    List<double> emaShort = List.filled(length, 0);
    List<double> emaLong = List.filled(length, 0);

    double alphaShort = 2 / (shortPeriod + 1);
    double alphaLong = 2 / (longPeriod + 1);

    // 第0条初始化
    emaShort[0] = data[0].close;
    emaLong[0] = data[0].close;

    for (int i = 1; i < length; i++) {
      double c = data[i].close;
      emaShort[i] = emaShort[i - 1] + alphaShort * (c - emaShort[i - 1]);
      emaLong[i] = emaLong[i - 1] + alphaLong * (c - emaLong[i - 1]);
    }

    // 2) DIF = emaShort - emaLong
    List<double> difArr = List.filled(length, 0);
    for (int i = 0; i < length; i++) {
      difArr[i] = emaShort[i] - emaLong[i];
    }

    // 3) DEA(=Signal line) = EMA(dif, signalPeriod)
    List<double> deaArr = List.filled(length, 0);
    double alphaSignal = 2 / (signalPeriod + 1);
    deaArr[0] = difArr[0]; // 初始化
    for (int i = 1; i < length; i++) {
      deaArr[i] = deaArr[i - 1] + alphaSignal * (difArr[i] - deaArr[i - 1]);
    }

    // 4) OsMA = DIF - DEA
    for (int i = 0; i < length; i++) {
      double osmaVal = difArr[i] - deaArr[i];
      if (!osmaVal.isFinite) osmaVal = 0;
      data[i].osma = osmaVal;
    }
  }

  /// 计算 Stochastic Oscillator: %K(14), %D(3) (默认)
  /// (示例: slow K=14, D=3, 用SMA做%D)
  static void _computeStochastic(List<KLineEntity> data,
      {int periodK = 14, int periodD = 3, String smoothMethod = 'ema'}) {
    final length = data.length;
    if (length < 2) return;

    // 1) 先算 %K with smoothing
    for (int i = 0; i < length; i++) {
      if (i < periodK - 1) {
        // 数据不足periodK => stochK设为 null或0
        data[i].stochK = 0;
      } else {
        double highest = -double.infinity;
        double lowest = double.infinity;
        int start = i - periodK + 1;
        for (int j = start; j <= i; j++) {
          double h = data[j].high;
          double l = data[j].low;
          if (h > highest) highest = h;
          if (l < lowest) lowest = l;
        }
        double c = data[i].close;
        double denominator = (highest - lowest).abs();
        double kValue = 0;
        if (denominator < 1e-12) {
          // 避免分母0 => 收盘价基本跟最高最低相等
          kValue = 100; // 或者0, 这里设为100
        } else {
          kValue = (c - lowest) * 100 / denominator;
        }

        // 应用平滑处理
        if (i > periodK - 1) {
          switch (smoothMethod) {
            case 'wilder':
              kValue = (data[i - 1].stochK! * (periodK - 1) + kValue) / periodK;
              break;
            case 'ema':
              double alpha = 2 / (periodK + 1);
              kValue = alpha * kValue + (1 - alpha) * data[i - 1].stochK!;
              break;
            case 'double':
              // First, Wilder smoothing
              double wilderK =
                  (data[i - 1].stochK! * (periodK - 1) + kValue) / periodK;
              // Then, EMA smoothing on Wilder result
              double alpha = 2 / (periodK + 1);
              kValue = alpha * wilderK + (1 - alpha) * data[i - 1].stochK!;
              break;
          }
        }

        if (!kValue.isFinite) kValue = 0;
        data[i].stochK = kValue;
      }
    }

    // 2) 再算 %D = 对 %K 的 [periodD]日SMA
    for (int i = 0; i < length; i++) {
      if (i < periodK - 1 + periodD - 1) {
        // 前面%K还没稳定, D也不足
        data[i].stochD = 0;
      } else {
        double sumK = 0;
        for (int j = i - (periodD - 1); j <= i; j++) {
          sumK += data[j].stochK ?? 0;
        }
        double dValue = sumK / periodD;
        if (!dValue.isFinite) dValue = 0;
        data[i].stochD = dValue;
      }
    }
  }

  /// 计算 Williams’ %R
  /// [period] 常见默认14
  /// 结果范围通常 -100(超卖) ~ 0(超买)
  static void _computeWPR(List<KLineEntity> data, {int period = 14}) {
    final length = data.length;
    if (length < 1) return;

    for (int i = 0; i < length; i++) {
      if (i < period - 1) {
        // 数据不足
        data[i].wpr = -50; // 或null
      } else {
        double highest = -double.infinity;
        double lowest = double.infinity;
        int start = i - period + 1;
        for (int j = start; j <= i; j++) {
          double h = data[j].high;
          double l = data[j].low;
          if (h > highest) highest = h;
          if (l < lowest) lowest = l;
        }
        double c = data[i].close;
        double denominator = (highest - lowest).abs();
        double wprVal = 0;
        if (denominator < 1e-12) {
          // 防止分母=0
          wprVal = 0;
        } else {
          wprVal = ((highest - c) / denominator) * (-100);
        }
        if (!wprVal.isFinite) {
          wprVal = 0;
        }
        data[i].wpr = wprVal;
      }
    }
  }

  /// 计算 DeMarker 指标 (DeM)，默认周期14
  /// DeMax(i)= max(High(i)-High(i-1), 0), DeMin(i)= max(Low(i-1)-Low(i), 0)
  /// DeM(i)= Sum(DeMax,14)/[Sum(DeMax,14)+Sum(DeMin,14)]
  static void _computeDeMarker(List<KLineEntity> data, {int period = 14}) {
    final length = data.length;
    if (length < 2) return;

    // 1) 先计算 DeMax / DeMin 数组
    List<double> deMaxArr = List.filled(length, 0);
    List<double> deMinArr = List.filled(length, 0);

    // i=0 无法和前一条比，对第0条设为0
    for (int i = 1; i < length; i++) {
      double high0 = data[i - 1].high;
      double high1 = data[i].high;
      double low0 = data[i - 1].low;
      double low1 = data[i].low;

      double deMax = 0;
      if (high1 > high0) {
        double diff = high1 - high0;
        if (diff > 0) deMax = diff;
      }
      deMaxArr[i] = deMax;

      double deMin = 0;
      if (low1 < low0) {
        double diff = low0 - low1;
        if (diff > 0) deMin = diff;
      }
      deMinArr[i] = deMin;
    }

    // 2) rolling sum of DeMax, DeMin over 'period'
    //    DeM= sum(DeMax)/ [sum(DeMax)+sum(DeMin)]
    for (int i = 0; i < length; i++) {
      if (i < period) {
        // 数据不足period
        data[i].dem = 0;
      } else {
        double sumMax = 0;
        double sumMin = 0;
        int start = i - period + 1;
        for (int j = start; j <= i; j++) {
          sumMax += deMaxArr[j];
          sumMin += deMinArr[j];
        }
        double denominator = sumMax + sumMin;
        double demValue = 0;
        if (denominator.abs() < 1e-12) {
          demValue = 0;
        } else {
          demValue = sumMax / denominator; // => in [0,1]
        }
        data[i].dem = demValue.isFinite ? demValue : 0;
      }
    }
  }

  /// 计算 Momentum 指标: Momentum(i) = Close(i) - Close(i - period)
  /// (也可改成比率( *100 ), 同理)
  static void _computeMomentum(List<KLineEntity> data, {int period = 10}) {
    final length = data.length;
    if (length == 0) return;

    for (int i = 0; i < length; i++) {
      if (i < period) {
        // 数据不足period => 先赋值0或null
        data[i].momentum = 0;
      } else {
        double currentClose = data[i].close;
        double pastClose = data[i - period].close;
        double momValue = currentClose - pastClose; // 差值
        if (!momValue.isFinite) momValue = 0;
        data[i].momentum = momValue;
      }
    }
  }

  /// 计算Money Flow Index (MFI)
  /// [period] 默认14
  static void _computeMFI(List<KLineEntity> data, {int period = 14}) {
    final length = data.length;
    if (length < 2) return;

    // 先存 typicalPrice & rawMoneyFlow
    // 并判断本条typicalPrice vs. 前条typicalPrice => positiveFlow或negativeFlow
    // i=0无法和前条比 => 先设
    List<double> posFlowArr = List.filled(length, 0);
    List<double> negFlowArr = List.filled(length, 0);

    // 计算第0条 typicalPrice & rawFlow
    // 无前一条可比 => posFlow=0, negFlow=0
    posFlowArr[0] = 0;
    negFlowArr[0] = 0;

    // i=1..end
    for (int i = 1; i < length; i++) {
      double tp = (data[i].high + data[i].low + data[i].close) / 3.0;
      double rmf = tp * data[i].vol;

      // 与前条tp对比
      double prevTp =
          (data[i - 1].high + data[i - 1].low + data[i - 1].close) / 3.0;
      if (tp > prevTp) {
        posFlowArr[i] = rmf;
        negFlowArr[i] = 0;
      } else if (tp < prevTp) {
        posFlowArr[i] = 0;
        negFlowArr[i] = rmf;
      } else {
        // tp == prevTp => 无显著资金流向
        posFlowArr[i] = 0;
        negFlowArr[i] = 0;
      }
    }

    // 计算过去period的 sumPosFlow & sumNegFlow => MFI
    for (int i = 0; i < length; i++) {
      if (i < period) {
        // 数据不足 => MFI=0或null
        data[i].mfi = 0;
      } else {
        double sumPos = 0, sumNeg = 0;
        int start = i - period + 1;
        for (int j = start; j <= i; j++) {
          sumPos += posFlowArr[j];
          sumNeg += negFlowArr[j];
        }
        if (sumNeg < 1e-12) {
          // 防止分母=0 => 全是posFlow
          data[i].mfi = 100;
        } else {
          double mfr = sumPos / sumNeg;
          double mfiVal =
              100 - (100 / (1 + mfr)); // = 100 * sumPos/(sumPos+sumNeg)
          if (!mfiVal.isFinite) mfiVal = 0;
          data[i].mfi = mfiVal;
        }
      }
    }
  }

  /// 计算 Envelopes
  /// [period] 默认20, [shiftPercent] 默认0.02 (2%)
  static void _computeEnvelopes(List<KLineEntity> data,
      {int period = 20, double shiftPercent = 0.02}) {
    final length = data.length;
    if (length < 1) return;

    for (int i = 0; i < length; i++) {
      if (i < period - 1) {
        data[i].envMid = null;
        data[i].envUp = null;
        data[i].envDn = null;
      } else {
        // 1) 计算过去period条close的SMA
        double sumClose = 0;
        int start = i - period + 1;
        for (int j = start; j <= i; j++) {
          sumClose += data[j].close;
        }
        double mid = sumClose / period;

        // 2) 上下轨
        double up = mid * (1 + shiftPercent);
        double dn = mid * (1 - shiftPercent);

        data[i].envMid = mid;
        data[i].envUp = up;
        data[i].envDn = dn;
      }
    }
  }

  /// 计算简单的Volatility Indicator = 100 * ATR(period)/Close
  /// [period] 默认14
  static void _computeVolIndicator(List<KLineEntity> data,
      {int period = 14, String smoothMethod = 'ema'}) {
    final length = data.length;
    if (length < 2) return;

    // 1) 先用最直观方法计算TR
    List<double> trArr = List.filled(length, 0);

    // 第0条无法与前一条比 => 先用 (high0 - low0)
    trArr[0] = data[0].high - data[0].low;
    for (int i = 1; i < length; i++) {
      double high = data[i].high;
      double low = data[i].low;
      double prevClose = data[i - 1].close;

      double range1 = (high - low).abs();
      double range2 = (high - prevClose).abs();
      double range3 = (low - prevClose).abs();
      trArr[i] = [range1, range2, range3].reduce((a, b) => a > b ? a : b);
    }

    // 2) 计算ATR with different smoothing methods
    List<double> atrArr = List.filled(length, 0);

    // Initialize with simple average for the first 'period' data points
    double sumTR = 0;
    for (int i = 0; i < period && i < length; i++) {
      sumTR += trArr[i];
    }
    if (period <= length) {
      atrArr[period - 1] = sumTR / period;
    }

    for (int i = period; i < length; i++) {
      switch (smoothMethod) {
        case 'wilder':
          double prevAtr = atrArr[i - 1];
          atrArr[i] = ((prevAtr * (period - 1)) + trArr[i]) / period;
          break;
        case 'ema':
          double alpha = 2 / (period + 1);
          atrArr[i] = alpha * trArr[i] + (1 - alpha) * atrArr[i - 1];
          break;
        case 'double':
          // First, Wilder smoothing
          double wilderAtr =
              ((atrArr[i - 1] * (period - 1)) + trArr[i]) / period;
          // Then, EMA smoothing on Wilder result
          double alpha = 2 / (period + 1);
          atrArr[i] = alpha * wilderAtr + (1 - alpha) * atrArr[i - 1];
          break;
      }
    }

    // 3) volIndicator(i) = (ATR(i)/close(i))*100
    for (int i = 0; i < length; i++) {
      if (i < period - 1) {
        data[i].volIndicator = 0;
      } else {
        double close = data[i].close;
        double atr = atrArr[i];
        if (close.abs() < 1e-12) {
          data[i].volIndicator = 0;
        } else {
          double volInd = (atr / close) * 100;
          if (!volInd.isFinite) volInd = 0;
          data[i].volIndicator = volInd;
        }
      }
    }
  }

  /// 计算 Aroon 指标的增强版
  /// [period]        常见默认14
  /// [calcOsc]       是否计算Aroon Oscillator
  /// [smoothMethod]  使用何种平滑算法:
  ///                  - "wilder"   经典Wilder平滑 (默认)
  ///                  - "ema"      指数平滑(EMA)
  ///                  - "double"   先Wilder后EMA的双重平滑
  static void _computeAroonAdvanced(
    List<KLineEntity> data, {
    int period = 14,
    bool calcOsc = true,
    String smoothMethod = 'ema',
  }) {
    final length = data.length;
    if (length < period) {
      // 少于period，计算不出来或只给默认值
      for (int i = 0; i < length; i++) {
        data[i].aroonUp = 0;
        data[i].aroonDown = 0;
        if (calcOsc) data[i].aroonOsc = 0;
      }
      return;
    }

    for (int i = 0; i < length; i++) {
      // 计算区间 [i - period + 1 .. i]，需判越界
      int start = i - period + 1;
      if (start < 0) start = 0; // 不够周期就从0开始
      double highest = -double.infinity;
      double lowest = double.infinity;
      int idxHigh = i;
      int idxLow = i;

      // 在过去 period 根(或到0)里找最高价/最低价以及它们所在索引
      for (int j = start; j <= i; j++) {
        double h = data[j].high;
        double l = data[j].low;
        if (h > highest) {
          highest = h;
          idxHigh = j;
        }
        if (l < lowest) {
          lowest = l;
          idxLow = j;
        }
      }

      // 计算 Up / Down
      double up = 100.0 * (period - (i - idxHigh)) / period;
      double down = 100.0 * (period - (i - idxLow)) / period;

      // 防止溢出
      if (!up.isFinite) up = 0;
      if (!down.isFinite) down = 0;

      // 平滑处理
      if (i > 0) {
        switch (smoothMethod) {
          case 'wilder':
            up = (data[i - 1].aroonUp! * (period - 1) + up) / period;
            down = (data[i - 1].aroonDown! * (period - 1) + down) / period;
            break;
          case 'ema':
            final alpha = 2 / (period + 1);
            up = alpha * up + (1 - alpha) * data[i - 1].aroonUp!;
            down = alpha * down + (1 - alpha) * data[i - 1].aroonDown!;
            break;
          case 'double':
            // 先 Wilder 平滑
            double tempUp = (data[i - 1].aroonUp! * (period - 1) + up) / period;
            double tempDown =
                (data[i - 1].aroonDown! * (period - 1) + down) / period;
            // 再 EMA 平滑
            final alpha = 2 / (period + 1);
            up = alpha * tempUp + (1 - alpha) * data[i - 1].aroonUp!;
            down = alpha * tempDown + (1 - alpha) * data[i - 1].aroonDown!;
            break;
        }
      }

      data[i].aroonUp = up.clamp(0, 100); // 一般区间[0,100]
      data[i].aroonDown = down.clamp(0, 100);

      // 如果要 AroonOsc
      if (calcOsc) {
        double osc = up - down;
        if (!osc.isFinite) osc = 0;
        data[i].aroonOsc = osc;
      }
    }
  }

  static void _computeChaikinMoneyFlow(List<KLineEntity> data,
      {int period = 20}) {
    if (data.isEmpty || period <= 0) {
      for (final e in data) {
        e.cmf = null;
      }
      return;
    }

    final List<double> mfBuffer = List.filled(period, 0.0);
    final List<double> volBuffer = List.filled(period, 0.0);
    double sumMf = 0.0;
    double sumVol = 0.0;
    int idx = 0;
    int filled = 0;

    for (final entity in data) {
      final double oldMf = mfBuffer[idx];
      final double oldVol = volBuffer[idx];
      if (filled >= period) {
        sumMf -= oldMf;
        sumVol -= oldVol;
      } else {
        filled++;
      }

      final double range = entity.high - entity.low;
      double multiplier = 0.0;
      if (range.abs() > 1e-12) {
        multiplier =
            ((entity.close - entity.low) - (entity.high - entity.close)) /
                range;
      }
      final double mfVolume = multiplier * entity.vol;

      mfBuffer[idx] = mfVolume;
      volBuffer[idx] = entity.vol;
      sumMf += mfVolume;
      sumVol += entity.vol;

      idx = (idx + 1) % period;

      if (filled >= period && sumVol.abs() > 1e-12) {
        entity.cmf = sumMf / sumVol;
      } else {
        entity.cmf = null;
      }
    }
  }

  static void _computeChaikinOscillator(List<KLineEntity> data,
      {int shortPeriod = 3, int longPeriod = 10}) {
    if (data.isEmpty) return;

    double? emaShort;
    double? emaLong;
    final double shortAlpha = 2 / (shortPeriod + 1);
    final double longAlpha = 2 / (longPeriod + 1);

    for (final entity in data) {
      final double? adl = entity.adl;
      if (adl == null) {
        entity.chaikinOscillator = null;
        continue;
      }

      emaShort =
          emaShort == null ? adl : emaShort + shortAlpha * (adl - emaShort);
      emaLong = emaLong == null ? adl : emaLong + longAlpha * (adl - emaLong);

      entity.chaikinOscillator = emaShort - emaLong;
    }
  }

  static void _computeKlingerOscillator(List<KLineEntity> data,
      {int shortPeriod = 34, int longPeriod = 55, int signalPeriod = 13}) {
    if (data.isEmpty) return;

    double? emaShort;
    double? emaLong;
    double? signal;
    final double shortAlpha = 2 / (shortPeriod + 1);
    final double longAlpha = 2 / (longPeriod + 1);
    final double signalAlpha = 2 / (signalPeriod + 1);

    for (int i = 0; i < data.length; i++) {
      final entity = data[i];
      final double typical = (entity.high + entity.low + entity.close) / 3.0;
      final double prevTypical = i > 0
          ? (data[i - 1].high + data[i - 1].low + data[i - 1].close) / 3.0
          : typical;
      final double direction = typical >= prevTypical ? 1.0 : -1.0;

      final double range = (entity.high - entity.low).abs();
      double vfComponent = 0.0;
      if (range > 1e-12) {
        vfComponent =
            ((entity.close - entity.low) - (entity.high - entity.close)) /
                range;
      }
      final double volumeForce = direction * entity.vol * vfComponent;

      emaShort = emaShort == null
          ? volumeForce
          : emaShort + shortAlpha * (volumeForce - emaShort);
      emaLong = emaLong == null
          ? volumeForce
          : emaLong + longAlpha * (volumeForce - emaLong);

      final double kvo = emaShort - emaLong;
      signal = signal == null ? kvo : signal + signalAlpha * (kvo - signal);
      entity.kvo = kvo;
      entity.kvoSignal = signal;
    }
  }

  static void _computeVpt(List<KLineEntity> data) {
    if (data.isEmpty) return;

    double cumulative = 0.0;
    data[0].vpt = 0.0;
    for (int i = 1; i < data.length; i++) {
      final prevClose = data[i - 1].close;
      final double change = prevClose.abs() > 1e-12
          ? (data[i].close - prevClose) / prevClose
          : 0.0;
      cumulative += change * data[i].vol;
      data[i].vpt = cumulative;
    }
  }

  static void _computeForceIndex(List<KLineEntity> data, {int period = 13}) {
    if (data.length < 2) {
      for (final e in data) {
        e.forceIndex = null;
      }
      return;
    }

    final double alpha = 2 / (period + 1);
    double? ema;
    data[0].forceIndex = null;
    for (int i = 1; i < data.length; i++) {
      final current = data[i];
      final prev = data[i - 1];
      final double raw = (current.close - prev.close) * current.vol;
      ema = ema == null ? raw : ema + alpha * (raw - ema);
      current.forceIndex = ema;
    }
  }

  static void _computeRoc(List<KLineEntity> data,
      {int period = 12, int signalPeriod = 6}) {
    if (data.isEmpty || period <= 0) {
      for (final e in data) {
        e.roc = null;
        e.rocSignal = null;
      }
      return;
    }

    final List<double?> rocValues = List.filled(data.length, null);
    for (int i = period; i < data.length; i++) {
      final prevClose = data[i - period].close;
      if (prevClose.abs() > 1e-12) {
        rocValues[i] = ((data[i].close - prevClose) / prevClose) * 100.0;
      } else {
        rocValues[i] = 0.0;
      }
    }

    double? ema;
    final double alpha = 2 / (signalPeriod + 1);
    for (int i = 0; i < data.length; i++) {
      final value = rocValues[i];
      data[i].roc = value;
      if (value != null) {
        ema = ema == null ? value : ema + alpha * (value - ema);
        data[i].rocSignal = ema;
      } else {
        data[i].rocSignal = null;
      }
    }
  }

  static void _computeUltimateOsc(List<KLineEntity> data,
      {int shortPeriod = 7, int midPeriod = 14, int longPeriod = 28}) {
    if (data.length < 2) {
      for (final e in data) {
        e.ultimateOsc = null;
      }
      return;
    }

    final length = data.length;
    final List<double> bp = List.filled(length, 0.0);
    final List<double> tr = List.filled(length, 0.0);

    for (int i = 0; i < length; i++) {
      if (i == 0) {
        bp[i] = data[i].close - data[i].low;
        tr[i] = data[i].high - data[i].low;
      } else {
        final prevClose = data[i - 1].close;
        final double minLow = math.min(data[i].low, prevClose);
        final double maxHigh = math.max(data[i].high, prevClose);
        bp[i] = data[i].close - minLow;
        tr[i] = maxHigh - minLow;
      }
    }

    double sum(List<double> source, int end, int period) {
      double total = 0.0;
      for (int j = 0; j < period; j++) {
        total += source[end - j];
      }
      return total;
    }

    for (int i = 0; i < length; i++) {
      if (i < longPeriod - 1) {
        data[i].ultimateOsc = null;
        continue;
      }

      final double shortBp = sum(bp, i, shortPeriod);
      final double shortTr = sum(tr, i, shortPeriod);
      final double midBp = sum(bp, i, midPeriod);
      final double midTr = sum(tr, i, midPeriod);
      final double longBp = sum(bp, i, longPeriod);
      final double longTr = sum(tr, i, longPeriod);

      if (shortTr.abs() < 1e-12 ||
          midTr.abs() < 1e-12 ||
          longTr.abs() < 1e-12) {
        data[i].ultimateOsc = null;
        continue;
      }

      final double avgShort = shortBp / shortTr;
      final double avgMid = midBp / midTr;
      final double avgLong = longBp / longTr;

      data[i].ultimateOsc = 100.0 * (4 * avgShort + 2 * avgMid + avgLong) / 7.0;
    }
  }

  static void _computeConnorsRsi(List<KLineEntity> data,
      {int pricePeriod = 3,
      int streakPeriod = 2,
      int percentRankPeriod = 100}) {
    final length = data.length;
    if (length == 0) return;

    final List<double> closes = data.map((e) => e.close).toList();
    final priceRsi = _rsiFromSeries(closes, pricePeriod);

    final List<double> streaks = List.filled(length, 0.0);
    for (int i = 1; i < length; i++) {
      if (data[i].close > data[i - 1].close) {
        streaks[i] = streaks[i - 1] >= 0 ? streaks[i - 1] + 1 : 1;
      } else if (data[i].close < data[i - 1].close) {
        streaks[i] = streaks[i - 1] <= 0 ? streaks[i - 1] - 1 : -1;
      } else {
        streaks[i] = 0;
      }
    }
    final streakRsi = _rsiFromSeries(streaks, streakPeriod);

    final List<double> changes = List.filled(length, 0.0);
    for (int i = 1; i < length; i++) {
      changes[i] = data[i].close - data[i - 1].close;
    }

    for (int i = 0; i < length; i++) {
      double? percentRank;
      if (i >= 1) {
        int start = i - percentRankPeriod + 1;
        if (start < 1) start = 1;
        int count = 0;
        int below = 0;
        int equal = 0;
        for (int j = start; j <= i; j++) {
          count++;
          if (changes[j] < changes[i]) {
            below++;
          } else if ((changes[j] - changes[i]).abs() < 1e-12) {
            equal++;
          }
        }
        if (count > 0) {
          percentRank = ((below + 0.5 * equal) / count) * 100.0;
        }
      }

      final double? r1 = priceRsi[i];
      final double? r2 = streakRsi[i];
      if (r1 == null || r2 == null || percentRank == null) {
        data[i].connorsRsi = null;
      } else {
        data[i].connorsRsi = (r1 + r2 + percentRank) / 3.0;
      }
    }
  }

  static void _computeStochRsi(List<KLineEntity> data,
      {int period = 14, int smoothK = 3, int smoothD = 3}) {
    final length = data.length;
    if (length == 0) return;

    final List<double?> rsiValues =
        List<double?>.generate(length, (i) => data[i].rsi);
    final List<double?> rawValues = List.filled(length, null);

    for (int i = 0; i < length; i++) {
      final double? rsiValue = rsiValues[i];
      if (rsiValue == null) {
        rawValues[i] = null;
        continue;
      }
      int start = i - period + 1;
      if (start < 0) start = 0;
      double minR = double.infinity;
      double maxR = -double.infinity;
      bool hasData = false;
      for (int j = start; j <= i; j++) {
        final double? candidate = rsiValues[j];
        if (candidate == null) continue;
        hasData = true;
        if (candidate < minR) minR = candidate;
        if (candidate > maxR) maxR = candidate;
      }
      if (!hasData || maxR == minR) {
        rawValues[i] = null;
        continue;
      }
      rawValues[i] = (rsiValue - minR) / (maxR - minR);
    }

    final List<double?> kValues = List.filled(length, null);
    for (int i = 0; i < length; i++) {
      final double? raw = rawValues[i];
      if (raw == null) {
        kValues[i] = null;
        continue;
      }
      double sum = 0.0;
      int count = 0;
      for (int j = i; j >= 0 && count < smoothK; j--) {
        final double? candidate = rawValues[j];
        if (candidate == null) continue;
        sum += candidate;
        count++;
      }
      if (count == smoothK) {
        kValues[i] = (sum / smoothK) * 100.0;
      } else {
        kValues[i] = null;
      }
    }

    for (int i = 0; i < length; i++) {
      final double? kValue = kValues[i];
      if (kValue == null) {
        data[i].stochRsiK = null;
        data[i].stochRsiD = null;
        continue;
      }
      double sum = 0.0;
      int count = 0;
      for (int j = i; j >= 0 && count < smoothD; j--) {
        final double? candidate = kValues[j];
        if (candidate == null) continue;
        sum += candidate;
        count++;
      }
      data[i].stochRsiK = kValue;
      data[i].stochRsiD = count == smoothD ? sum / smoothD : null;
    }
  }

  static void _computeRvi(List<KLineEntity> data) {
    if (data.length < 4) {
      for (final e in data) {
        e.rvi = null;
        e.rviSignal = null;
      }
      return;
    }

    for (int i = 0; i < data.length; i++) {
      if (i < 3) {
        data[i].rvi = null;
        data[i].rviSignal = null;
        continue;
      }

      double numerator = 0.0;
      double denominator = 0.0;
      for (int j = 0; j < 4; j++) {
        final current = data[i - j];
        final weight = (j == 0 || j == 3) ? 1 : 2;
        numerator += weight * (current.close - current.open);
        denominator += weight * (current.high - current.low);
      }
      numerator /= 6.0;
      denominator /= 6.0;

      if (denominator.abs() < 1e-12) {
        data[i].rvi = null;
        data[i].rviSignal = null;
        continue;
      }

      final double rviValue = numerator / denominator;
      data[i].rvi = rviValue;

      if (i >= 3) {
        final values = <double?>[
          data[i].rvi,
          data[i - 1].rvi,
          data[i - 2].rvi,
          data[i - 3].rvi,
        ];
        if (values.every((v) => v != null)) {
          data[i].rviSignal =
              (values[0]! + 2 * values[1]! + 2 * values[2]! + values[3]!) / 6.0;
        } else {
          data[i].rviSignal = null;
        }
      } else {
        data[i].rviSignal = null;
      }
    }
  }

  static void _computeDpo(List<KLineEntity> data, {int period = 20}) {
    if (data.isEmpty || period <= 0) {
      for (final e in data) {
        e.dpo = null;
      }
      return;
    }

    final List<double> closes = data.map((e) => e.close).toList();
    double rollingSum = 0.0;
    for (int i = 0; i < data.length; i++) {
      rollingSum += closes[i];
      if (i >= period) {
        rollingSum -= closes[i - period];
      }
      if (i >= period - 1) {
        final double sma = rollingSum / period;
        data[i].dpo = closes[i] - sma;
      } else {
        data[i].dpo = null;
      }
    }
  }

  static void _computeKama(List<KLineEntity> data,
      {int erPeriod = 10, int fastPeriod = 2, int slowPeriod = 30}) {
    final length = data.length;
    if (length == 0 || erPeriod <= 0) {
      for (final e in data) {
        e.kama = null;
      }
      return;
    }
    if (length < erPeriod) {
      for (final e in data) {
        e.kama = null;
      }
      return;
    }

    final List<double> closes = data.map((e) => e.close).toList();
    double sum = 0.0;
    for (int i = 0; i < erPeriod; i++) {
      sum += closes[i];
    }
    double kama = sum / erPeriod;

    for (int i = 0; i < length; i++) {
      if (i < erPeriod) {
        data[i].kama = null;
        continue;
      }
      final double change = (closes[i] - closes[i - erPeriod]).abs();
      double volatility = 0.0;
      for (int j = i - erPeriod + 1; j <= i; j++) {
        volatility += (closes[j] - closes[j - 1]).abs();
      }
      final double er = volatility.abs() > 1e-12 ? change / volatility : 0.0;
      final double fastSC = 2 / (fastPeriod + 1);
      final double slowSC = 2 / (slowPeriod + 1);
      final double smoothing =
          math.pow(er * (fastSC - slowSC) + slowSC, 2).toDouble();
      kama = kama + smoothing * (closes[i] - kama);
      data[i].kama = kama;
    }
  }

  static void _computeHma(List<KLineEntity> data, {int period = 21}) {
    if (data.isEmpty || period <= 0) {
      for (final e in data) {
        e.hma = null;
      }
      return;
    }

    final List<double> closes = data.map((e) => e.close).toList();
    final int halfPeriod = math.max(1, period ~/ 2);
    final int sqrtPeriod = math.max(1, math.sqrt(period).round());

    final List<double?> wmaHalf = List.filled(data.length, null);
    final List<double?> wmaFull = List.filled(data.length, null);
    for (int i = 0; i < data.length; i++) {
      wmaHalf[i] = _wmaAt(closes, i, halfPeriod);
      wmaFull[i] = _wmaAt(closes, i, period);
    }

    final List<double?> diffSeries = List.filled(data.length, null);
    for (int i = 0; i < data.length; i++) {
      if (wmaHalf[i] != null && wmaFull[i] != null) {
        diffSeries[i] = 2 * wmaHalf[i]! - wmaFull[i]!;
      }
    }

    for (int i = 0; i < data.length; i++) {
      data[i].hma = _wmaAtNullable(diffSeries, i, sqrtPeriod);
    }
  }

  static void _computeKeltnerChannel(List<KLineEntity> data,
      {int period = 20, double multiplier = 2}) {
    if (data.isEmpty) return;

    double? ema;
    final double alpha = 2 / (period + 1);
    for (final entity in data) {
      final double typicalPrice =
          (entity.high + entity.low + entity.close) / 3.0;
      ema = ema == null ? typicalPrice : ema + alpha * (typicalPrice - ema);
      entity.keltnerMiddle = ema;
      if (entity.atr != null) {
        entity.keltnerUpper = ema + multiplier * entity.atr!;
        entity.keltnerLower = ema - multiplier * entity.atr!;
      } else {
        entity.keltnerUpper = null;
        entity.keltnerLower = null;
      }
    }
  }

  static void _computeDonchianChannel(List<KLineEntity> data,
      {int period = 20}) {
    if (data.isEmpty || period <= 0) return;

    for (int i = 0; i < data.length; i++) {
      int start = i - period + 1;
      if (start < 0) start = 0;
      double highest = -double.infinity;
      double lowest = double.infinity;
      for (int j = start; j <= i; j++) {
        highest = math.max(highest, data[j].high);
        lowest = math.min(lowest, data[j].low);
      }
      if (i >= period - 1) {
        data[i].donchianUpper = highest;
        data[i].donchianLower = lowest;
        data[i].donchianMiddle = (highest + lowest) / 2.0;
      } else {
        data[i].donchianUpper = null;
        data[i].donchianLower = null;
        data[i].donchianMiddle = null;
      }
    }
  }

  static void _computeBollingerBandwidth(List<KLineEntity> data) {
    for (final entity in data) {
      final up = entity.up;
      final dn = entity.dn;
      final mb = entity.mb;
      if (up != null && dn != null && mb != null && mb.abs() > 1e-12) {
        entity.bollBandwidth = (up - dn) / mb;
      } else {
        entity.bollBandwidth = null;
      }
    }
  }

  static void _computeChaikinVolatility(List<KLineEntity> data,
      {int emaPeriod = 10, int changePeriod = 10}) {
    if (data.isEmpty) return;

    final List<double?> emaRange = List.filled(data.length, null);
    double ema = 0.0;
    bool hasEma = false;
    final double alpha = 2 / (emaPeriod + 1);
    for (int i = 0; i < data.length; i++) {
      final range = data[i].high - data[i].low;
      if (!hasEma) {
        ema = range;
        hasEma = true;
      } else {
        ema = ema + alpha * (range - ema);
      }
      emaRange[i] = ema;
      if (i >= changePeriod) {
        final prevRange = emaRange[i - changePeriod];
        if (prevRange != null && prevRange.abs() > 1e-12) {
          data[i].chaikinVolatility = ((ema - prevRange) / prevRange) * 100.0;
        } else {
          data[i].chaikinVolatility = null;
        }
      } else {
        data[i].chaikinVolatility = null;
      }
    }
  }

  static void _computeHvPercentile(List<KLineEntity> data,
      {int lookback = 63}) {
    if (data.isEmpty) return;

    for (int i = 0; i < data.length; i++) {
      final double? current = data[i].hv;
      if (current == null) {
        data[i].hvPercentile = null;
        continue;
      }
      int start = i - lookback + 1;
      if (start < 0) start = 0;
      int count = 1;
      int below = 0;
      int equal = 1;
      for (int j = start; j < i; j++) {
        final double? candidate = data[j].hv;
        if (candidate == null) continue;
        count++;
        if (candidate < current) {
          below++;
        } else if ((candidate - current).abs() < 1e-12) {
          equal++;
        }
      }
      data[i].hvPercentile = ((below + 0.5 * equal) / count) * 100.0;
    }
  }

  static void _computeAtrPercentile(List<KLineEntity> data,
      {int lookback = 63}) {
    if (data.isEmpty) return;

    for (int i = 0; i < data.length; i++) {
      final double? current = data[i].atr;
      if (current == null) {
        data[i].atrPercentile = null;
        continue;
      }
      int start = i - lookback + 1;
      if (start < 0) start = 0;
      int count = 1;
      int below = 0;
      int equal = 1;
      for (int j = start; j < i; j++) {
        final double? candidate = data[j].atr;
        if (candidate == null) continue;
        count++;
        if (candidate < current) {
          below++;
        } else if ((candidate - current).abs() < 1e-12) {
          equal++;
        }
      }
      data[i].atrPercentile = ((below + 0.5 * equal) / count) * 100.0;
    }
  }

  static void _computeElderRay(List<KLineEntity> data, {int period = 13}) {
    if (data.isEmpty) return;

    double? ema;
    final double alpha = 2 / (period + 1);
    for (int i = 0; i < data.length; i++) {
      final entity = data[i];
      ema = ema == null ? entity.close : ema + alpha * (entity.close - ema);
      if (i < period - 1) {
        entity.elderBull = null;
        entity.elderBear = null;
      } else {
        entity.elderBull = entity.high - ema;
        entity.elderBear = entity.low - ema;
      }
    }
  }

  static void _computeIchimokuSpanDiff(List<KLineEntity> data) {
    for (final entity in data) {
      if (entity.ichimokuSpanA != null && entity.ichimokuSpanB != null) {
        entity.ichimokuSpanDiff = entity.ichimokuSpanA! - entity.ichimokuSpanB!;
      } else {
        entity.ichimokuSpanDiff = null;
      }
    }
  }

  static void _computePivotPoints(List<KLineEntity> data) {
    double? prevHigh;
    double? prevLow;
    double? prevClose;

    for (final entity in data) {
      if (prevHigh != null && prevLow != null && prevClose != null) {
        final double pivot = (prevHigh + prevLow + prevClose) / 3.0;
        final double range = prevHigh - prevLow;
        entity.pivot = pivot;
        entity.pivotR1 = 2 * pivot - prevLow;
        entity.pivotS1 = 2 * pivot - prevHigh;
        entity.pivotR2 = pivot + range;
        entity.pivotS2 = pivot - range;
        entity.pivotR3 = prevHigh + 2 * (pivot - prevLow);
        entity.pivotS3 = prevLow - 2 * (prevHigh - pivot);
      } else {
        entity.pivot = null;
        entity.pivotR1 = null;
        entity.pivotR2 = null;
        entity.pivotR3 = null;
        entity.pivotS1 = null;
        entity.pivotS2 = null;
        entity.pivotS3 = null;
      }

      prevHigh = entity.high;
      prevLow = entity.low;
      prevClose = entity.close;
    }
  }

  static void _computeGannFan(List<KLineEntity> data, {int lookback = 30}) {
    if (data.isEmpty) return;

    for (int i = 0; i < data.length; i++) {
      int start = i - lookback + 1;
      if (start < 0) start = 0;
      double highest = -double.infinity;
      double lowest = double.infinity;
      for (int j = start; j <= i; j++) {
        highest = math.max(highest, data[j].high);
        lowest = math.min(lowest, data[j].low);
      }
      final double range = highest - lowest;
      if (range.abs() < 1e-12) {
        data[i].gann1x1 = null;
        data[i].gann1x2 = null;
        data[i].gann2x1 = null;
        continue;
      }
      final double normalized = (data[i].close - lowest) / range;
      data[i].gann1x1 = normalized;
      data[i].gann1x2 = normalized / 2.0;
      data[i].gann2x1 = (normalized * 2).clamp(-2.0, 2.0);
    }
  }

  static List<double?> _rsiFromSeries(List<double> series, int period) {
    final length = series.length;
    final result = List<double?>.filled(length, null);
    if (length <= period || period <= 0) {
      return result;
    }

    double gainSum = 0.0;
    double lossSum = 0.0;
    for (int i = 1; i <= period; i++) {
      final double change = series[i] - series[i - 1];
      if (change > 0) {
        gainSum += change;
      } else {
        lossSum -= change;
      }
    }
    double avgGain = gainSum / period;
    double avgLoss = lossSum / period;
    double rs = avgLoss.abs() < 1e-12 ? double.infinity : avgGain / avgLoss;
    result[period] = avgLoss.abs() < 1e-12 ? 100.0 : 100.0 - 100.0 / (1 + rs);

    for (int i = period + 1; i < length; i++) {
      final double change = series[i] - series[i - 1];
      final double gain = change > 0 ? change : 0.0;
      final double loss = change < 0 ? -change : 0.0;
      avgGain = ((avgGain * (period - 1)) + gain) / period;
      avgLoss = ((avgLoss * (period - 1)) + loss) / period;
      if (avgLoss.abs() < 1e-12) {
        result[i] = 100.0;
      } else {
        rs = avgGain / avgLoss;
        result[i] = 100.0 - 100.0 / (1 + rs);
      }
    }

    return result;
  }

  static double? _wmaAt(List<double> values, int index, int period) {
    if (period <= 0 || index < period - 1) return null;
    double numerator = 0.0;
    int weight = 1;
    for (int i = index - period + 1; i <= index; i++) {
      numerator += values[i] * weight;
      weight++;
    }
    final double denominator = period * (period + 1) / 2;
    return denominator == 0 ? null : numerator / denominator;
  }

  static double? _wmaAtNullable(List<double?> values, int index, int period) {
    if (period <= 0 || index < period - 1) return null;
    double numerator = 0.0;
    int weight = 1;
    for (int i = index - period + 1; i <= index; i++) {
      final double? value = values[i];
      if (value == null) {
        return null;
      }
      numerator += value * weight;
      weight++;
    }
    final double denominator = period * (period + 1) / 2;
    return denominator == 0 ? null : numerator / denominator;
  }
}

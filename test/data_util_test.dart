import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_multiple/entity/k_line_entity.dart';
import 'package:k_chart_multiple/provider/signal_provider.dart';
import 'package:k_chart_multiple/utils/data_util.dart';

typedef _PsarResult = ({double? value, bool? isUp});

List<KLineEntity> _buildTrendingData(int count) {
  final List<KLineEntity> items = [];
  for (int i = 0; i < count; i++) {
    final double close = 10.0 + i * 0.5;
    final double high = close + 0.4;
    final double low = close - 0.4;
    final double open = close - 0.2;
    items.add(KLineEntity.fromCustom(
      open: open,
      close: close,
      high: high,
      low: low,
      vol: 100 + i * 5,
      time: DateTime(2024, 1, 1).millisecondsSinceEpoch + i * 60000,
    ));
  }
  return items;
}

List<KLineEntity> _buildPsarReversalData() {
  final List<KLineEntity> items = [];
  for (int i = 0; i < 30; i++) {
    final bool rising = i < 15;
    final double base =
        rising ? 10.0 + i * 0.3 : 10.0 + 15 * 0.3 - (i - 14) * 0.32;
    final double close = double.parse(base.toStringAsFixed(6));
    final double high = close + 0.5;
    final double low = close - 0.5;
    final double open = close + (rising ? -0.2 : 0.2);
    items.add(KLineEntity.fromCustom(
      open: open,
      close: close,
      high: high,
      low: low,
      vol: 150 + i * 8,
      time: DateTime(2024, 1, 1).millisecondsSinceEpoch + i * 60000,
    ));
  }
  return items;
}

List<double> _computeExpectedPpo(List<double> closes,
    {int fastPeriod = 12, int slowPeriod = 26}) {
  final int length = closes.length;
  final List<double> emaFast = List<double>.filled(length, 0);
  final List<double> emaSlow = List<double>.filled(length, 0);
  final List<double> ppo = List<double>.filled(length, 0);
  final double alphaFast = 2 / (fastPeriod + 1);
  final double alphaSlow = 2 / (slowPeriod + 1);

  emaFast[0] = closes[0];
  emaSlow[0] = closes[0];
  ppo[0] = 0;

  for (int i = 1; i < length; i++) {
    final double c = closes[i];
    emaFast[i] = emaFast[i - 1] + alphaFast * (c - emaFast[i - 1]);
    emaSlow[i] = emaSlow[i - 1] + alphaSlow * (c - emaSlow[i - 1]);

    final double slow = emaSlow[i];
    if (slow.abs() < 1e-12) {
      ppo[i] = 0;
    } else {
      double ratio = (emaFast[i] - slow) / slow * 100;
      if (!ratio.isFinite) {
        ratio = 0;
      } else if (ratio.abs() > 1e5) {
        ratio = ratio > 0 ? 1e5 : -1e5;
      }
      ppo[i] = ratio;
    }
  }
  return ppo;
}

List<double?> _computeExpectedPpoSignal(List<double> ppoLine,
    {int signalPeriod = 9}) {
  final int length = ppoLine.length;
  final List<double?> signal = List<double?>.filled(length, null);
  if (length > 0) {
    signal[0] = 0;
  }
  if (length > 1) {
    signal[1] = ppoLine[1];
    final double alphaSignal = 2 / (signalPeriod + 1);
    for (int i = 2; i < length; i++) {
      final double prev = signal[i - 1] ?? 0;
      double value = prev + alphaSignal * (ppoLine[i] - prev);
      if (!value.isFinite) value = 0;
      signal[i] = value;
    }
  }
  return signal;
}

List<double> _computeExpectedAtr(
  List<double> highs,
  List<double> lows,
  List<double> closes, {
  int period = 14,
  String smoothMethod = 'ema',
}) {
  final int length = closes.length;
  final List<double> tr = List<double>.filled(length, 0);
  final List<double> atr = List<double>.filled(length, 0);

  if (length == 0) return atr;
  tr[0] = highs[0] - lows[0];
  atr[0] = tr[0];
  double sumTR = tr[0];

  for (int i = 1; i < length; i++) {
    final double range1 = highs[i] - lows[i];
    final double range2 = (highs[i] - closes[i - 1]).abs();
    final double range3 = (lows[i] - closes[i - 1]).abs();
    tr[i] = [range1, range2, range3].reduce((a, b) => a > b ? a : b);

    sumTR += tr[i];
    if (i < period) {
      atr[i] = sumTR / (i + 1);
    } else {
      final double prevAtr = atr[i - 1];
      switch (smoothMethod) {
        case 'wilder':
          atr[i] = (prevAtr * (period - 1) + tr[i]) / period;
          break;
        case 'double':
          final double wilderAtr = (prevAtr * (period - 1) + tr[i]) / period;
          final double alpha = 2 / (period + 1);
          atr[i] = alpha * wilderAtr + (1 - alpha) * prevAtr;
          break;
        case 'none':
          atr[i] = tr[i];
          break;
        case 'ema':
        default:
          final double alpha = 2 / (period + 1);
          atr[i] = alpha * tr[i] + (1 - alpha) * prevAtr;
          break;
      }
    }
  }
  return atr;
}

List<_PsarResult> _computeExpectedPsar(
  List<double> highs,
  List<double> lows,
  List<double> closes, {
  double accInit = 0.02,
  double accStep = 0.02,
  double accMax = 0.2,
}) {
  final int length = closes.length;
  final List<_PsarResult> result =
      List<_PsarResult>.generate(length, (_) => (value: null, isUp: null));

  if (length == 0) {
    return result;
  }
  if (length == 1) {
    result[0] = (value: lows[0], isUp: null);
    return result;
  }

  bool isUp = closes[1] > closes[0];
  double sar = isUp ? lows[0] : highs[0];
  double ep = isUp ? highs[0] : lows[0];
  double af = accInit;

  result[0] = (value: sar, isUp: null);
  result[1] = (value: sar, isUp: null);

  for (int i = 2; i < length; i++) {
    final bool trendBeforeUpdate = isUp;
    final double curHigh = highs[i];
    final double curLow = lows[i];
    double newSar = sar + af * (ep - sar);

    if (!newSar.isFinite) {
      newSar = sar;
    }

    if (isUp) {
      final double min1 = lows[i - 1];
      final double min2 = lows[i - 2];
      if (newSar > min1) newSar = min1;
      if (newSar > min2) newSar = min2;

      if (newSar > curLow) {
        isUp = false;
        newSar = ep;
        ep = curLow;
        af = accInit;
      } else {
        if (curHigh > ep) {
          ep = curHigh;
          af += accStep;
          if (af > accMax) af = accMax;
        }
      }
    } else {
      final double max1 = highs[i - 1];
      final double max2 = highs[i - 2];
      if (newSar < max1) newSar = max1;
      if (newSar < max2) newSar = max2;

      if (newSar < curHigh) {
        isUp = true;
        newSar = ep;
        ep = curHigh;
        af = accInit;
      } else {
        if (curLow < ep) {
          ep = curLow;
          af += accStep;
          if (af > accMax) af = accMax;
        }
      }
    }

    sar = newSar;
    result[i] = (value: sar, isUp: trendBeforeUpdate);
  }

  return result;
}

void main() {
  group('DataUtil indicator calculations', () {
    test('PPO values align with reference implementation', () {
      final data = _buildTrendingData(30);
      final closes = data.map((e) => e.close).toList(growable: false);

      DataUtil.calculate(data);

      final expectedPpo = _computeExpectedPpo(closes);
      final expectedSignal = _computeExpectedPpoSignal(expectedPpo);

      for (int i = 0; i < data.length; i++) {
        expect(data[i].ppo, closeTo(expectedPpo[i], 1e-6),
            reason: 'ppo[$i] mismatch');
        if (expectedSignal[i] == null) {
          expect(data[i].ppoSignal, isNull,
              reason: 'ppoSignal[$i] should be null');
        } else {
          expect(data[i].ppoSignal, isNotNull,
              reason: 'ppoSignal[$i] should be computed');
          expect(data[i].ppoSignal!, closeTo(expectedSignal[i]!, 1e-6),
              reason: 'ppoSignal[$i] mismatch');
        }
      }
    });

    test('ATR smoothing follows EMA definition after warm-up', () {
      final data = _buildTrendingData(30);
      final highs = data.map((e) => e.high).toList(growable: false);
      final lows = data.map((e) => e.low).toList(growable: false);
      final closes = data.map((e) => e.close).toList(growable: false);

      DataUtil.calculate(data);

      final expectedAtr = _computeExpectedAtr(highs, lows, closes);
      for (int i = 0; i < data.length; i++) {
        expect(data[i].atr, isNotNull, reason: 'atr[$i] should not be null');
        expect(data[i].atr!, closeTo(expectedAtr[i], 1e-6),
            reason: 'atr[$i] mismatch');
      }
    });

    test('PSAR direction and values match canonical implementation', () {
      final data = _buildPsarReversalData();
      final highs = data.map((e) => e.high).toList(growable: false);
      final lows = data.map((e) => e.low).toList(growable: false);
      final closes = data.map((e) => e.close).toList(growable: false);

      DataUtil.calculate(data);

      final expected = _computeExpectedPsar(highs, lows, closes);
      for (int i = 0; i < data.length; i++) {
        expect(data[i].psar, expected[i].value == null ? isNull : isNotNull,
            reason: 'psar[$i] availability mismatch');
        if (expected[i].value != null && data[i].psar != null) {
          expect(data[i].psar!, closeTo(expected[i].value!, 1e-6),
              reason: 'psar[$i] mismatch');
        }
        expect(data[i].psarIsUp, expected[i].isUp,
            reason: 'psarIsUp[$i] mismatch');
      }
    });

    test('Probability values stay within bounds after calculation', () {
      final data = _buildTrendingData(40);
      DataUtil.calculate(data);

      for (int i = 2; i < data.length; i++) {
        final probability = data[i].probability;
        expect(probability, isNotNull,
            reason: 'probability[$i] should be computed');
        expect(probability!, greaterThanOrEqualTo(0.01),
            reason: 'probability[$i] below minimum');
        expect(probability, lessThanOrEqualTo(0.99),
            reason: 'probability[$i] above maximum');
      }
    });

    test('DMI and Vortex indicators remain finite', () {
      final data = _buildTrendingData(60);
      DataUtil.calculate(data);

      final last = data.last;
      expect(last.pdi, isNotNull, reason: 'pdi should exist');
      expect(last.mdi, isNotNull, reason: 'mdi should exist');
      expect(last.adx, isNotNull, reason: 'adx should exist');
      expect(last.viPlus, isNotNull, reason: '+VI should exist');
      expect(last.viMinus, isNotNull, reason: '-VI should exist');

      expect(last.adx!.isFinite, isTrue, reason: 'adx should be finite');
      expect(last.viPlus!.isFinite, isTrue, reason: '+VI should be finite');
      expect(last.viMinus!.isFinite, isTrue, reason: '-VI should be finite');
    });

    test('priceAboveToProb clamps output inside [0, 1]', () {
      final entity = KLineEntity.fromCustom(
        open: 10,
        close: 10.5,
        high: 10.8,
        low: 9.9,
        vol: 100,
        time: DateTime(2024, 1, 1).millisecondsSinceEpoch,
      );

      expect(priceAboveToProb(entity, 10.5), inInclusiveRange(0.0, 1.0));
      expect(priceAboveToProb(entity, 1), lessThanOrEqualTo(1.0));
      expect(priceAboveToProb(entity, 100), greaterThanOrEqualTo(0.0));
    });
  });
}

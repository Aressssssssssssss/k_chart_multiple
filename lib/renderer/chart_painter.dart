import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import '../entity/up_prob_report.dart';
import '../flutter_k_chart.dart';
import '../provider/adl_signal_provider.dart';
import '../provider/adx_only_signal_provider.dart';
import '../provider/aroon_signal_provider.dart';
import '../provider/atr_signal_provider.dart';
import '../provider/boll_signal_provider.dart';
import '../provider/cci_signal_provider.dart';
import '../provider/dem_signal_provider.dart';
import '../provider/dmi_signal_provider.dart';
import '../provider/envelopes_signal_provider.dart';
import '../provider/hv_signal_provider.dart';
import '../provider/ichimoku_signal_provider.dart';
import '../provider/kdj_signal_provider.dart';
import '../provider/ma_cross_signal_provider.dart';
import '../provider/macd_signal_provider.dart';
import '../provider/mfi_signal_provider.dart';
import '../provider/momentum_signal_provider.dart';
import '../provider/obv_signal_provider.dart';
import '../provider/ppo_signal_provider.dart';
import '../provider/rsi_signal_provider.dart';
import '../provider/sar_signal_provider.dart';
import '../provider/signal_provider.dart';
import '../provider/stddev_signal_provider.dart';
import '../provider/stoch_signal_provider.dart';
import '../provider/trix_signal_provider.dart';
import '../provider/tsi_signal_provider.dart';
import '../provider/vix_signal_provider.dart';
import '../provider/volatility_signal_provider.dart';
import '../provider/vortex_signal_provider.dart';
import '../provider/vwap_signal_provider.dart';
import '../provider/wpr_signal_provider.dart';
import '../provider/wr_signal_provider.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isrecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer; //, mSecondaryRenderer;
  final List<SecondaryState> secondaryStates;
  final List<SecondaryRenderer?> secondaryRenderers = []; // 存储多个次图渲染器

  StreamSink<InfoWindowEntity?>? sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint, nowPricePaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;

  final double? mainHeight; // 新增参数：主图高度
  final double? secondaryHeight; // 新增参数：次图高度

  /// 副图指标 → Provider
  final Map<SecondaryState, SecondarySignalProvider> _secProviders;

  /// 主图指标 → Provider
  final Map<MainState, MainSignalProvider> _mainProviders;

  final void Function(UpProbReport report)? onUpProbs; // ★ 新增回调
  UpProbReport? _lastReport; // ★ 缓存上次上送

  /// 副图买/卖回调
  final void Function(double probability)? onGoingUp;
  final void Function(double probability)? onGoingDown;

  /// 主图买/卖回调
  final void Function(double probability)? onMainGoingUp;
  final void Function(double probability)? onMainGoingDown;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    mainState,
    volHidden,
    isShowMainState,
    required this.secondaryStates,
    this.sink,
    this.mainHeight, // 接收主图高度
    this.secondaryHeight, // 接收次图高度
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.onGoingUp,
    this.onGoingDown,
    this.onMainGoingUp,
    this.onMainGoingDown,
    this.onUpProbs,
  })  : _secProviders = {
          SecondaryState.KDJ: const KdjSignalProvider(),
          SecondaryState.MACD: const MacdSignalProvider(),
          SecondaryState.RSI: const RsiSignalProvider(),
          SecondaryState.WR: const WrSignalProvider(),
          SecondaryState.WPR: const WprSignalProvider(),
          SecondaryState.CCI: const CciSignalProvider(),
          SecondaryState.STOCHASTIC: const StochSignalProvider(),
          SecondaryState.MOMENTUM: const MomentumSignalProvider(),
          SecondaryState.MFI: const MfiSignalProvider(),
          SecondaryState.DEMARKER: const DemSignalProvider(),
          SecondaryState.STDDEV: const StdDevSignalProvider(),
          SecondaryState.DMI: const DmiSignalProvider(),
          SecondaryState.ADX: const AdxOnlySignalProvider(),
          SecondaryState.AROON: const AroonSignalProvider(),
          SecondaryState.VORTEX: const VortexSignalProvider(),
          SecondaryState.SAR: const SarSignalProvider(),
          SecondaryState.ICHIMOKU: const IchimokuSignalProvider(),
          SecondaryState.TSI: const TsiSignalProvider(),
          SecondaryState.PPO: const PpoSignalProvider(),
          SecondaryState.TRIX: const TrixSignalProvider(),
          SecondaryState.OBV: const ObvSignalProvider(),
          SecondaryState.VWAP: const VwapSignalProvider(),
          SecondaryState.ADL: const AdlSignalProvider(),
          SecondaryState.ATR: const AtrSignalProvider(),
          SecondaryState.HV: const HvSignalProvider(),
          SecondaryState.VIX: const VixSignalProvider(),
          SecondaryState.VOLATILITY: const VolatilitySignalProvider(),
          SecondaryState.ENVELOPES: const EnvelopesSignalProvider(),
          // 若有
          // SecondaryState.BSSIGNAL: const BsSignalProvider(),
          // …… 如有更多副图指标，可一并注册
        },
        _mainProviders = {
          MainState.MA: MaCrossSignalProvider(),
          MainState.BOLL: BollSignalProvider(),
          // …… 如有更多主图指标，可一并注册
        },
        super(
          chartStyle,
          datas: datas,
          scaleX: scaleX,
          scrollX: scrollX,
          isLongPress: isLongPass,
          isOnTap: isOnTap,
          isTapShowInfoDialog: isTapShowInfoDialog,
          selectX: selectX,
          mainState: mainState,
          volHidden: volHidden,
          isShowMainState: isShowMainState,
          secondaryStates: secondaryStates,
          isLine: isLine,
        ) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = this.chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      var t = datas![0];
      fixedLength =
          NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    }

    // 初始化主图表渲染器
    if (isShowMainState) {
      double mainRectHeight =
          mainHeight ?? (mDisplayHeight * 0.6); // 使用自定义或默认高度
      mMainRect = Rect.fromLTRB(0, 0, mWidth, mainRectHeight); // 主图区域定义
      // print('[initChartRenderer] Main Renderer Initialized');
    } else {
      mMainRect = Rect.fromLTRB(0, 0, 0, 0); // 主图表高度设置为 0
    }

    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainState,
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      verticalTextAlignment,
      maDayList,
    );

    if (mVolRect != null) {
      double volRectHeight =
          secondaryHeight ?? (mDisplayHeight * 0.2); // 使用次图高度或默认值
      mVolRect = Rect.fromLTRB(
        0,
        mMainRect.bottom + mChildPadding,
        mWidth,
        mMainRect.bottom + mChildPadding + volRectHeight,
      );
      mVolRenderer = VolRenderer(
          mVolRect!,
          mVolMaxValue,
          mVolMinValue,
          mChildPadding,
          fixedLength,
          this.chartStyle,
          this.chartColors) as BaseChartRenderer?;
      // print(
      //     '[initChartRenderer] Volume Renderer Initialized: Rect = $mVolRect');
    }

    secondaryRenderers.clear();
    // double secondaryTop = mMainRect.bottom + (mVolRect?.height ?? 0) + mChildPadding;
    double secondaryTop =
        mVolRect?.bottom ?? mMainRect.bottom; // 基于成交量图的底部作为初始位置

    for (int i = 0; i < secondaryStates.length; i++) {
      double secondaryRectHeight = secondaryHeight ??
          (mDisplayHeight * 0.2) - mChildPadding; // 使用自定义或默认高度

      double newSecondaryRectHeight = i * (secondaryRectHeight + mChildPadding);
      if (i == 0) newSecondaryRectHeight = newSecondaryRectHeight + 10;

      Rect secondaryRect = Rect.fromLTRB(
        0,
        secondaryTop + newSecondaryRectHeight, // 累积次图高度
        mWidth,
        secondaryTop + ((i + 1) * secondaryRectHeight) + (i * mChildPadding),
      );

      // 这里从BaseChartPainter里拿对应的 max/min Map
      SecondaryState st = secondaryStates[i];
      double secMax = mSecondaryMaxMap[st] ?? 0;
      double secMin = mSecondaryMinMap[st] ?? 0;

      SecondaryRenderer renderer = SecondaryRenderer(
        secondaryRect,
        secondaryRect,
        secMax,
        secMin,
        mChildPadding,
        secondaryStates[i],
        fixedLength,
        this.chartStyle,
        this.chartColors,
      );

      secondaryRenderers.add(renderer);
      // print('[initChartRenderer] Initialized Secondary Renderer [$i]: '
      //     'State: ${secondaryStates[i]}, Rect: $secondaryRect');
    }

    // print(
    //     '[initChartRenderer] Secondary Renderers Count: ${secondaryRenderers.length}');
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint();
    Gradient mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: chartColors.bgColor,
    );

    if (isShowMainState) {
      Rect mainRect =
          Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
      canvas.drawRect(
          mainRect, mBgPaint..shader = mBgGradient.createShader(mainRect));
    }

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(
          volRect, mBgPaint..shader = mBgGradient.createShader(volRect));
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect!.top - mChildPadding,
          mSecondaryRect!.width, mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect,
          mBgPaint..shader = mBgGradient.createShader(secondaryRect));
    }
    Rect dateRect =
        Rect.fromLTRB(0, size.height - mBottomPadding, size.width, size.height);
    canvas.drawRect(
        dateRect, mBgPaint..shader = mBgGradient.createShader(dateRect));
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      if (isShowMainState == true) {
        mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);

        mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      }
      // mSecondaryRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      for (int j = 0; j < secondaryRenderers.length; j++) {
        secondaryRenderers[j]?.drawGrid(canvas, mGridRows, mGridColumns);
      }
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);
      if (isShowMainState == true) {
        mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);

        mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      }

      for (int j = 0; j < secondaryRenderers.length; j++) {
        // print('[drawChart] Renderer [$j]: Drawing state ${secondaryStates[j]}');

        secondaryRenderers[j]?.drawChart(
          lastPoint,
          curPoint,
          lastX,
          curX,
          size,
          canvas,
        );
        // 添加日志
        // print('[drawChart] Renderer [$j]: State = ${secondaryStates[j]}, '
        //     'Rect = ${secondaryRenderers[j]?.rect}');
      }

      // ---------- ★ 新增：KDJ 信号触发回调 ----------
      // if (secondaryStates.contains(SecondaryState.KDJ)) {
      //   // 只在可视范围最后一个 bar 上触发，避免一次渲染多次调用
      //   final isLastVisible = (i == mStopIndex);
      //   if (isLastVisible) {
      //     // 约定：KLineEntity 内部已经填充 buySignal / sellSignal 与 probability
      //     final prob = curPoint.probability ?? 1.0; // 默认为 1
      //     if (curPoint.buySignal == true) {
      //       onGoingUp?.call(prob);
      //     } else if (curPoint.sellSignal == true) {
      //       onGoingDown?.call(prob);
      //     }
      //   }
      // }
      // —— 副图信号回调 ——
      for (final st in secondaryStates) {
        final prov = _secProviders[st];
        if (prov != null && i == mStopIndex) {
          final prob = curPoint.probability ?? 1.0;
          if (prov.isBuy(datas!, i)) {
            onGoingUp?.call(prob);
          } else if (prov.isSell(datas!, i)) {
            onGoingDown?.call(prob);
          }
        }
      }

      // —— 主图信号回调 ——
      // if (i == mStopIndex) {
      //   final mprov = _mainProviders[mainState];
      //   if (mprov != null) {
      //     final prob = curPoint.probability ?? 1.0;
      //     if (mprov.isBuy(datas!, i)) {
      //       onMainGoingUp?.call(prob);
      //     } else if (mprov.isSell(datas!, i)) {
      //       onMainGoingDown?.call(prob);
      //     }
      //   }
      // }
      // chart_painter.dart -> drawChart(...) 循环内，紧跟在原有信号回调逻辑之后：
// —— 组装概率并上送 —— 只在最后一根触发，避免一屏里多次
      if (i == mStopIndex && onUpProbs != null) {
        // 主图概率
        double? mainUp;
        final mprov = _mainProviders[mainState];
        if (mprov != null) {
          mainUp = mprov.upProb(datas!, i);
        }

        // 副图概率
        final Map<SecondaryState, double?> secUps = {};
        for (final st in secondaryStates) {
          final prov = _secProviders[st];
          double? p;
          if (prov != null) {
            p = prov.upProb(datas!, i);
          } else {
            p = null; // 没有 provider 就不上送
          }
          secUps[st] = p;
        }

        final report = UpProbReport(
          index: i,
          time: curPoint.time,
          mainUp: mainUp,
          secondaryUps: secUps,
        );

        // 去抖：只有变了才上送
        if (_lastReport == null || !report.almostEquals(_lastReport!)) {
          _lastReport = report;
          onUpProbs?.call(report);
        }
      }
    }

    if ((isLongPress == true || (isTapShowInfoDialog && isOnTap)) &&
        isTrendLine == false) {
      drawCrossLine(canvas, size);
    }
    if (isTrendLine == true) drawTrendLines(canvas, size);

    canvas.restore();
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    if (!hideGrid) {
      mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);

      mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    }
    // mSecondaryRenderer?.drawVerticalText(canvas, textStyle, mGridRows);

    for (int j = 0; j < secondaryRenderers.length; j++) {
      secondaryRenderers[j]?.drawVerticalText(canvas, textStyle, mGridRows);
    }
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas![index].time), null);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(point.close, chartColors.crossTextColor);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = new Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = new Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.time), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    if (isShowMainState == true) {
      mMainRenderer.drawText(canvas, data, x);

      mVolRenderer?.drawText(canvas, data, x);
    }
    // mSecondaryRenderer?.drawText(canvas, data, x);
    for (final renderer in secondaryRenderers) {
      renderer?.drawText(canvas, data, x);
    }
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    if (isShowMainState == false) return;
    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
          "── " + mMainLowMinValue.toStringAsFixed(fixedLength),
          chartColors.minColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          mMainLowMinValue.toStringAsFixed(fixedLength) + " ──",
          chartColors.minColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
          "── " + mMainHighMaxValue.toStringAsFixed(fixedLength),
          chartColors.maxColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          mMainHighMaxValue.toStringAsFixed(fixedLength) + " ──",
          chartColors.maxColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!this.showNowPrice) {
      return;
    }

    if (!this.isShowMainState) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);

    //视图展示区域边界值绘制
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    nowPricePaint
      ..color = value >= datas!.last.open
          ? this.chartColors.nowPriceUpColor
          : this.chartColors.nowPriceDnColor;
    //先画横线
    double startX = 0;
    final max = -mTranslateX + mWidth / scaleX;
    final space =
        this.chartStyle.nowPriceLineSpan + this.chartStyle.nowPriceLineLength;
    while (startX < max) {
      canvas.drawLine(
          Offset(startX, y),
          Offset(startX + this.chartStyle.nowPriceLineLength, y),
          nowPricePaint);
      startX += space;
    }
    //再画背景和文本
    TextPainter tp = getTextPainter(
        value.toStringAsFixed(fixedLength), this.chartColors.nowPriceTextColor);

    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width;
        break;
    }

    double top = y - tp.height / 2;
    canvas.drawRect(
        Rect.fromLTRB(offsetX, top, offsetX + tp.width, top + tp.height),
        nowPricePaint);
    tp.paint(canvas, Offset(offsetX, top));
  }

//For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;
    // getMainY(point.close);

    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);
    Paint paintX = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
          paint);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
          paint);
    }
    if (lines.length >= 1) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        canvas.drawLine(
            p1,
            element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
            Paint()
              ..color = Colors.yellow
              ..strokeWidth = 2);
      });
    }
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = this.chartColors.vCrossColor
      ..strokeWidth = this.chartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);

    Paint paintX = Paint()
      ..color = this.chartColors.hCrossColor
      ..strokeWidth = this.chartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k线图横线
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
          paintX);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
          paintX);
    }
  }

  TextPainter getTextPainter(text, color) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  /// 点是否在SecondaryRect中
  // bool isInSecondaryRect(Offset point) {
  //   return mSecondaryRect?.contains(point) ?? false;
  // }

  bool isInSecondaryRect(Offset point) {
    for (int i = 0; i < secondaryRenderers.length; i++) {
      if (secondaryRenderers[i]?.rect.contains(point) ?? false) {
        return true;
      }
    }
    return false;
  }

  /// 点是否在MainRect中
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }
}

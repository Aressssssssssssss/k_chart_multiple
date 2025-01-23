import 'dart:ui';

import 'package:flutter/material.dart';

import '../flutter_k_chart.dart';

class SecondaryRenderer extends BaseChartRenderer<KLineEntity> {
  late double mMACDWidth;
  SecondaryState state;
  final ChartStyle chartStyle;
  final ChartColors chartColors;

  final Rect rect; // 添加 rect 属性

  SecondaryRenderer(
      this.rect,
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.state,
      int fixedLength,
      this.chartStyle,
      this.chartColors)
      : super(
          // chartRect: mainRect,
          chartRect: rect,

          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
        ) {
    mMACDWidth = this.chartStyle.macdWidth;
  }

  void drawIchimoku(
    KLineEntity lastPoint,
    KLineEntity curPoint,
    double lastX,
    double curX,
    Size size,
    Canvas canvas,
  ) {
    /// ---- 1) 画【云层填充】(SpanA和SpanB之间) ----
    /// 先拿到上一个点与当前点的span A/B
    final double? spanALast = lastPoint.ichimokuSpanA;
    final double? spanBLast = lastPoint.ichimokuSpanB;
    final double? spanACur = curPoint.ichimokuSpanA;
    final double? spanBCur = curPoint.ichimokuSpanB;

    // 如果任意一个数据是null，就没法画这段云
    // 同时还可判断isFinite防止NaN/Infinity
    if (spanALast != null &&
        spanBLast != null &&
        spanACur != null &&
        spanBCur != null &&
        spanALast.isFinite &&
        spanBLast.isFinite &&
        spanACur.isFinite &&
        spanBCur.isFinite) {
      double ySpanALast = getY(spanALast);
      double ySpanBLast = getY(spanBLast);
      double ySpanACur = getY(spanACur);
      double ySpanBCur = getY(spanBCur);

      // 构造一个4点闭合区域 path
      Path cloudPath = Path()
        ..moveTo(lastX, ySpanALast) // 左侧SpanA
        ..lineTo(curX, ySpanACur) // 右侧SpanA
        ..lineTo(curX, ySpanBCur) // 右侧SpanB
        ..lineTo(lastX, ySpanBLast) // 左侧SpanB
        ..close();

      Paint cloudPaint = Paint()
        ..isAntiAlias = true
        ..color = chartColors.ichimokuCloudColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      // 填充云层
      canvas.drawPath(cloudPath, cloudPaint);
    }

    /// ---- 2) 绘制5条线 (Tenkan, Kijun, SpanA, SpanB, Chikou) ----
    // 在画线时，也要注意null或无限值判断
    drawLine(lastPoint.ichimokuTenkan, curPoint.ichimokuTenkan, canvas, lastX,
        curX, chartColors.ichimokuTenkanColor);
    drawLine(lastPoint.ichimokuKijun, curPoint.ichimokuKijun, canvas, lastX,
        curX, chartColors.ichimokuKijunColor);
    drawLine(lastPoint.ichimokuSpanA, curPoint.ichimokuSpanA, canvas, lastX,
        curX, chartColors.ichimokuSpanAColor);
    drawLine(lastPoint.ichimokuSpanB, curPoint.ichimokuSpanB, canvas, lastX,
        curX, chartColors.ichimokuSpanBColor);
    drawLine(lastPoint.ichimokuChikou, curPoint.ichimokuChikou, canvas, lastX,
        curX, chartColors.ichimokuChikouColor);
  }

  @override
  void drawChart(KLineEntity lastPoint, KLineEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    switch (state) {
      case SecondaryState.WPR:
        // 只是一条线
        drawLine(lastPoint.wpr, curPoint.wpr, canvas, lastX, curX,
            chartColors.wprColor);
        break;

      case SecondaryState.STOCHASTIC:
        // 画 %K
        drawLine(lastPoint.stochK, curPoint.stochK, canvas, lastX, curX,
            chartColors.stochKColor);

        // 画 %D
        drawLine(lastPoint.stochD, curPoint.stochD, canvas, lastX, curX,
            chartColors.stochDColor);
        break;

      case SecondaryState.STDDEV:
        drawLine(lastPoint.stdDev, curPoint.stdDev, canvas, lastX, curX,
            chartColors.stdDevColor);
        break;

      case SecondaryState.ADX:
        drawLine(lastPoint.adx, curPoint.adx, canvas, lastX, curX,
            chartColors.adxColor);
        break;

      case SecondaryState.VIX:
        drawLine(lastPoint.vix, curPoint.vix, canvas, lastX, curX,
            chartColors.vixColor);
        break;

      case SecondaryState.ADL:
        drawLine(lastPoint.adl, curPoint.adl, canvas, lastX, curX,
            chartColors.adlColor);
        break;

      case SecondaryState.OBV:
        // 画OBV原始线
        drawLine(lastPoint.obv, curPoint.obv, canvas, lastX, curX,
            chartColors.obvColor);

        // 画OBV平滑线
        drawLine(lastPoint.obvEma, curPoint.obvEma, canvas, lastX, curX,
            chartColors.obvEmaColor);
        break;

      case SecondaryState.VWAP:
        drawLine(lastPoint.vwap, curPoint.vwap, canvas, lastX, curX,
            chartColors.vwapColor);
        break;

      case SecondaryState.HV:
        drawLine(lastPoint.hv, curPoint.hv, canvas, lastX, curX,
            chartColors.hvColor);
        break;

      case SecondaryState.ATR:
        drawLine(lastPoint.atr, curPoint.atr, canvas, lastX, curX,
            chartColors.atrColor);
        break;

      case SecondaryState.VORTEX:
        drawLine(lastPoint.viPlus, curPoint.viPlus, canvas, lastX, curX,
            chartColors.vortexPlusColor);
        drawLine(lastPoint.viMinus, curPoint.viMinus, canvas, lastX, curX,
            chartColors.vortexMinusColor);
        break;

      case SecondaryState.AROON:
        // 画3条线
        drawLine(lastPoint.aroonUp, curPoint.aroonUp, canvas, lastX, curX,
            chartColors.aroonUpColor);
        drawLine(lastPoint.aroonDown, curPoint.aroonDown, canvas, lastX, curX,
            chartColors.aroonDownColor);
        // Osc(可选)
        drawLine(lastPoint.aroonOsc, curPoint.aroonOsc, canvas, lastX, curX,
            chartColors.aroonOscColor);
        break;

      case SecondaryState.SAR:
        // 画一条线 or 一系列点
        // 1) 你可以直接在 drawChart(lastPoint, curPoint) 里用 drawLine(...) or drawCircle(...)

        // 演示：点对点画圆 (可替换成 line)
        final psarLast = lastPoint.psar;
        final psarCur = curPoint.psar;
        if (psarLast != null && psarLast.isFinite) {
          double yLast = getY(psarLast);
          Paint p = chartPaint
            ..color =
                curPoint.psarIsUp! ? chartColors.upColor : chartColors.dnColor
            ..style = PaintingStyle.fill
            ..strokeWidth = 1.0;

          // 这里画上一个点
          // lastX, yLast => 2.5半径的小圆
          canvas.drawCircle(Offset(lastX, yLast), 2.5, p);
        }

        if (psarCur != null && psarCur.isFinite) {
          double yCur = getY(psarCur);
          Paint p = chartPaint
            ..color =
                curPoint.psarIsUp! ? chartColors.upColor : chartColors.dnColor
            ..style = PaintingStyle.fill
            ..strokeWidth = 1.0;
          // 这里画当前点
          canvas.drawCircle(Offset(curX, yCur), 2.5, p);
        }
        break;

      case SecondaryState.ICHIMOKU:
        drawIchimoku(lastPoint, curPoint, lastX, curX, size, canvas);
        break;

      case SecondaryState.TSI:
        // 画 TSI主线
        drawLine(lastPoint.tsi, curPoint.tsi, canvas, lastX, curX,
            chartColors.tsiColor);
        // 再画 TSI 信号线
        drawLine(lastPoint.tsiSignal, curPoint.tsiSignal, canvas, lastX, curX,
            chartColors.tsiSignalColor);
        break;
      case SecondaryState.PPO:
        // 与MACD类似，画柱状或线？
        // 常见做法：PPO主线 & PPO信号线 两条线
        drawLine(lastPoint.ppo, curPoint.ppo, canvas, lastX, curX,
            chartColors.ppoColor);
        drawLine(lastPoint.ppoSignal, curPoint.ppoSignal, canvas, lastX, curX,
            chartColors.ppoSignalColor);
        break;
      case SecondaryState.TRIX:
        drawLine(lastPoint.trix, curPoint.trix, canvas, lastX, curX,
            chartColors.trixColor);
        drawLine(lastPoint.trixSignal, curPoint.trixSignal, canvas, lastX, curX,
            chartColors.trixSignalColor);
        break;
      case SecondaryState.DMI:
        // 画pdi、mdi、adx (以及adxr)
        drawLine(lastPoint.pdi, curPoint.pdi, canvas, lastX, curX,
            chartColors.dmiPdiColor);
        drawLine(lastPoint.mdi, curPoint.mdi, canvas, lastX, curX,
            chartColors.dmiMdiColor);
        drawLine(lastPoint.adx, curPoint.adx, canvas, lastX, curX,
            chartColors.dmiAdxColor);
        // 如果还有 adxr
        drawLine(lastPoint.adxr, curPoint.adxr, canvas, lastX, curX,
            chartColors.dmiAdxrColor);
        break;
      case SecondaryState.MACD:
        drawMACD(curPoint, canvas, curX, lastPoint, lastX);
        break;
      case SecondaryState.KDJ:
        drawLine(lastPoint.k, curPoint.k, canvas, lastX, curX,
            this.chartColors.kColor);
        drawLine(lastPoint.d, curPoint.d, canvas, lastX, curX,
            this.chartColors.dColor);
        drawLine(lastPoint.j, curPoint.j, canvas, lastX, curX,
            this.chartColors.jColor);
        break;
      case SecondaryState.RSI:
        drawLine(lastPoint.rsi, curPoint.rsi, canvas, lastX, curX,
            this.chartColors.rsiColor);
        break;
      case SecondaryState.WR:
        drawLine(lastPoint.r, curPoint.r, canvas, lastX, curX,
            this.chartColors.rsiColor);
        break;
      case SecondaryState.CCI:
        drawLine(lastPoint.cci, curPoint.cci, canvas, lastX, curX,
            this.chartColors.rsiColor);
        break;
      default:
        break;
    }
  }

  void drawMACD(KLineEntity curPoint, Canvas canvas, double curX,
      KLineEntity lastPoint, double lastX) {
    final macd = curPoint.macd ?? 0;
    double macdY = getY(macd);
    double r = mMACDWidth / 2;
    double zeroy = getY(0);
    if (macd > 0) {
      canvas.drawRect(Rect.fromLTRB(curX - r, macdY, curX + r, zeroy),
          chartPaint..color = this.chartColors.upColor);
    } else {
      canvas.drawRect(Rect.fromLTRB(curX - r, zeroy, curX + r, macdY),
          chartPaint..color = this.chartColors.dnColor);
    }
    if (lastPoint.dif != 0) {
      drawLine(lastPoint.dif, curPoint.dif, canvas, lastX, curX,
          this.chartColors.difColor);
    }
    if (lastPoint.dea != 0) {
      drawLine(lastPoint.dea, curPoint.dea, canvas, lastX, curX,
          this.chartColors.deaColor);
    }
    if (lastPoint.osma != 0) {
      drawLine(lastPoint.osma, curPoint.osma, canvas, lastX, curX,
          chartColors.osmaColor);
    }
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    List<TextSpan>? children;
    switch (state) {
      case SecondaryState.WPR:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "WPR(14)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.wpr != null) {
          spans.add(TextSpan(
            text: "%R:${format(data.wpr)}  ",
            style: getTextStyle(chartColors.wprColor),
          ));
        }
        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.STOCHASTIC:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "Stoch(14,3)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.stochK != null) {
          spans.add(TextSpan(
            text: "K:${format(data.stochK)}  ",
            style: getTextStyle(chartColors.stochKColor),
          ));
        }
        if (data.stochD != null) {
          spans.add(TextSpan(
            text: "D:${format(data.stochD)}  ",
            style: getTextStyle(chartColors.stochDColor),
          ));
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.STDDEV:
        List<TextSpan> spans = [];
        spans.add(TextSpan(
          text: "StdDev(14)  ",
          style: getTextStyle(chartColors.defaultTextColor),
        ));
        if (data.stdDev != null) {
          spans.add(TextSpan(
            text: "SD:${format(data.stdDev)}  ",
            style: getTextStyle(chartColors.stdDevColor),
          ));
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.ADX:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "ADX(14)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.adx != null) {
          spans.add(
            TextSpan(
              text: "ADX:${format(data.adx)}  ",
              style: getTextStyle(chartColors.adxColor),
            ),
          );
        }
        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.VIX:
        List<TextSpan> spans = [];
        spans.add(TextSpan(
          text: "VIX(14)  ", // 如果你算14日近似
          style: getTextStyle(chartColors.defaultTextColor),
        ));
        if (data.vix != null) {
          spans.add(TextSpan(
            text: "VIX:${format(data.vix)}  ",
            style: getTextStyle(chartColors.vixColor),
          ));
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.ADL:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "A/D Line  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.adl != null) {
          spans.add(TextSpan(
            text: "ADL:${format(data.adl)}  ",
            style: getTextStyle(chartColors.adlColor),
          ));
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.OBV:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "OBV(Vol), EMA(10)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.obv != null) {
          spans.add(TextSpan(
            text: "OBV:${format(data.obv)}  ",
            style: getTextStyle(chartColors.obvColor),
          ));
        }
        if (data.obvEma != null) {
          spans.add(TextSpan(
            text: "OBV-EMA:${format(data.obvEma)}  ",
            style: getTextStyle(chartColors.obvEmaColor),
          ));
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.VWAP:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "VWAP  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.vwap != null) {
          spans.add(
            TextSpan(
              text: "VWAP:${format(data.vwap)}  ",
              style: getTextStyle(chartColors.vwapColor),
            ),
          );
        }
        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.HV:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "HV(14)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.hv != null) {
          spans.add(
            TextSpan(
              text: "HV:${format(data.hv)}  ", // 假设data.hv=25.3 -> "25.30"
              style: getTextStyle(chartColors.hvColor),
            ),
          );
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.ATR:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "ATR(14)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.atr != null) {
          spans.add(
            TextSpan(
              text: "ATR:${format(data.atr)}  ",
              style: getTextStyle(chartColors.atrColor),
            ),
          );
        }
        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.VORTEX:
        List<TextSpan> children = [];
        children.add(
          TextSpan(
            text: "Vortex(14)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.viPlus != null) {
          children.add(TextSpan(
            text: "+VI:${format(data.viPlus)}  ",
            style: getTextStyle(chartColors.vortexPlusColor),
          ));
        }
        if (data.viMinus != null) {
          children.add(TextSpan(
            text: "-VI:${format(data.viMinus)}  ",
            style: getTextStyle(chartColors.vortexMinusColor),
          ));
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: children),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.AROON:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "Aroon(14)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );

        if (data.aroonUp != null) {
          spans.add(TextSpan(
            text: "Up:${format(data.aroonUp)}  ",
            style: getTextStyle(chartColors.aroonUpColor),
          ));
        }
        if (data.aroonDown != null) {
          spans.add(TextSpan(
            text: "Down:${format(data.aroonDown)}  ",
            style: getTextStyle(chartColors.aroonDownColor),
          ));
        }
        if (data.aroonOsc != null) {
          spans.add(TextSpan(
            text: "Osc:${format(data.aroonOsc)}  ",
            style: getTextStyle(chartColors.aroonOscColor),
          ));
        }

        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.SAR:
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "SAR(0.02,0.2)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );
        if (data.psar != null) {
          spans.add(
            TextSpan(
              text: "PSAR:${format(data.psar)}  ",
              style: getTextStyle(chartColors.sarColor),
            ),
          );
        }

        // 组装
        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.ICHIMOKU:
        // 组合5条线的字段到 children
        List<TextSpan> spans = [];
        spans.add(
          TextSpan(
            text: "Ichimoku(9,26,52)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
        );

        if (data.ichimokuTenkan != null) {
          spans.add(TextSpan(
              text: "Tenkan:${format(data.ichimokuTenkan)}  ",
              style: getTextStyle(chartColors.ichimokuTenkanColor)));
        }
        if (data.ichimokuKijun != null) {
          spans.add(TextSpan(
              text: "Kijun:${format(data.ichimokuKijun)}  ",
              style: getTextStyle(chartColors.ichimokuKijunColor)));
        }
        if (data.ichimokuSpanA != null) {
          spans.add(TextSpan(
              text: "SpanA:${format(data.ichimokuSpanA)}  ",
              style: getTextStyle(chartColors.ichimokuSpanAColor)));
        }
        if (data.ichimokuSpanB != null) {
          spans.add(TextSpan(
              text: "SpanB:${format(data.ichimokuSpanB)}  ",
              style: getTextStyle(chartColors.ichimokuSpanBColor)));
        }
        if (data.ichimokuChikou != null) {
          spans.add(TextSpan(
              text: "Chikou:${format(data.ichimokuChikou)}  ",
              style: getTextStyle(chartColors.ichimokuChikouColor)));
        }

        // 将span列表转成TextSpan
        TextPainter tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        // 在 secondaryRect 顶部一点的位置画文字
        tp.paint(canvas, Offset(x, chartRect.top - topPadding));
        break;

      case SecondaryState.TSI:
        children = [
          TextSpan(
              text: "TSI(25,13,9)  ",
              style: getTextStyle(chartColors.defaultTextColor)),
          if (data.tsi != null)
            TextSpan(
                text: "TSI:${format(data.tsi)}  ",
                style: getTextStyle(chartColors.tsiColor)),
          if (data.tsiSignal != null)
            TextSpan(
                text: "SIGNAL:${format(data.tsiSignal)}  ",
                style: getTextStyle(chartColors.tsiSignalColor)),
        ];
        break;

      case SecondaryState.PPO:
        children = [
          TextSpan(
            text: "PPO(12,26,9)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
          if (data.ppo != null)
            TextSpan(
              text: "PPO:${format(data.ppo)}  ",
              style: getTextStyle(chartColors.ppoColor),
            ),
          if (data.ppoSignal != null)
            TextSpan(
              text: "SIGNAL:${format(data.ppoSignal)}  ",
              style: getTextStyle(chartColors.ppoSignalColor),
            ),
        ];
        break;
      case SecondaryState.TRIX:
        children = [
          TextSpan(
            text: "TRIX(12,9)  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
          if (data.trix != null)
            TextSpan(
              text: "TRIX:${format(data.trix)}  ",
              style: getTextStyle(chartColors.trixColor),
            ),
          if (data.trixSignal != null)
            TextSpan(
              text: "SIGNAL:${format(data.trixSignal)}  ",
              style: getTextStyle(chartColors.trixSignalColor),
            ),
        ];
        break;
      case SecondaryState.DMI:
        children = [
          TextSpan(
            text: "DMI(14):  ",
            style: getTextStyle(chartColors.defaultTextColor),
          ),
          if (data.pdi != null)
            TextSpan(
              text: "PDI:${format(data.pdi)}  ",
              style: getTextStyle(chartColors.dmiPdiColor),
            ),
          if (data.mdi != null)
            TextSpan(
              text: "MDI:${format(data.mdi)}  ",
              style: getTextStyle(chartColors.dmiMdiColor),
            ),
          if (data.adx != null)
            TextSpan(
              text: "ADX:${format(data.adx)}  ",
              style: getTextStyle(chartColors.dmiAdxColor),
            ),
          if (data.adxr != null)
            TextSpan(
              text: "ADXR:${format(data.adxr)}  ",
              style: getTextStyle(chartColors.dmiAdxrColor),
            ),
        ];
        break;
      case SecondaryState.MACD:
        children = [
          TextSpan(
              text: "MACD(12,26,9)    ",
              style: getTextStyle(this.chartColors.defaultTextColor)),
          if (data.macd != 0)
            TextSpan(
                text: "MACD:${format(data.macd)}    ",
                style: getTextStyle(this.chartColors.macdColor)),
          if (data.dif != 0)
            TextSpan(
                text: "DIF:${format(data.dif)}    ",
                style: getTextStyle(this.chartColors.difColor)),
          if (data.dea != 0)
            TextSpan(
                text: "DEA:${format(data.dea)}    ",
                style: getTextStyle(this.chartColors.deaColor)),
          if (data.osma != 0)
            TextSpan(
              text: "OsMA:${format(data.osma)}  ",
              style: getTextStyle(chartColors.osmaColor),
            )
        ];
        break;
      case SecondaryState.KDJ:
        children = [
          TextSpan(
              text: "KDJ(9,1,3)    ",
              style: getTextStyle(this.chartColors.defaultTextColor)),
          if (data.macd != 0)
            TextSpan(
                text: "K:${format(data.k)}    ",
                style: getTextStyle(this.chartColors.kColor)),
          if (data.dif != 0)
            TextSpan(
                text: "D:${format(data.d)}    ",
                style: getTextStyle(this.chartColors.dColor)),
          if (data.dea != 0)
            TextSpan(
                text: "J:${format(data.j)}    ",
                style: getTextStyle(this.chartColors.jColor)),
        ];
        break;
      case SecondaryState.RSI:
        children = [
          TextSpan(
              text: "RSI(14):${format(data.rsi)}    ",
              style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      case SecondaryState.WR:
        children = [
          TextSpan(
              text: "WR(14):${format(data.r)}    ",
              style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      case SecondaryState.CCI:
        children = [
          TextSpan(
              text: "CCI(14):${format(data.cci)}    ",
              style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      default:
        break;
    }
    TextPainter tp = TextPainter(
        text: TextSpan(children: children ?? []),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextPainter maxTp = TextPainter(
        text: TextSpan(text: "${format(maxValue)}", style: textStyle),
        textDirection: TextDirection.ltr);
    maxTp.layout();
    TextPainter minTp = TextPainter(
        text: TextSpan(text: "${format(minValue)}", style: textStyle),
        textDirection: TextDirection.ltr);
    minTp.layout();

    maxTp.paint(canvas,
        Offset(chartRect.width - maxTp.width, chartRect.top - topPadding));
    minTp.paint(canvas,
        Offset(chartRect.width - minTp.width, chartRect.bottom - minTp.height));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.top),
        Offset(chartRect.width, chartRect.top), gridPaint);
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //mSecondaryRect垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}

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

  @override
  void drawChart(KLineEntity lastPoint, KLineEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    switch (state) {
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

  void drawMACD(MACDEntity curPoint, Canvas canvas, double curX,
      MACDEntity lastPoint, double lastX) {
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
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    List<TextSpan>? children;
    switch (state) {
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

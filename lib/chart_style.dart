import 'package:flutter/material.dart' show Color, Colors;

class ChartColors {
  List<Color> bgColor = [Color(0xff18191d), Color(0xff18191d)];

  Color kLineColor = Color(0xff4C86CD);
  Color lineFillColor = Color(0x554C86CD);
  Color lineFillInsideColor = Color(0x00000000);
  Color ma5Color = Color(0xffC9B885);
  Color ma10Color = Color(0xff6CB0A6);
  Color ma30Color = Color(0xff9979C6);
  Color upColor = Color(0xff4DAA90);
  Color dnColor = Color(0xffC15466);
  Color volColor = Color(0xff4729AE);

  Color macdColor = Color(0xff4729AE);
  Color difColor = Color(0xffC9B885);
  Color deaColor = Color(0xff6CB0A6);

  Color kColor = Color(0xffC9B885);
  Color dColor = Color(0xff6CB0A6);
  Color jColor = Color(0xff9979C6);

  Color rsiColor = Color(0xffC9B885);

  Color defaultTextColor = Color(0xff60738E);

  Color nowPriceUpColor = Color(0xff4DAA90);
  Color nowPriceDnColor = Color(0xffC15466);
  Color nowPriceTextColor = Color(0xffffffff);

  //深度颜色
  Color depthBuyColor = Color(0xff60A893);
  Color depthSellColor = Color(0xffC15866);

  //选中后显示值边框颜色
  Color selectBorderColor = Color(0xff6C7A86);

  //选中后显示值背景的填充颜色
  Color selectFillColor = Color(0xff0D1722);

  //分割线颜色
  Color gridColor = Color(0xff4c5c74);

  Color infoWindowNormalColor = Color(0xffffffff);
  Color infoWindowTitleColor = Color(0xffffffff);
  Color infoWindowUpColor = Color(0xff00ff00);
  Color infoWindowDnColor = Color(0xffff0000);

  Color hCrossColor = Color(0xffffffff);
  Color vCrossColor = Color(0x1Effffff);
  Color crossTextColor = Color(0xffffffff);

  //当前显示内最大和最小值的颜色
  Color maxColor = Color(0xffffffff);
  Color minColor = Color(0xffffffff);

  Color getMAColor(int index) {
    switch (index % 3) {
      case 1:
        return ma10Color;
      case 2:
        return ma30Color;
      default:
        return ma5Color;
    }
  }

  /// DMI: +DI (pdi)
  Color dmiPdiColor = Colors.orange;

  /// DMI: -DI (mdi)
  Color dmiMdiColor = Colors.cyan;

  /// DMI: ADX
  Color dmiAdxColor = Colors.pink;

  /// DMI: ADXR
  Color dmiAdxrColor = Colors.purple;

  Color trixColor = Colors.deepOrange; // TRIX主线
  Color trixSignalColor = Colors.purple; // TRIX信号线

  Color ppoColor = Colors.orange;
  Color ppoSignalColor = Colors.purple;

  Color tsiColor = Colors.orangeAccent;
  Color tsiSignalColor = Colors.deepPurpleAccent;

  // 线条颜色
  Color ichimokuTenkanColor = Colors.red;
  Color ichimokuKijunColor = Colors.blue;
  Color ichimokuSpanAColor = Colors.green;
  Color ichimokuSpanBColor = Colors.purple;
  Color ichimokuChikouColor = Colors.orange;

  // 云层填充色
  Color ichimokuCloudColor =
      Colors.green; // 纯色, 实际绘制时会调用 .withValues(alpha: 0.2)

  Color sarColor = Colors.pink;

  Color aroonUpColor = Colors.green;
  Color aroonDownColor = Colors.red;
  Color aroonOscColor = Colors.blue;

  Color vortexPlusColor = Colors.orange;
  Color vortexMinusColor = Colors.cyan;

  Color atrColor = Colors.orange;

  Color hvColor = Colors.deepOrange;

  Color vwapColor = Colors.blueAccent;

  Color obvColor = Colors.blue; // OBV原始线
  Color obvEmaColor = Colors.orange; // 对OBV平滑后的线

  Color adlColor = Colors.purple;

  Color marketProfileColor = Colors.cyan; // 你喜欢的颜色

  Color vixColor = Colors.pinkAccent;

  Color adxColor = Colors.orangeAccent;
  Color stdDevColor = Colors.deepPurpleAccent;

  Color osmaColor = Colors.blueGrey;

  Color stochKColor = Colors.green;
  Color stochDColor = Colors.red;

  Color wprColor = Colors.indigo;

  Color demColor = Colors.cyan; // DeMarker线

  Color momentumColor = Colors.indigo;
  Color mfiColor = Colors.deepOrangeAccent;

  Color envMidColor = Colors.blue; // 中轨
  Color envUpColor = Colors.green; // 上轨
  Color envDnColor = Colors.red; // 下轨

  Color volIndicatorColor = Colors.blueGrey;

  Color buySignalColor = Colors.green;
  Color sellSignalColor = Colors.red;

  Color cmfColor = Colors.tealAccent;
  Color chaikinOscColor = Colors.amberAccent;
  Color klingerColor = Colors.lightBlueAccent;
  Color klingerSignalColor = Colors.pinkAccent;
  Color vptColor = Colors.limeAccent;
  Color forceIndexColor = Colors.cyanAccent;
  Color rocColor = Colors.orangeAccent;
  Color rocSignalColor = Colors.deepPurpleAccent;
  Color ultimateOscColor = Colors.yellowAccent;
  Color connorsRsiColor = Colors.lightGreenAccent;
  Color stochRsiKColor = Colors.greenAccent;
  Color stochRsiDColor = Colors.redAccent;
  Color rviColor = Colors.blueAccent;
  Color rviSignalColor = Colors.deepOrangeAccent;
  Color dpoColor = Colors.deepPurple;
  Color kamaColor = Colors.cyan;
  Color hmaColor = Colors.lime;
  Color keltnerMidColor = Colors.blueGrey;
  Color keltnerUpColor = Colors.greenAccent;
  Color keltnerDnColor = Colors.redAccent;
  Color donchianMidColor = Colors.blueGrey;
  Color donchianUpColor = Colors.green;
  Color donchianDnColor = Colors.red;
  Color bollBandwidthColor = Colors.lightBlue;
  Color chaikinVolatilityColor = Colors.pinkAccent;
  Color hvPercentileColor = Colors.indigoAccent;
  Color atrPercentileColor = Colors.deepOrange;
  Color elderBullColor = Colors.greenAccent;
  Color elderBearColor = Colors.redAccent;
  Color ichimokuSpanDiffColor = Colors.amber;
  Color pivotColor = Colors.blueGrey;
  Color pivotResistanceColor = Colors.redAccent;
  Color pivotSupportColor = Colors.greenAccent;
  Color gann1x1Color = Colors.orangeAccent;
  Color gann1x2Color = Colors.cyanAccent;
  Color gann2x1Color = Colors.purpleAccent;
}

class ChartStyle {
  double topPadding = 30.0;

  double bottomPadding = 20.0;

  double childPadding = 12.0;

  //点与点的距离
  double pointWidth = 11.0;

  //蜡烛宽度
  double candleWidth = 8.5;

  //蜡烛中间线的宽度
  double candleLineWidth = 1.5;

  //vol柱子宽度
  double volWidth = 8.5;

  //macd柱子宽度
  double macdWidth = 3.0;

  //垂直交叉线宽度
  double vCrossWidth = 8.5;

  //水平交叉线宽度
  double hCrossWidth = 0.5;

  //现在价格的线条长度
  double nowPriceLineLength = 1;

  //现在价格的线条间隔
  double nowPriceLineSpan = 1;

  //现在价格的线条粗细
  double nowPriceLineWidth = 1;

  int gridRows = 4;

  int gridColumns = 4;

  //下方時間客製化
  List<String>? dateTimeFormat;
}

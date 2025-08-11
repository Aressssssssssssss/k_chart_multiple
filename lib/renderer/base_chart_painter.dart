import 'dart:math' as math;

import 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:k_chart_multiple/flutter_k_chart.dart';

import '../entity/trade_mark.dart';

export 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;

abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;
  List<KLineEntity>? datas;
  MainState mainState;
  bool isShowMainState;
  // SecondaryState secondaryState;
  final List<SecondaryState> secondaryStates; // 替换原有单一字段

  bool volHidden;
  bool isTapShowInfoDialog;
  double scaleX = 1.0, scrollX = 0.0, selectX;
  bool isLongPress = false;
  bool isOnTap;
  bool isLine;

  //3块区域大小与位置
  late Rect mMainRect;
  Rect? mVolRect, mSecondaryRect;
  late double mDisplayHeight, mWidth;
  double mTopPadding = 30.0, mBottomPadding = 20.0, mChildPadding = 12.0;
  int mGridRows = 4, mGridColumns = 4;
  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = double.minPositive, mMainMinValue = double.maxFinite;
  double mVolMaxValue = double.minPositive, mVolMinValue = double.maxFinite;
  // double mSecondaryMaxValue = double.minPositive,
  //     mSecondaryMinValue = double.maxFinite;

  // 用一个 Map<SecondaryState, double> 来存取相应的max/min
  late Map<SecondaryState, double> mSecondaryMaxMap;
  late Map<SecondaryState, double> mSecondaryMinMap;

  double mTranslateX = double.minPositive;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = double.minPositive,
      mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0; //数据占屏幕总长度
  final ChartStyle chartStyle;
  late double mPointWidth;
  List<String> mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn]; //格式化时间

  List<TradeMark> tradeMarks;
  bool showTradeMarks;

  BaseChartPainter(
    this.chartStyle, {
    this.datas,
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    this.isOnTap = false,
    this.isShowMainState = true,
    this.mainState = MainState.MA,
    this.volHidden = false,
    this.isTapShowInfoDialog = false,
    // this.secondaryState = SecondaryState.MACD,
    this.secondaryStates = const [SecondaryState.MACD], // 初始化为默认值

    this.isLine = false,
    // 新增两个可选参数（给旧代码默认值不破坏）
    this.tradeMarks = const [],
    this.showTradeMarks = true,
  }) {
    mItemCount = datas?.length ?? 0;
    mPointWidth = this.chartStyle.pointWidth;
    mTopPadding = this.chartStyle.topPadding;
    mBottomPadding = this.chartStyle.bottomPadding;
    mChildPadding = this.chartStyle.childPadding;
    mGridRows = this.chartStyle.gridRows;
    mGridColumns = this.chartStyle.gridColumns;
    mDataLen = mItemCount * mPointWidth;
    // 针对每种 secondaryState 初始化默认的 max/min
    mSecondaryMaxMap = {};
    mSecondaryMinMap = {};
    for (final st in secondaryStates) {
      // mSecondaryMaxMap[st] = double.minPositive;//导致TRIX线无效
      // mSecondaryMinMap[st] = double.maxFinite;
      mSecondaryMaxMap[st] = -double.infinity; // 或 -double.maxFinite
      mSecondaryMinMap[st] = double.infinity;
    }
    initFormats();
  }

  void setTradeMarks(List<TradeMark> marks) {
    tradeMarks = marks;
  }

  void initFormats() {
    if (this.chartStyle.dateTimeFormat != null) {
      mFormats = this.chartStyle.dateTimeFormat!;
      return;
    }

    if (mItemCount < 2) {
      mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
      return;
    }

    int firstTime = datas!.first.time ?? 0;
    int secondTime = datas![1].time ?? 0;
    int time = secondTime - firstTime;
    time ~/= 1000;
    //月线
    if (time >= 24 * 60 * 60 * 28)
      mFormats = [yy, '-', mm];
    //日线等
    else if (time >= 24 * 60 * 60)
      mFormats = [yy, '-', mm, '-', dd];
    //小时线等
    else
      mFormats = [mm, '-', dd, ' ', HH, ':', nn];
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    mDisplayHeight = size.height - mTopPadding - mBottomPadding;
    mWidth = size.width;
    initRect(size);
    calculateValue();
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (datas != null && datas!.isNotEmpty) {
      drawChart(canvas, size);
      drawVerticalText(canvas);
      drawDate(canvas, size);

      drawText(canvas, datas!.last, 5);
      drawMaxAndMin(canvas);
      drawNowPrice(canvas);

      if (isLongPress == true || (isTapShowInfoDialog && isOnTap)) {
        drawCrossLineText(canvas, size);
      }
    }
    canvas.restore();
  }

  void initChartRenderer();

  //画背景
  void drawBg(Canvas canvas, Size size);

  //画网格
  void drawGrid(canvas);

  //画图表
  void drawChart(Canvas canvas, Size size);

  //画右边值
  void drawVerticalText(canvas);

  //画时间
  void drawDate(Canvas canvas, Size size);

  //画值
  void drawText(Canvas canvas, KLineEntity data, double x);

  //画最大最小值
  void drawMaxAndMin(Canvas canvas);

  //画当前价格
  void drawNowPrice(Canvas canvas);

  //画交叉线
  void drawCrossLine(Canvas canvas, Size size);

  //交叉线值
  void drawCrossLineText(Canvas canvas, Size size);

  void initRect(Size size) {
    double volHeight = volHidden != true ? mDisplayHeight * 0.2 : 0;
    double secondaryHeight =
        secondaryStates.isNotEmpty ? mDisplayHeight * 0.2 : 0;

    // 主图表高度计算
    double mainHeight =
        mDisplayHeight - volHeight - (secondaryHeight * secondaryStates.length);

    // 主图表区域
    mMainRect = Rect.fromLTRB(0, mTopPadding, mWidth, mTopPadding + mainHeight);

    // 成交量图表区域
    if (volHidden != true) {
      mVolRect = Rect.fromLTRB(0, mMainRect.bottom + mChildPadding, mWidth,
          mMainRect.bottom + volHeight);
    }

    // 副图区域
    if (secondaryStates.isNotEmpty) {
      mSecondaryRect = Rect.fromLTRB(
          0,
          mVolRect?.bottom ?? mMainRect.bottom + mChildPadding,
          mWidth,
          (mVolRect?.bottom ?? mMainRect.bottom) + secondaryHeight);
    }

    // 添加日志
    // print('[initRect] Main Rect: $mMainRect');
    // print('[initRect] Vol Rect: $mVolRect');
    // print('[initRect] Secondary Rect: $mSecondaryRect');
  }

  calculateValue() {
    if (datas == null) return;
    if (datas!.isEmpty) return;

    // 如果用户配置了要显示DMI，则先计算DMI
    // if (secondaryStates.contains(SecondaryState.DMI)) {
    //   _computeDMI(datas!); // period可自定义
    // }
    // 如果用户勾选了DMI, 就内部计算DMI
    // if (secondaryStates.contains(SecondaryState.DMI)) {
    //   _computeDMIAdvanced(
    //     datas!,
    //     period: 14,
    //     useAdxr: true, // 要不要计算ADXR
    //     adxrPeriod: 14,
    //     smoothMethod: 'ema', // 这里演示"双重平滑"
    //   );
    // }

    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      var item = datas![i];
      getMainMaxMinValue(item, i);
      getVolMaxMinValue(item);
      // getSecondaryMaxMinValue(item);
      // 3）更新每个 SecondaryState 的最大最小值
      for (final st in secondaryStates) {
        double oldMax = mSecondaryMaxMap[st] ?? double.minPositive;
        double oldMin = mSecondaryMinMap[st] ?? double.maxFinite;
        double newMax = oldMax;
        double newMin = oldMin;
        if (st == SecondaryState.VOLATILITY) {
          double? val = item.volIndicator;
          if (val != null && val.isFinite) {
            if (val > newMax) newMax = val;
            if (val < newMin) newMin = val;
          }
        } else if (st == SecondaryState.ENVELOPES) {
          // 3条线: envMid, envUp, envDn
          if (item.envMid != null && item.envMid!.isFinite) {
            if (item.envMid! > newMax) newMax = item.envMid!;
            if (item.envMid! < newMin) newMin = item.envMid!;
          }
          if (item.envUp != null && item.envUp!.isFinite) {
            if (item.envUp! > newMax) newMax = item.envUp!;
            if (item.envUp! < newMin) newMin = item.envUp!;
          }
          if (item.envDn != null && item.envDn!.isFinite) {
            if (item.envDn! > newMax) newMax = item.envDn!;
            if (item.envDn! < newMin) newMin = item.envDn!;
          }
        } else if (st == SecondaryState.MFI) {
          double? mfiVal = item.mfi;
          if (mfiVal != null && mfiVal.isFinite) {
            if (mfiVal > newMax) newMax = mfiVal;
            if (mfiVal < newMin) newMin = mfiVal;
          }
        } else if (st == SecondaryState.MOMENTUM) {
          double? val = item.momentum;
          if (val != null && val.isFinite) {
            if (val > newMax) newMax = val;
            if (val < newMin) newMin = val;
          }
        } else if (st == SecondaryState.DEMARKER) {
          double? demVal = item.dem;
          if (demVal != null && demVal.isFinite) {
            if (demVal > newMax) newMax = demVal;
            if (demVal < newMin) newMin = demVal;
          }
        } else if (st == SecondaryState.WPR) {
          double? wVal = item.wpr;
          if (wVal != null && wVal.isFinite) {
            // 常见 wVal在 -100..0
            // 但为了兼容，还是正常比较
            if (wVal > newMax) newMax = wVal;
            if (wVal < newMin) newMin = wVal;
          }
        } else if (st == SecondaryState.STOCHASTIC) {
          // stochK, stochD
          double? kVal = item.stochK;
          double? dVal = item.stochD;
          if (kVal != null && kVal.isFinite) {
            if (kVal > newMax) newMax = kVal;
            if (kVal < newMin) newMin = kVal;
          }
          if (dVal != null && dVal.isFinite) {
            if (dVal > newMax) newMax = dVal;
            if (dVal < newMin) newMin = dVal;
          }
        } else if (st == SecondaryState.STDDEV) {
          double? val = item.stdDev;
          if (val != null && val.isFinite) {
            if (val > newMax) newMax = val;
            if (val < newMin) newMin = val;
          }
        } else if (st == SecondaryState.ADX) {
          double? adxVal = item.adx;
          if (adxVal != null && adxVal.isFinite) {
            if (adxVal > newMax) newMax = adxVal;
            if (adxVal < newMin) newMin = adxVal;
          }
        } else if (st == SecondaryState.VIX) {
          double? v = item.vix;
          if (v != null && v.isFinite) {
            if (v > newMax) newMax = v;
            if (v < newMin) newMin = v;
          }
        } else if (st == SecondaryState.ADL) {
          double? v = item.adl;
          if (v != null && v.isFinite) {
            if (v > newMax) newMax = v;
            if (v < newMin) newMin = v;
          }
        } else if (st == SecondaryState.OBV) {
          // 这里可纳入obvEma(更平滑) or obv(原始) 作为坐标
          double? val = item.obvEma; // 优先看平滑
          if (val != null && val.isFinite) {
            if (val > newMax) newMax = val;
            if (val < newMin) newMin = val;
          }
        } else if (st == SecondaryState.VWAP) {
          double? v = item.vwap;
          if (v != null && v.isFinite) {
            if (v > newMax) newMax = v;
            if (v < newMin) newMin = v;
          }
        } else if (st == SecondaryState.HV) {
          double? hvVal = item.hv;
          if (hvVal != null && hvVal.isFinite) {
            if (hvVal > newMax) newMax = hvVal;
            if (hvVal < newMin) newMin = hvVal;
          }
        } else if (st == SecondaryState.ATR) {
          double? a = item.atr;
          if (a != null && a.isFinite) {
            if (a > newMax) newMax = a;
            if (a < newMin) newMin = a;
          }
        } else if (st == SecondaryState.VORTEX) {
          // item.viPlus, item.viMinus
          double? viplus = item.viPlus;
          double? viminus = item.viMinus;
          if (viplus != null && viplus.isFinite) {
            if (viplus > newMax) newMax = viplus;
            if (viplus < newMin) newMin = viplus;
          }
          if (viminus != null && viminus.isFinite) {
            if (viminus > newMax) newMax = viminus;
            if (viminus < newMin) newMin = viminus;
          }
        } else if (st == SecondaryState.AROON) {
          // item.aroonUp, item.aroonDown, item.aroonOsc
          double? up = item.aroonUp;
          double? down = item.aroonDown;
          double? osc = item.aroonOsc; // 若calcOsc=true

          // 依次更新
          if (up != null && up.isFinite) {
            if (up > newMax) newMax = up;
            if (up < newMin) newMin = up;
          }
          if (down != null && down.isFinite) {
            if (down > newMax) newMax = down;
            if (down < newMin) newMin = down;
          }
          if (osc != null && osc.isFinite) {
            if (osc > newMax) newMax = osc;
            if (osc < newMin) newMin = osc;
          }
        } else if (st == SecondaryState.SAR) {
          // 只存一条 psar
          final psarVal = item.psar;
          if (psarVal != null && psarVal.isFinite) {
            if (psarVal > newMax) newMax = psarVal;
            if (psarVal < newMin) newMin = psarVal;
          }
        } else if (st == SecondaryState.ICHIMOKU) {
          // 5条线: Tenkan, Kijun, SpanA, SpanB, Chikou
          final lines = [
            item.ichimokuTenkan,
            item.ichimokuKijun,
            item.ichimokuSpanA,
            item.ichimokuSpanB,
            item.ichimokuChikou,
          ];
          for (var val in lines) {
            if (val != null && val.isFinite) {
              if (val > newMax) newMax = val;
              if (val < newMin) newMin = val;
            }
          }
        } else if (st == SecondaryState.TSI) {
          // TSI + 信号线
          if (item.tsi != null && item.tsiSignal != null) {
            if (item.tsi!.isFinite) {
              newMax = newMax > item.tsi! ? newMax : item.tsi!;
              newMin = newMin < item.tsi! ? newMin : item.tsi!;
            }
            if (item.tsiSignal!.isFinite) {
              newMax = newMax > item.tsiSignal! ? newMax : item.tsiSignal!;
              newMin = newMin < item.tsiSignal! ? newMin : item.tsiSignal!;
            }
          }
        } else if (st == SecondaryState.PPO) {
          // 这里给PPO主线 + PPO信号线 做max/min
          if (item.ppo != null && item.ppoSignal != null) {
            double ppoVal = item.ppo!;
            double ppoSig = item.ppoSignal!;
            if (ppoVal.isFinite) {
              newMax = newMax > ppoVal ? newMax : ppoVal;
              newMin = newMin < ppoVal ? newMin : ppoVal;
            }
            if (ppoSig.isFinite) {
              newMax = newMax > ppoSig ? newMax : ppoSig;
              newMin = newMin < ppoSig ? newMin : ppoSig;
            }
          }
        } else if (st == SecondaryState.TRIX) {
          // 和MACD/KDJ类似，获取TRIX和其Signal线的值
          if (item.trix != null && item.trixSignal != null) {
            // 这里只示例主线/信号线各一个
            // 如果你自己还想多画别的线，可以都加进reduce
            newMax = [oldMax, item.trix!, item.trixSignal!]
                .reduce((a, b) => a > b ? a : b);

            newMin = [oldMin, item.trix!, item.trixSignal!]
                .reduce((a, b) => a < b ? a : b);
          }
        } else if (st == SecondaryState.DMI) {
          // pdi, mdi, adx, adxr
          if (item.pdi != null && item.mdi != null && item.adx != null) {
            // 这里假设你还需要adxr，可以一起写，否则省略
            newMax = [
              oldMax,
              item.pdi!,
              item.mdi!,
              item.adx!,
              if (item.adxr != null) item.adxr!
            ].reduce((a, b) => a > b ? a : b);

            newMin = [
              oldMin,
              item.pdi!,
              item.mdi!,
              item.adx!,
              if (item.adxr != null) item.adxr!
            ].reduce((a, b) => a < b ? a : b);
          }
        } else if (st == SecondaryState.MACD) {
          // item.macd, item.dif, item.dea
          if (item.macd != null && item.dif != null && item.dea != null) {
            newMax = [oldMax, item.macd!, item.dif!, item.dea!, item.osma!]
                .reduce((a, b) => a > b ? a : b);
            newMin = [oldMin, item.macd!, item.dif!, item.dea!, item.osma!]
                .reduce((a, b) => a < b ? a : b);
          }
          // double? val = item.osma;
          // if (val != null && val.isFinite) {
          //   if (val > newMax) newMax = val;
          //   if (val < newMin) newMin = val;
          // }
        } else if (st == SecondaryState.KDJ) {
          // item.k, item.d, item.j
          if (item.k != null && item.d != null && item.j != null) {
            newMax = [oldMax, item.k!, item.d!, item.j!]
                .reduce((a, b) => a > b ? a : b);
            newMin = [oldMin, item.k!, item.d!, item.j!]
                .reduce((a, b) => a < b ? a : b);
          }
        } else if (st == SecondaryState.RSI) {
          // item.rsi
          if (item.rsi != null) {
            newMax = newMax > item.rsi! ? newMax : item.rsi!;
            newMin = newMin < item.rsi! ? newMin : item.rsi!;
          }
        } else if (st == SecondaryState.WR) {
          // WR 通常范围 [-100, 0], 也可自行判定
          newMax = newMax > 0 ? newMax : 0;
          newMin = newMin < -100 ? newMin : -100;
        } else if (st == SecondaryState.CCI) {
          if (item.cci != null) {
            newMax = math.max(newMax, item.cci!);
            newMin = math.min(newMin, item.cci!);
          }
        }
        // 回写到 Map
        mSecondaryMaxMap[st] = newMax;
        mSecondaryMinMap[st] = newMin;

        // print('[getSecondaryMaxMinValue] Max: $newMax, Min: $newMin');
      }
    }
  }

  void getMainMaxMinValue(KLineEntity item, int i) {
    double maxPrice, minPrice;
    if (mainState == MainState.MA) {
      maxPrice = math.max(item.high, _findMaxMA(item.maValueList ?? [0]));
      minPrice = math.min(item.low, _findMinMA(item.maValueList ?? [0]));
    } else if (mainState == MainState.BOLL) {
      maxPrice = math.max(item.up ?? 0, item.high);
      minPrice = math.min(item.dn ?? 0, item.low);
    } else {
      maxPrice = item.high;
      minPrice = item.low;
    }
    mMainMaxValue = math.max(mMainMaxValue, maxPrice);
    mMainMinValue = math.min(mMainMinValue, minPrice);

    if (mMainHighMaxValue < item.high) {
      mMainHighMaxValue = item.high;
      mMainMaxIndex = i;
    }
    if (mMainLowMinValue > item.low) {
      mMainLowMinValue = item.low;
      mMainMinIndex = i;
    }

    if (isLine == true) {
      mMainMaxValue = math.max(mMainMaxValue, item.close);
      mMainMinValue = math.min(mMainMinValue, item.close);
    }
  }

  double _findMaxMA(List<double> a) {
    double result = double.minPositive;
    for (double i in a) {
      result = math.max(result, i);
    }
    return result;
  }

  double _findMinMA(List<double> a) {
    double result = double.maxFinite;
    for (double i in a) {
      result = math.min(result, i == 0 ? double.maxFinite : i);
    }
    return result;
  }

  void getVolMaxMinValue(KLineEntity item) {
    mVolMaxValue = math.max(
        mVolMaxValue,
        math.max(
            item.vol, math.max(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
    mVolMinValue = math.min(
        mVolMinValue,
        math.min(
            item.vol, math.min(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
  }

  void getSecondaryMaxMinValue(KLineEntity item) {
    for (var secondaryState in secondaryStates) {
      // print(
      //     'State: $secondaryState, MACD: ${item.macd}, DIF: ${item.dif}, DEA: ${item.dea}');
      // print('Calculating SecondaryState: $secondaryState');
      // print('MACD: ${item.macd}, DIF: ${item.dif}, DEA: ${item.dea}');
      // print('KDJ: K=${item.k}, D=${item.d}, J=${item.j}');
      // print('RSI: ${item.rsi}, WR: ${item.r}, CCI: ${item.cci}');

      double mSecondaryMaxValue = double.minPositive;
      double mSecondaryMinValue = double.maxFinite;

      if (secondaryState == SecondaryState.MACD) {
        if (item.macd != null) {
          mSecondaryMaxValue = math.max(mSecondaryMaxValue,
              math.max(item.macd!, math.max(item.dif!, item.dea!)));
          mSecondaryMinValue = math.min(mSecondaryMinValue,
              math.min(item.macd!, math.min(item.dif!, item.dea!)));
        }
      } else if (secondaryState == SecondaryState.KDJ) {
        if (item.d != null) {
          mSecondaryMaxValue = math.max(mSecondaryMaxValue,
              math.max(item.k!, math.max(item.d!, item.j!)));
          mSecondaryMinValue = math.min(mSecondaryMinValue,
              math.min(item.k!, math.min(item.d!, item.j!)));
        }
      } else if (secondaryState == SecondaryState.RSI) {
        if (item.rsi != null) {
          mSecondaryMaxValue = math.max(mSecondaryMaxValue, item.rsi!);
          mSecondaryMinValue = math.min(mSecondaryMinValue, item.rsi!);
        }
      } else if (secondaryState == SecondaryState.WR) {
        mSecondaryMaxValue = 0;
        mSecondaryMinValue = -100;
      } else if (secondaryState == SecondaryState.CCI) {
        if (item.cci != null) {
          mSecondaryMaxValue = math.max(mSecondaryMaxValue, item.cci!);
          mSecondaryMinValue = math.min(mSecondaryMinValue, item.cci!);
        }
      } else {
        mSecondaryMaxValue = 0;
        mSecondaryMinValue = 0;
      }
      // 添加日志
      // print('[getSecondaryMaxMinValue] State: $secondaryState, '
      //     'Max: $mSecondaryMaxValue, Min: $mSecondaryMinValue');
    }
  }

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  ///二分查找当前值的index
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  ///根据索引索取x坐标
  ///+ mPointWidth / 2防止第一根和最后一根k线显示不���
  ///@param position 索引值
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  KLineEntity getItem(int position) {
    return datas![position];
    // if (datas != null) {
    //   return datas[position];
    // } else {
    //   return null;
    // }
  }

  ///scrollX 转换为 TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  ///获取平移的最小值
  double getMinTranslateX() {
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2;
    return x >= 0 ? 0.0 : x;
  }

  ///计算长按后x的值，转换为index
  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }
    return mSelectedIndex;
  }

  ///translateX转化为view中的x
  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
//    return oldDelegate.datas != datas ||
//        oldDelegate.datas?.length != datas?.length ||
//        oldDelegate.scaleX != scaleX ||
//        oldDelegate.scrollX != scrollX ||
//        oldDelegate.isLongPress != isLongPress ||
//        oldDelegate.selectX != selectX ||
//        oldDelegate.isLine != isLine ||
//        oldDelegate.mainState != mainState ||
//        oldDelegate.secondaryState != secondaryState;
  }
}

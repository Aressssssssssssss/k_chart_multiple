import 'dart:math';

import 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:k_chart_multiple/flutter_k_chart.dart';

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
      mSecondaryMaxMap[st] = double.minPositive;
      mSecondaryMinMap[st] = double.maxFinite;
    }
    initFormats();
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

  // void initRect(Size size) {
  //   double volHeight = volHidden != true ? mDisplayHeight * 0.2 : 0;
  //   // double secondaryHeight = secondaryState != SecondaryState.NONE ? mDisplayHeight * 0.2 : 0;
  //   double secondaryHeight =
  //       secondaryStates.isNotEmpty ? mDisplayHeight * 0.2 : 0;

  //   // double mainHeight = mDisplayHeight;
  //   // mainHeight -= volHeight;
  //   // mainHeight -= secondaryHeight;
  //   double mainHeight =
  //       mDisplayHeight - volHeight - (secondaryHeight * secondaryStates.length);

  //   mMainRect = Rect.fromLTRB(0, mTopPadding, mWidth, mTopPadding + mainHeight);

  //   if (volHidden != true) {
  //     mVolRect = Rect.fromLTRB(0, mMainRect.bottom + mChildPadding, mWidth,
  //         mMainRect.bottom + volHeight);
  //   }

  //   //secondaryState == SecondaryState.NONE隐藏副视图
  //   if (secondaryStates.isNotEmpty) {
  //     mSecondaryRect = Rect.fromLTRB(
  //         0,
  //         mMainRect.bottom + volHeight + mChildPadding,
  //         mWidth,
  //         mMainRect.bottom + volHeight + secondaryHeight);
  //   }

  //   // 添加日志
  //   print('[initRect] Main Rect: $mMainRect');
  //   print('[initRect] Vol Rect: $mVolRect');
  //   print('[initRect] Secondary Rect: $mSecondaryRect');
  // }

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
    print('[initRect] Main Rect: $mMainRect');
    print('[initRect] Vol Rect: $mVolRect');
    print('[initRect] Secondary Rect: $mSecondaryRect');
  }

  void _computeDMI(List<KLineEntity> data, {int period = 14}) {
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

  calculateValue() {
    if (datas == null) return;
    if (datas!.isEmpty) return;

    // 如果用户配置了要显示DMI，则先计算DMI
    if (secondaryStates.contains(SecondaryState.DMI)) {
      _computeDMI(datas!); // period可自定义
    }

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

        if (st == SecondaryState.DMI) {
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
            newMax = [oldMax, item.macd!, item.dif!, item.dea!]
                .reduce((a, b) => a > b ? a : b);
            newMin = [oldMin, item.macd!, item.dif!, item.dea!]
                .reduce((a, b) => a < b ? a : b);
          }
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
            newMax = max(newMax, item.cci!);
            newMin = min(newMin, item.cci!);
          }
        }
        // 回写到 Map
        mSecondaryMaxMap[st] = newMax;
        mSecondaryMinMap[st] = newMin;

        print('[getSecondaryMaxMinValue] Max: $newMax, Min: $newMin');
      }
    }
  }

  void getMainMaxMinValue(KLineEntity item, int i) {
    double maxPrice, minPrice;
    if (mainState == MainState.MA) {
      maxPrice = max(item.high, _findMaxMA(item.maValueList ?? [0]));
      minPrice = min(item.low, _findMinMA(item.maValueList ?? [0]));
    } else if (mainState == MainState.BOLL) {
      maxPrice = max(item.up ?? 0, item.high);
      minPrice = min(item.dn ?? 0, item.low);
    } else {
      maxPrice = item.high;
      minPrice = item.low;
    }
    mMainMaxValue = max(mMainMaxValue, maxPrice);
    mMainMinValue = min(mMainMinValue, minPrice);

    if (mMainHighMaxValue < item.high) {
      mMainHighMaxValue = item.high;
      mMainMaxIndex = i;
    }
    if (mMainLowMinValue > item.low) {
      mMainLowMinValue = item.low;
      mMainMinIndex = i;
    }

    if (isLine == true) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    }
  }

  double _findMaxMA(List<double> a) {
    double result = double.minPositive;
    for (double i in a) {
      result = max(result, i);
    }
    return result;
  }

  double _findMinMA(List<double> a) {
    double result = double.maxFinite;
    for (double i in a) {
      result = min(result, i == 0 ? double.maxFinite : i);
    }
    return result;
  }

  void getVolMaxMinValue(KLineEntity item) {
    mVolMaxValue = max(mVolMaxValue,
        max(item.vol, max(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
    mVolMinValue = min(mVolMinValue,
        min(item.vol, min(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
  }

  void getSecondaryMaxMinValue(KLineEntity item) {
    for (var secondaryState in secondaryStates) {
      print(
          'State: $secondaryState, MACD: ${item.macd}, DIF: ${item.dif}, DEA: ${item.dea}');
      print('Calculating SecondaryState: $secondaryState');
      print('MACD: ${item.macd}, DIF: ${item.dif}, DEA: ${item.dea}');
      print('KDJ: K=${item.k}, D=${item.d}, J=${item.j}');
      print('RSI: ${item.rsi}, WR: ${item.r}, CCI: ${item.cci}');

      double mSecondaryMaxValue = double.minPositive;
      double mSecondaryMinValue = double.maxFinite;

      if (secondaryState == SecondaryState.MACD) {
        if (item.macd != null) {
          mSecondaryMaxValue = max(
              mSecondaryMaxValue, max(item.macd!, max(item.dif!, item.dea!)));
          mSecondaryMinValue = min(
              mSecondaryMinValue, min(item.macd!, min(item.dif!, item.dea!)));
        }
      } else if (secondaryState == SecondaryState.KDJ) {
        if (item.d != null) {
          mSecondaryMaxValue =
              max(mSecondaryMaxValue, max(item.k!, max(item.d!, item.j!)));
          mSecondaryMinValue =
              min(mSecondaryMinValue, min(item.k!, min(item.d!, item.j!)));
        }
      } else if (secondaryState == SecondaryState.RSI) {
        if (item.rsi != null) {
          mSecondaryMaxValue = max(mSecondaryMaxValue, item.rsi!);
          mSecondaryMinValue = min(mSecondaryMinValue, item.rsi!);
        }
      } else if (secondaryState == SecondaryState.WR) {
        mSecondaryMaxValue = 0;
        mSecondaryMinValue = -100;
      } else if (secondaryState == SecondaryState.CCI) {
        if (item.cci != null) {
          mSecondaryMaxValue = max(mSecondaryMaxValue, item.cci!);
          mSecondaryMinValue = min(mSecondaryMinValue, item.cci!);
        }
      } else {
        mSecondaryMaxValue = 0;
        mSecondaryMinValue = 0;
      }
      // 添加日志
      print('[getSecondaryMaxMinValue] State: $secondaryState, '
          'Max: $mSecondaryMaxValue, Min: $mSecondaryMinValue');
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

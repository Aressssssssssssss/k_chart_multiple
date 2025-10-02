import 'dart:async';

import 'package:flutter/material.dart';
import 'package:k_chart_multiple/chart_translations.dart';
import 'package:k_chart_multiple/extension/map_ext.dart';
import 'package:k_chart_multiple/flutter_k_chart.dart';

import 'entity/trade_mark.dart';
import 'entity/up_prob_report.dart';
import 'renderer/trend_line_state.dart';

enum MainState { MA, BOLL, NONE }

extension MainStateJson on MainState {
  /// 将枚举值转换为 JSON（String）表示
  String toJson() {
    // 直接返回枚举名
    return toString().split('.').last;
  }

  /// 从 JSON（String）解析出对应的枚举值
  static MainState fromJson(String json) {
    // 尝试匹配所有 values
    return MainState.values.firstWhere(
      (e) => e.toJson() == json,
      // 如果没有匹配，则返回 NONE 或者抛出异常
      orElse: () => MainState.NONE,
    );
  }
}

enum SecondaryState {
  MACD,
  KDJ,
  RSI,
  WR,
  CCI,
  DMI,
  TRIX,
  PPO,
  TSI,
  ICHIMOKU,
  SAR,
  AROON,
  VORTEX,
  ATR,
  HV,
  VWAP,
  OBV,
  ADL,
  VIX,
  ADX,
  STDDEV,
  STOCHASTIC,
  WPR,
  DEMARKER,
  MOMENTUM,
  MFI,
  ENVELOPES,
  VOLATILITY,
  CMF,
  CHAIKIN_OSC,
  KLINGER,
  VPT,
  FORCE,
  ROC,
  ULTIMATE,
  CONNORS_RSI,
  STOCH_RSI,
  RVI,
  DPO,
  KAMA,
  HMA,
  KELTNER,
  DONCHIAN,
  BOLL_BANDWIDTH,
  CHAIKIN_VOLATILITY,
  HV_PERCENTILE,
  ATR_PERCENTILE,
  ELDER_RAY,
  ICHIMOKU_SPAN,
  PIVOT,
  GANN_FAN,
  NONE
}

extension SecondaryStateJson on SecondaryState {
  /// 将枚举值转换为 JSON（String）表示
  String toJson() {
    // 直接返回枚举名
    return toString().split('.').last;
  }

  /// 从 JSON（String）解析出对应的枚举值
  static SecondaryState fromJson(String json) {
    // 尝试匹配所有 values
    return SecondaryState.values.firstWhere(
      (e) => e.toJson() == json,
      // 如果没有匹配，则返回 NONE 或者抛出异常
      orElse: () => SecondaryState.NONE,
    );
  }
}

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final MainState mainState;
  final bool volHidden;
  final bool isShowMainState;
  final List<SecondaryState> secondaryStates;
  final Function(int)? onSecondaryTap;
  final bool isLine;
  final bool isTapShowInfoDialog; //是否开启单击显示详情数据
  final bool hideGrid;
  @Deprecated('Use `translations` instead.')
  final bool isChinese;
  final bool showNowPrice;
  final bool showInfoDialog;
  final bool materialInfoDialog; // Material风格的信息弹窗
  final Map<String, ChartTranslations> translations;
  final List<String> timeFormat;

  //当屏幕滚动到尽头会调用，真为拉到屏幕右侧尽头，假为拉到屏幕左侧尽头
  final Function(bool)? onLoadMore;

  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final VerticalTextAlignment verticalTextAlignment;
  final bool isTrendLine;

  final double? mainHeight; // 新增参数：主图高度
  final double? secondaryHeight; // 新增参数：次图高度

  // 副图回调
  final void Function(double probability)? onGoingUp;
  final void Function(double probability)? onGoingDown;

  // 主图回调
  final void Function(double probability)? onMainGoingUp;
  final void Function(double probability)? onMainGoingDown;

  final void Function(UpProbReport report)? onUpProbs;

  final List<TradeMark> tradeMarks;
  final bool showTradeMarks;

  KChartWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    required this.isTrendLine,
    this.mainState = MainState.MA,
    this.isShowMainState = true,
    this.secondaryStates = const [SecondaryState.MACD],
    this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.isTapShowInfoDialog = false,
    this.hideGrid = false,
    @Deprecated('Use `translations` instead.') this.isChinese = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.materialInfoDialog = true,
    this.translations = kChartTranslations,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.left,
    this.mainHeight,
    this.secondaryHeight,
    this.onGoingUp, // ★ 仅副图
    this.onGoingDown, // ★ 仅副图
    this.onMainGoingUp, // ★ 仅主图
    this.onMainGoingDown, // ★ 仅主图
    this.onUpProbs,
    this.tradeMarks = const [],
    this.showTradeMarks = true,
  });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  StreamController<InfoWindowEntity?>? mInfoWindowStream;
  double mHeight = 0, mWidth = 0;
  AnimationController? _controller;
  Animation<double>? aniX;

  //For TrendLine
  List<TrendLine> lines = [];
  double? changeinXposition;
  double? changeinYposition;
  double mSelectY = 0.0;
  bool waitingForOtherPairofCords = false;
  bool enableCordRecord = false;
  int _lastDataLength = 0;
  int? _lastDataTailTime;
  final TrendLineState _trendLineState = TrendLineState();
  static const Offset _pendingTrendLineEnd = Offset(-1, -1);

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  @override
  void initState() {
    super.initState();
    mInfoWindowStream = StreamController<InfoWindowEntity?>();
    _captureDataSignature(widget.datas);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant KChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDatas = widget.datas;
    final oldDatas = oldWidget.datas;
    final newLength = newDatas?.length ?? 0;
    final newTailTime =
        (newDatas != null && newDatas.isNotEmpty) ? newDatas.last.time : null;
    final dataChanged = !identical(newDatas, oldDatas) ||
        newLength != _lastDataLength ||
        newTailTime != _lastDataTailTime;
    if (dataChanged) {
      _resetTrendLineState();
    }
    _captureDataSignature(newDatas);
  }

  @override
  void dispose() {
    mInfoWindowStream?.close();
    _controller?.dispose();
    _resetTrendLineState(clearAllLines: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }
    final _painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      lines: lines, //For TrendLine
      isTrendLine: widget.isTrendLine, //For TrendLine
      selectY: mSelectY, //For TrendLine
      trendLineState: _trendLineState,
      datas: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass: isLongPress,
      isOnTap: isOnTap,
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainState: widget.mainState,
      volHidden: widget.volHidden,
      isShowMainState: widget.isShowMainState,
      secondaryStates: widget.secondaryStates,
      mainHeight: widget.mainHeight,
      secondaryHeight: widget.secondaryHeight,
      isLine: widget.isLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      sink: mInfoWindowStream?.sink,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
      onGoingUp: widget.onGoingUp,
      onGoingDown: widget.onGoingDown,
      onMainGoingUp: widget.onMainGoingUp,
      onMainGoingDown: widget.onMainGoingDown,
      onUpProbs: widget.onUpProbs,
      tradeMarks: widget.tradeMarks,
      showTradeMarks: widget.showTradeMarks,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;

        return GestureDetector(
          onTapUp: (details) {
            final localPosition = details.localPosition;
            if (widget.onSecondaryTap != null) {
              final index = _painter.secondaryIndexAt(localPosition);
              if (index != null) {
                widget.onSecondaryTap!(index);
              }
            }

            if (!widget.isTrendLine && _painter.isInMainRect(localPosition)) {
              isOnTap = true;
              final tappedX = _clampSelectX(localPosition.dx);
              final tappedY = _clampSelectY(localPosition.dy);
              if (widget.isTapShowInfoDialog &&
                  (mSelectX != tappedX || mSelectY != tappedY)) {
                mSelectX = tappedX;
                mSelectY = tappedY;
                notifyChanged();
              }
            }
            if (widget.isTrendLine && !isLongPress && enableCordRecord) {
              enableCordRecord = false;
              final clampedY = _clampSelectY(mSelectY);
              final trendState = _trendLineState;
              if (trendState.hasMetrics) {
                final Offset p1 = Offset(trendState.currentX, clampedY);
                final trendMax = trendState.maxValue!;
                final trendScale = trendState.scale!;
                if (!waitingForOtherPairofCords) {
                  lines.add(TrendLine(
                      p1, _pendingTrendLineEnd, trendMax, trendScale));
                }

                if (waitingForOtherPairofCords) {
                  var a = lines.last;
                  lines.removeLast();
                  lines.add(TrendLine(a.p1, p1, trendMax, trendScale));
                  waitingForOtherPairofCords = false;
                } else {
                  waitingForOtherPairofCords = true;
                }
              }
              notifyChanged();
            }
          },
          onHorizontalDragDown: (details) {
            isOnTap = false;
            _stopAnimation();

            _onDragChanged(true);
          },
          onHorizontalDragUpdate: (details) {
            if (isScale || isLongPress) return;
            mScrollX = ((details.primaryDelta ?? 0) / mScaleX + mScrollX)
                .clamp(0.0, ChartPainter.maxScrollX)
                .toDouble();
            notifyChanged();
          },
          onHorizontalDragEnd: (DragEndDetails details) {
            var velocity = details.velocity.pixelsPerSecond.dx;
            _onFling(velocity);
          },
          onHorizontalDragCancel: () => _onDragChanged(false),
          onScaleStart: (_) {
            isScale = true;
          },
          onScaleUpdate: (details) {
            if (isDrag || isLongPress) return;

            // double newScaleX = (mScaleX * details.scale).clamp(0.5, 2.0);
            // widget.scaleNotifier.value = newScaleX; // 更新全局缩放值

            mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
            notifyChanged();
          },
          onScaleEnd: (_) {
            isScale = false;
            _lastScale = mScaleX;
          },
          onLongPressStart: (details) {
            isOnTap = false;
            isLongPress = true;
            final localPosition = details.localPosition;
            if (widget.isTrendLine) {
              final clampedX = _clampSelectX(localPosition.dx);
              final clampedY = _clampSelectY(localPosition.dy);
              if (changeinXposition == null) {
                mSelectX = clampedX;
                mSelectY = clampedY;
              }
              changeinXposition = clampedX;
              changeinYposition = clampedY;
              notifyChanged();
            } else {
              final newX = _clampSelectX(localPosition.dx);
              final newY = _clampSelectY(localPosition.dy);
              if (mSelectX != newX || mSelectY != newY) {
                mSelectX = newX;
                mSelectY = newY;
                notifyChanged();
              }
            }
          },
          onLongPressMoveUpdate: (details) {
            final localPosition = details.localPosition;
            if (!widget.isTrendLine) {
              final newX = _clampSelectX(localPosition.dx);
              final newY = _clampSelectY(localPosition.dy);
              if (mSelectX != newX || mSelectY != newY) {
                mSelectX = newX;
                mSelectY = newY;
                notifyChanged();
              }
            } else if (changeinXposition != null && changeinYposition != null) {
              final deltaX = localPosition.dx - changeinXposition!;
              final deltaY = localPosition.dy - changeinYposition!;
              mSelectX = _clampSelectX(mSelectX + deltaX);
              mSelectY = _clampSelectY(mSelectY + deltaY);
              changeinXposition = _clampSelectX(localPosition.dx);
              changeinYposition = _clampSelectY(localPosition.dy);
              notifyChanged();
            }
          },
          onLongPressEnd: (details) {
            isLongPress = false;
            enableCordRecord = true;
            mInfoWindowStream?.sink.add(null);
            notifyChanged();
          },
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: Size(double.infinity, double.infinity),
                painter: _painter,
              ),
              if (widget.showInfoDialog) _buildInfoDialog()
            ],
          ),
        );
      },
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller?.dispose();
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.flingTime), vsync: this);
    aniX = null;
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX)
        .animate(CurvedAnimation(
            parent: _controller!.view, curve: widget.flingCurve));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _captureDataSignature(List<KLineEntity>? datas) {
    _lastDataLength = datas?.length ?? 0;
    _lastDataTailTime =
        (datas != null && datas.isNotEmpty) ? datas.last.time : null;
  }

  void _resetTrendLineState({bool clearAllLines = false}) {
    _trendLineState.reset();
    changeinXposition = null;
    changeinYposition = null;
    waitingForOtherPairofCords = false;
    enableCordRecord = false;
    if (lines.isEmpty) return;
    if (clearAllLines) {
      lines.clear();
    } else {
      _clearPendingTrendLines();
    }
  }

  void _clearPendingTrendLines() {
    lines.removeWhere((line) => line.p2 == _pendingTrendLineEnd);
  }

  double _clampSelectX(double value) {
    if (mWidth <= 0) return value;
    if (value < 0.0) return 0.0;
    if (value > mWidth) return mWidth;
    return value;
  }

  double _clampSelectY(double value) {
    if (mHeight <= 0) return value;
    if (value < 0.0) return 0.0;
    if (value > mHeight) return mHeight;
    return value;
  }

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
        stream: mInfoWindowStream?.stream,
        builder: (context, snapshot) {
          if ((!isLongPress && !isOnTap) ||
              widget.isLine == true ||
              !snapshot.hasData ||
              snapshot.data?.kLineEntity == null) return Container();
          KLineEntity entity = snapshot.data!.kLineEntity;
          double upDown = entity.change ?? entity.close - entity.open;
          double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
          final double? entityAmount = entity.amount;
          final infos = [
            getDate(entity.time),
            entity.open.toStringAsFixed(widget.fixedLength),
            entity.high.toStringAsFixed(widget.fixedLength),
            entity.low.toStringAsFixed(widget.fixedLength),
            entity.close.toStringAsFixed(widget.fixedLength),
            "${upDown > 0 ? "+" : ""}${upDown.toStringAsFixed(widget.fixedLength)}",
            "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
            if (entityAmount != null) entityAmount.toInt().toString()
          ];
          final dialogPadding = 4.0;
          final dialogWidth = mWidth / 3;
          // ignore: deprecated_member_use_from_same_package
          final translations = widget.isChinese
              ? kChartTranslations['zh_CN']!
              : widget.translations.of(context);
          return Container(
            margin: EdgeInsets.only(
                left: snapshot.data!.isLeft
                    ? dialogPadding
                    : mWidth - dialogWidth - dialogPadding,
                top: 25),
            width: dialogWidth,
            decoration: BoxDecoration(
                color: widget.chartColors.selectFillColor,
                border: Border.all(
                    color: widget.chartColors.selectBorderColor, width: 0.5)),
            child: ListView.builder(
              padding: EdgeInsets.all(dialogPadding),
              itemCount: infos.length,
              itemExtent: 14.0,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return _buildItem(
                  infos[index],
                  translations.byIndex(index),
                );
              },
            ),
          );
        });
  }

  Widget _buildItem(String info, String infoName) {
    Color color = widget.chartColors.infoWindowNormalColor;
    if (info.startsWith("+"))
      color = widget.chartColors.infoWindowUpColor;
    else if (info.startsWith("-")) color = widget.chartColors.infoWindowDnColor;
    final infoWidget = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
            child: Text("$infoName",
                style: TextStyle(
                    color: widget.chartColors.infoWindowTitleColor,
                    fontSize: 10.0))),
        Text(info, style: TextStyle(color: color, fontSize: 10.0)),
      ],
    );
    return widget.materialInfoDialog
        ? Material(color: Colors.transparent, child: infoWidget)
        : infoWidget;
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      widget.timeFormat);
}

# k_chart_multiple

Flutter K 线图组件，支持在单个界面中实例化多个行情图，并提供完整的指标体系、交易标记与回调能力，帮助你快速构建专业的行情/量化分析页面。

## 功能亮点
- 同屏管理多个 `KChartWidget`，支持自定义宽高和滚动行为
- 内置主图指标（MA/BOLL）与 20+ 个副图指标，可通过 `List<SecondaryState>` 自由组合
- 支持蜡烛图、分时线、趋势线绘制以及成交量、深度图
- 提供 `ChartStyle`/`ChartColors`、多语言、时间格式等多维度外观配置
- 额外的概率评估、交易标记 (`TradeMark`) 与信号回调，便于量化策略联动
- 自带示例项目与本地数据，开箱即可运行

## 快速开始
1. **添加依赖**
   ```yaml
   dependencies:
     k_chart_multiple: ^1.1.0
   ```

2. **导入库**
   ```dart
   import 'package:k_chart_multiple/flutter_k_chart.dart';
   ```

3. **准备数据**
   ```dart
   final raw = await rootBundle.loadString('assets/chatData.json');
   final List<dynamic> list = json.decode(raw)['data'];
   final datas = list
       .map((e) => KLineEntity.fromJson(e as Map<String, dynamic>))
       .toList()
       .reversed
       .toList();
   DataUtil.calculate(datas); // 必须：计算均线、指标、概率等
   ```

4. **渲染单个 K 线图**
   ```dart
   final chart = KChartWidget(
     datas,
     ChartStyle(),
     ChartColors(),
     isTrendLine: false,
     mainState: MainState.MA,
     secondaryStates: const [SecondaryState.MACD, SecondaryState.RSI],
     volHidden: false,
     showNowPrice: true,
     timeFormat: TimeFormat.YEAR_MONTH_DAY_WITH_HOUR,
     translations: kChartTranslations,
     onLoadMore: (isRightEdge) {
       if (isRightEdge) fetchMore();
     },
   );
   ```

## 同屏展示多个 K 线图
`KChartWidget` 是普通的 Flutter 组件，可像其他 Widget 一样放在 `ListView`、`GridView` 或 `TabBarView` 中。下面示例演示如何在同一页面创建多个指标组合：

```dart
class MultipleCharts extends StatelessWidget {
  final List<List<SecondaryState>> secondaryCombos;
  final List<KLineEntity> source;

  MultipleCharts({
    super.key,
    required this.secondaryCombos,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: secondaryCombos.length,
      itemBuilder: (_, index) {
        return Card(
          color: Colors.black,
          child: KChartWidget(
            source,
            ChartStyle()
              ..childPadding = 8,
            ChartColors(),
            isTrendLine: false,
            mainState: MainState.MA,
            secondaryStates: secondaryCombos[index],
            volHidden: index.isEven,
            showNowPrice: true,
            fixedLength: 2,
            timeFormat: TimeFormat.YEAR_MONTH_DAY,
            mainHeight: 260,
            secondaryHeight: 90,
            onSecondaryTap: (i) {
              debugPrint('Tapped secondary chart $i of card $index');
            },
          ),
        );
      },
    );
  }
}
```

提示：
- 共享同一份 `datas` 时，多个图表会拥有一致的缩放与计算结果；如需独立数据，只需传入不同的 `List<KLineEntity>`。
- 可结合 `ValueNotifier`/`Provider` 等状态管理方案，控制指标组合、主题或数据刷新。

## 常用配置总览
- **主图模式**：`mainState` 支持 `MainState.MA`、`MainState.BOLL`、`MainState.NONE`
- **副图指标**：`SecondaryState` 提供 MACD、KDJ、RSI、SAR、ATR、VWAP、等 20+ 指标；将需要的指标放入 `List` 即可一次展示多个副图
- **线图模式**：`isLine = true` 切换为分时折线；`isTrendLine = true` 开启趋势线绘制
- **成交量/栅格**：通过 `volHidden`、`hideGrid` 控制是否显示
- **外观**：调整 `ChartStyle`（点宽、间距、网格、内边距）与 `ChartColors`（K 线多空颜色、指标颜色、背景等）
- **布局高度**：`mainHeight`、`secondaryHeight` 控制主副图区域；未设置时自动按比例分配
- **国际化与时间**：`translations` 设置信息窗文案，`timeFormat` 控制底部时间格式，示例内置 `kChartTranslations`
- **加载与交互**：
  - `onLoadMore(bool isRightEdge)`：滑动至边缘时触发，适合懒加载
  - `isOnDrag`、`onSecondaryTap`：监听拖拽状态与副图区点击
  - `isTapShowInfoDialog`、`showInfoDialog`、`materialInfoDialog` 控制信息窗行为

## 指标一览与说明
### 主图指标
- **MA（Moving Average）**：多周期移动平均线，用于平滑价格、观测趋势方向。
- **BOLL（Bollinger Bands）**：标准差通道，通过上下轨道衡量价格波动范围，捕捉突破与回归机会。
- **NONE**：不在主图叠加任何指标，仅显示蜡烛或折线图。

### 副图指标
- **MACD（Moving Average Convergence Divergence）**：由 DIF、DEA 与柱状图组成，识别趋势、动能与背离。
- **KDJ（Stochastic Oscillator）**：通过 %K/%D/%J 反映超买超卖，常用于区间震荡行情。
- **RSI（Relative Strength Index）**：衡量涨跌动量强度，常用阈值 30/70 判断反转。
- **WR（Williams %R）**：基于最近区间高低点的动量指标，定位超买/超卖位置。
- **CCI（Commodity Channel Index）**：检测价格偏离均值程度，辅助震荡与趋势行情的入场判断。
- **DMI（Directional Movement Index）**：包含 +DI/-DI/ADX/ADXR，衡量趋势方向与强度。
- **TRIX（三重指数平滑均线）**：去趋势后的动量指标，同时提供信号线确认。
- **PPO（Percentage Price Oscillator）**：相对型 MACD，消除不同标的价格级别差异。
- **TSI（True Strength Index）**：双重平滑动量指标，强调趋势内的回调力度。
- **ICHIMOKU（一目均衡表）**：包含转折/基准/领先/延迟线与云图，提供趋势、支撑阻力与时间窗。
- **SAR（Parabolic SAR）**：抛物线反转指标，提供潜在止盈/反转位置。
- **AROON**：上升/下降线与振荡器，测量距离近期极值的时间，判定趋势切换。
- **VORTEX**：VI+/VI- 强调多空力量的转移。
- **ATR（Average True Range）**：真实波动区间，衡量绝对波动程度，常用作止损。
- **HV（Historical Volatility）**：基于对数收益的年化历史波动率。
- **VWAP（Volume Weighted Average Price）**：成交量加权平均价，衡量日内公平价格。
- **OBV（On Balance Volume）**：价格与成交量耦合的量能指标，含平滑版本。
- **ADL（Accumulation/Distribution Line）**：资金流向估计，结合价量判断吸筹派发。
- **VIX（Local Volatility Proxy）**：基于价格数据的波动率 proxy，辅助衡量市场恐慌程度。
- **ADX（Average Directional Index）**：DMI 的趋势强度分量，可单独作为副图使用。
- **STDDEV（Standard Deviation）**：统计型波动衡量，常配合均值策略使用。
- **STOCHASTIC（Slow Stoch）**：平滑 K/D 线，过滤原始随机指标噪声。
- **WPR（Williams %R）**：威廉指标的经典实现，聚焦短期反转。
- **DEMARKER**：比较当前高低点与前期极值，评估潜在枯竭与反转。
- **MOMENTUM**：简单差分动量，直接衡量价格变化速率。
- **MFI（Money Flow Index）**：结合价量的 RSI 变体，突出资金流入流出。
- **ENVELOPES**：移动平均包络线，用上下百分比带追踪趋势。
- **VOLATILITY（ATR / Close）**：ATR 相对化的波动率指标，衡量波动占比。
- **CMF（Chaikin Money Flow）**：基于价量的资金流量，评估买盘/卖盘压力。
- **CHAIKIN_OSC（Chaikin Oscillator）**：ADL 快慢双均线差值，捕捉动量拐点。
- **KLINGER（Klinger Volume Oscillator）**：对成交量趋势进行 EMA 拟合，并提供信号线。
- **VPT（Volume Price Trend）**：累积量价趋势，衡量成交量对价格的推动方向。
- **FORCE（Force Index）**：当日涨跌幅与成交量的乘积，衡量多空能量冲击。
- **ROC（Rate of Change）**：百分比变动率，再配以信号线平滑。
- **ULTIMATE（Ultimate Oscillator）**：多周期买力指标，兼顾短、中、长周期动能。
- **CONNORS_RSI**：价格 RSI、连续涨跌次数与百分位构成的综合动量评分。
- **STOCH_RSI**：对 RSI 进行二次随机化，适合捕捉 RSI 内部节奏。
- **RVI（Relative Vigor Index）**：对开高低收做加权，衡量上涨活力并附带信号线。
- **DPO（Detrended Price Oscillator）**：去除长期趋势的振荡器，突出周期性波动。
- **KAMA（Kaufman Adaptive MA）**：自适应移动平均，依据效率比动态调整平滑。
- **HMA（Hull Moving Average）**：加权均线的高阶平滑版本，响应更快。
- **KELTNER（Keltner Channel）**：EMA 中轨 + ATR 通道，趋势跟随与突破过滤常用。
- **DONCHIAN（Donchian Channel）**：过去 N 日高低通道，经典海龟策略指标。
- **BOLL_BANDWIDTH**：布林上下轨宽度相对值，用于识别高/低波动段。
- **CHAIKIN_VOLATILITY**：基于高低价的波动率变化率，关注波动扩张/收缩。
- **HV_PERCENTILE**：历史波动率在观察窗口内的百分位，评估当前波动所处区间。
- **ATR_PERCENTILE**：ATR 在滚动样本内的百分位，更直观地比较绝对波动水平。
- **ELDER_RAY**：多空力量指标，Bull/Bear Power 与 EMA 结合判断趋势。
- **ICHIMOKU_SPAN Δ**：SpanA-SpanB 差值，刻画云层厚度与趋势强弱。
- **PIVOT**：传统枢轴点与多级支撑阻力，适合日内框架。
- **GANN_FAN**：归一化的江恩扇形比例线，辅助角度和时间分析。

## 交易标记与概率回调
- 使用 `TradeMark` 将策略事件渲染在主图上：
  ```dart
  final trades = [
    TradeMark(index: 50, price: 26800, side: TradeSide.long, action: TradeAction.entry, label: 'Entry'),
    TradeMark(index: 120, price: 28400, side: TradeSide.long, action: TradeAction.tp, label: 'TP1'),
  ];

  KChartWidget(
    datas,
    ChartStyle(),
    ChartColors(),
    isTrendLine: false,
    tradeMarks: trades,
    showTradeMarks: true,
    onGoingUp: (prob) => debugPrint('Secondary chart up probability: $prob'),
    onMainGoingUp: (prob) => debugPrint('Main chart up probability: $prob'),
    onUpProbs: (report) => debugPrint(report.toString()),
  );
  ```
- `DataUtil.calculate` 会在 `KLineEntity.probability` 中写入综合概率，同时驱动 `onGoingUp` / `onGoingDown` / `onUpProbs` 等回调，便于与信号提供器或交易逻辑联动。

## 与信号提供器联动
`lib/provider` 目录包含针对各类指标的信号计算器（如 `macd_signal_provider.dart`、`sar_signal_provider.dart` 等）。你可以：
1. 结合自己的行情源更新 `KLineEntity`
2. 调用对应的 Provider 计算买卖点/信号
3. 配合 `TradeMark` 或自定义 UI 进行提醒

## 示例项目
- `example/lib/main.dart` 展示了完整的页面搭建、按钮控制指标、趋势线模式切换、深度图等能力。
- 运行示例：
  ```bash
  flutter pub get
  cd example
  flutter run
  ```

## 常见问题
- **画面没有指标数据**：确认在渲染前调用 `DataUtil.calculate(list)`。
- **时间轴不正确**：`KLineEntity.time` 以毫秒时间戳为准，若只获取秒级需要自行乘以 1000。
- **需要更多语言**：扩展 `translations`，或提供自定义 `ChartTranslations` 实例。

欢迎提交 Issue 或 Pull Request 升级指标与样式配置。

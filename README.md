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

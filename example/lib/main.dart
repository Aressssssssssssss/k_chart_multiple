import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:k_chart_multiple/chart_translations.dart';
import 'package:k_chart_multiple/flutter_k_chart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const List<Locale> _localeCycle = <Locale>[
    Locale('en', 'US'),
    Locale('zh', 'CN'),
    Locale('es', 'ES'),
    Locale('ja', 'JP'),
  ];

  Locale _locale = _localeCycle.first;

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      locale: _locale,
      supportedLocales: _localeCycle,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        locale: _locale,
        locales: _localeCycle,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key,
      required this.title,
      required this.locale,
      required this.locales,
      required this.onLocaleChanged});

  final String title;
  final Locale locale;
  final List<Locale> locales;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<KLineEntity>? datas;
  bool showLoading = true;
  MainState _mainState = MainState.MA;
  bool _volHidden = false;
  final List<SecondaryState> _secondaryStates = const [
    SecondaryState.KDJ,
    SecondaryState.CMF,
    SecondaryState.CHAIKIN_OSC,
    SecondaryState.KLINGER,
  ].toList();
  bool isLine = false;
  bool _hideGrid = false;
  bool _showNowPrice = true;
  List<DepthEntity>? _bids, _asks;
  bool isChangeUI = false;
  bool _isTrendLine = false;
  bool _priceLeft = true;
  VerticalTextAlignment _verticalTextAlignment = VerticalTextAlignment.left;

  ChartStyle chartStyle = ChartStyle();
  ChartColors chartColors = ChartColors();

  static const Map<String, ChartTranslations> _translations = {
    'en_US': ChartTranslations(),
    ...kChartTranslations,
  };

  static const List<SecondaryState> _newIndicatorStates = [
    SecondaryState.CMF,
    SecondaryState.CHAIKIN_OSC,
    SecondaryState.KLINGER,
    SecondaryState.VPT,
    SecondaryState.FORCE,
    SecondaryState.ROC,
    SecondaryState.ULTIMATE,
    SecondaryState.CONNORS_RSI,
    SecondaryState.STOCH_RSI,
    SecondaryState.RVI,
    SecondaryState.DPO,
    SecondaryState.KAMA,
    SecondaryState.HMA,
    SecondaryState.KELTNER,
    SecondaryState.DONCHIAN,
    SecondaryState.BOLL_BANDWIDTH,
    SecondaryState.CHAIKIN_VOLATILITY,
    SecondaryState.HV_PERCENTILE,
    SecondaryState.ATR_PERCENTILE,
    SecondaryState.ELDER_RAY,
    SecondaryState.ICHIMOKU_SPAN,
    SecondaryState.PIVOT,
    SecondaryState.GANN_FAN,
  ];

  static const Map<SecondaryState, Map<String, String>>
      _secondaryStateDisplayNames = {
    SecondaryState.CMF: {
      'en': 'Chaikin Money Flow',
      'zh': '资金流量(CMF)',
    },
    SecondaryState.CHAIKIN_OSC: {
      'en': 'Chaikin Oscillator',
      'zh': 'Chaikin 振荡',
    },
    SecondaryState.KLINGER: {
      'en': 'Klinger Volume Osc.',
      'zh': 'Klinger 量振荡',
    },
    SecondaryState.VPT: {
      'en': 'Volume Price Trend',
      'zh': '量价趋势(VPT)',
    },
    SecondaryState.FORCE: {
      'en': 'Force Index',
      'zh': '能量指标',
    },
    SecondaryState.ROC: {
      'en': 'Rate of Change',
      'zh': '变动率(ROC)',
    },
    SecondaryState.ULTIMATE: {
      'en': 'Ultimate Oscillator',
      'zh': '终极振荡',
    },
    SecondaryState.CONNORS_RSI: {
      'en': 'Connors RSI',
      'zh': 'Connors RSI',
    },
    SecondaryState.STOCH_RSI: {
      'en': 'Stochastic RSI',
      'zh': '随机RSI',
    },
    SecondaryState.RVI: {
      'en': 'Relative Vigor Index',
      'zh': '相对活力指数(RVI)',
    },
    SecondaryState.DPO: {
      'en': 'Detrended Price Osc.',
      'zh': '去趋势振荡(DPO)',
    },
    SecondaryState.KAMA: {
      'en': 'Kaufman Adaptive MA',
      'zh': '卡夫曼自适应MA',
    },
    SecondaryState.HMA: {
      'en': 'Hull Moving Avg.',
      'zh': '赫尔均线(HMA)',
    },
    SecondaryState.KELTNER: {
      'en': 'Keltner Channel',
      'zh': '肯特纳通道',
    },
    SecondaryState.DONCHIAN: {
      'en': 'Donchian Channel',
      'zh': '唐奇安通道',
    },
    SecondaryState.BOLL_BANDWIDTH: {
      'en': 'Bollinger Bandwidth',
      'zh': '布林带宽度',
    },
    SecondaryState.CHAIKIN_VOLATILITY: {
      'en': 'Chaikin Volatility',
      'zh': 'Chaikin 波动',
    },
    SecondaryState.HV_PERCENTILE: {
      'en': 'HV Percentile',
      'zh': '历史波动百分位',
    },
    SecondaryState.ATR_PERCENTILE: {
      'en': 'ATR Percentile',
      'zh': 'ATR 百分位',
    },
    SecondaryState.ELDER_RAY: {
      'en': 'Elder Ray',
      'zh': '艾尔德射线',
    },
    SecondaryState.ICHIMOKU_SPAN: {
      'en': 'Ichimoku Span Δ',
      'zh': '一目云差值',
    },
    SecondaryState.PIVOT: {
      'en': 'Pivot Levels',
      'zh': '枢轴点',
    },
    SecondaryState.GANN_FAN: {
      'en': 'Gann Fan',
      'zh': '江恩扇形',
    },
  };

  @override
  void initState() {
    super.initState();
    getData();
    rootBundle.loadString('assets/depth.json').then((result) {
      final parseJson = json.decode(result);
      final tick = parseJson['tick'] as Map<String, dynamic>;
      final List<DepthEntity> bids = (tick['bids'] as List<dynamic>)
          .map<DepthEntity>(
              (item) => DepthEntity(item[0] as double, item[1] as double))
          .toList();
      final List<DepthEntity> asks = (tick['asks'] as List<dynamic>)
          .map<DepthEntity>(
              (item) => DepthEntity(item[0] as double, item[1] as double))
          .toList();
      initDepth(bids, asks);
    });
  }

  void initDepth(List<DepthEntity>? bids, List<DepthEntity>? asks) {
    if (bids == null || asks == null || bids.isEmpty || asks.isEmpty) return;

    final processedBids = <DepthEntity>[];
    final processedAsks = <DepthEntity>[];

    double amount = 0.0;
    final sortedBids = [...bids]
      ..sort((left, right) => left.price.compareTo(right.price));
    // 累加买入委托量
    for (final item in sortedBids.reversed) {
      amount += item.vol;
      processedBids.insert(0, DepthEntity(item.price, amount));
    }

    amount = 0.0;
    final sortedAsks = [...asks]
      ..sort((left, right) => left.price.compareTo(right.price));
    // 累加卖出委托量
    for (final item in sortedAsks) {
      amount += item.vol;
      processedAsks.add(DepthEntity(item.price, amount));
    }

    if (!mounted) return;
    setState(() {
      _bids = processedBids;
      _asks = processedAsks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeTag =
        '${widget.locale.languageCode}_${widget.locale.countryCode}';
    final double chartHeight =
        400 + 80 + 10 + _secondaryStates.length * (80 + 13);

    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _localizedLabel('Language', '语言', localeTag),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: widget.locale,
                    isDense: true,
                    onChanged: (Locale? value) {
                      if (value != null) {
                        widget.onLocaleChanged(value);
                      }
                    },
                    items: widget.locales
                        .map(
                          (locale) => DropdownMenuItem<Locale>(
                            value: locale,
                            child: Text(_localeDisplayName(locale)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Stack(children: <Widget>[
          SizedBox(
            height: chartHeight,
            width: double.infinity,
            child: KChartWidget(
              datas,
              chartStyle,
              chartColors,
              isLine: isLine,
              isTrendLine: _isTrendLine,
              mainState: _mainState,
              volHidden: _volHidden,
              secondaryStates: _secondaryStates,
              fixedLength: 2,
              timeFormat: TimeFormat.YEAR_MONTH_DAY,
              translations: _translations,
              showNowPrice: _showNowPrice,
              hideGrid: _hideGrid,
              isTapShowInfoDialog: false,
              verticalTextAlignment: _verticalTextAlignment,
              maDayList: const [1, 100, 1000],
              mainHeight: 400,
              secondaryHeight: 80,
              onUpProbs: (report) {
                debugPrint('The comprehensive possibility is $report');
              },
              onGoingUp: (probability) {
                debugPrint('Secondary chart rising probability: $probability');
              },
              onGoingDown: (probability) {
                debugPrint('Secondary chart falling probability: $probability');
              },
              onMainGoingUp: (probability) {
                debugPrint('Main chart rising probability: $probability');
              },
              onMainGoingDown: (probability) {
                debugPrint('Main chart falling probability: $probability');
              },
            ),
          ),
          if (showLoading)
            const SizedBox(
              width: double.infinity,
              height: 450,
              child: Center(child: CircularProgressIndicator()),
            ),
        ]),
        buildButtons(localeTag),
        if (_bids != null && _asks != null)
          SizedBox(
            height: 230,
            width: double.infinity,
            child: DepthChart(_bids!, _asks!, chartColors),
          )
      ],
    );
  }

  Widget buildButtons(String localeTag) {
    final Set<SecondaryState> newIndicatorSet = _newIndicatorStates.toSet();
    final List<SecondaryState> classicIndicators = SecondaryState.values
        .where((state) =>
            state != SecondaryState.NONE && !newIndicatorSet.contains(state))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: <Widget>[
            button(_localizedLabel('Time Mode', '分时', localeTag),
                selected: isLine, onPressed: () => isLine = true),
            button(_localizedLabel('K Line Mode', 'K线模式', localeTag),
                selected: !isLine, onPressed: () => isLine = false),
            button(_localizedLabel('TrendLine', '画趋势线', localeTag),
                selected: _isTrendLine,
                onPressed: () => _isTrendLine = !_isTrendLine),
            button(_localizedLabel('Line:MA', '主图:MA', localeTag),
                selected: _mainState == MainState.MA,
                onPressed: () => _mainState = MainState.MA),
            button(_localizedLabel('Line:BOLL', '主图:BOLL', localeTag),
                selected: _mainState == MainState.BOLL,
                onPressed: () => _mainState = MainState.BOLL),
            button(_localizedLabel('Hide Line', '主图:隐藏', localeTag),
                selected: _mainState == MainState.NONE,
                onPressed: () => _mainState = MainState.NONE),
            button(_localizedLabel('Hide Secondary', '清空副图', localeTag),
                selected: _secondaryStates.isEmpty,
                onPressed: () => _secondaryStates.clear()),
            button(
                _volHidden
                    ? _localizedLabel('Show Vol', '显示成交量', localeTag)
                    : _localizedLabel('Hide Vol', '隐藏成交量', localeTag),
                selected: _volHidden,
                onPressed: () => _volHidden = !_volHidden),
            button(
                _hideGrid
                    ? _localizedLabel('Show Grid', '显示网格', localeTag)
                    : _localizedLabel('Hide Grid', '隐藏网格', localeTag),
                selected: _hideGrid,
                onPressed: () => _hideGrid = !_hideGrid),
            button(
                _showNowPrice
                    ? _localizedLabel('Hide Now Price', '隐藏最新价', localeTag)
                    : _localizedLabel('Show Now Price', '显示最新价', localeTag),
                selected: !_showNowPrice,
                onPressed: () => _showNowPrice = !_showNowPrice),
            button(_localizedLabel('Customize UI', '自定义样式', localeTag),
                selected: isChangeUI, onPressed: () {
              isChangeUI = !isChangeUI;
              if (isChangeUI) {
                chartColors.selectBorderColor = Colors.red;
                chartColors.selectFillColor = Colors.red;
                chartColors.lineFillColor = Colors.red;
                chartColors.kLineColor = Colors.yellow;
              } else {
                chartColors.selectBorderColor = const Color(0xff6C7A86);
                chartColors.selectFillColor = const Color(0xff0D1722);
                chartColors.lineFillColor = const Color(0x554C86CD);
                chartColors.kLineColor = const Color(0xff4C86CD);
              }
            }),
            button(_localizedLabel('Toggle Price Label', '切换价位文字', localeTag),
                selected: !_priceLeft, onPressed: () {
              _priceLeft = !_priceLeft;
              _verticalTextAlignment = _priceLeft
                  ? VerticalTextAlignment.left
                  : VerticalTextAlignment.right;
            }),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _localizedLabel('Classic Secondary Indicators', '经典副图', localeTag),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.start,
          children: _buildSecondaryButtons(classicIndicators, localeTag),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _localizedLabel('New Secondary Indicators', '新增副图', localeTag),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.orangeAccent),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.start,
          children: _buildSecondaryButtons(_newIndicatorStates, localeTag),
        ),
      ],
    );
  }

  List<Widget> _buildSecondaryButtons(
      List<SecondaryState> states, String localeTag) {
    return states.map((state) {
      final label = _secondaryStateName(state, localeTag);
      return button(
        label,
        selected: _secondaryStates.contains(state),
        onPressed: () {
          if (_secondaryStates.contains(state)) {
            _secondaryStates.remove(state);
          } else {
            _secondaryStates.add(state);
          }
        },
      );
    }).toList();
  }

  String _secondaryStateName(SecondaryState state, String localeTag) {
    final labels = _secondaryStateDisplayNames[state];
    if (labels == null) {
      return state.toString().split('.').last;
    }
    if (localeTag == 'zh_CN') {
      return labels['zh'] ?? labels['en'] ?? state.toString().split('.').last;
    }
    return labels['en'] ?? state.toString().split('.').last;
  }

  Widget button(String text, {VoidCallback? onPressed, bool selected = false}) {
    final Color backgroundColor = selected ? Colors.orange : Colors.blue;
    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              onPressed();
              setState(() {});
            },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(88, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        ),
        backgroundColor: backgroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.check, size: 16, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(text),
        ],
      ),
    );
  }

  String _localizedLabel(String en, String zh, String localeTag) {
    switch (localeTag) {
      case 'zh_CN':
        return zh;
      case 'es_ES':
        return _spanishLabels[en] ?? en;
      case 'ja_JP':
        return _japaneseLabels[en] ?? en;
      default:
        return en;
    }
  }

  static const Map<String, String> _spanishLabels = {
    'Time Mode': 'Modo tiempo',
    'K Line Mode': 'Modo velas',
    'TrendLine': 'Línea de tendencia',
    'Line:MA': 'Principal: MA',
    'Line:BOLL': 'Principal: BOLL',
    'Hide Line': 'Ocultar principal',
    'Hide Secondary': 'Ocultar secundarios',
    'Show Vol': 'Mostrar volumen',
    'Hide Vol': 'Ocultar volumen',
    'Change Language': 'Cambiar idioma',
    'Hide Grid': 'Ocultar rejilla',
    'Show Grid': 'Mostrar rejilla',
    'Hide Now Price': 'Ocultar precio actual',
    'Show Now Price': 'Mostrar precio actual',
    'Customize UI': 'Personalizar UI',
    'Toggle Price Label': 'Cambiar etiqueta de precio',
    'Language': 'Idioma',
  };

  static const Map<String, String> _japaneseLabels = {
    'Time Mode': '時間足',
    'K Line Mode': 'ローソク足',
    'TrendLine': 'トレンドライン',
    'Line:MA': '主図:MA',
    'Line:BOLL': '主図:BOLL',
    'Hide Line': '主図:非表示',
    'Hide Secondary': '副図を消去',
    'Show Vol': '出来高を表示',
    'Hide Vol': '出来高を隠す',
    'Change Language': '言語を切替',
    'Hide Grid': 'グリッドを隠す',
    'Show Grid': 'グリッドを表示',
    'Hide Now Price': '現在値を隠す',
    'Show Now Price': '現在値を表示',
    'Customize UI': 'UIをカスタム',
    'Toggle Price Label': '価格ラベル切替',
    'Language': '言語',
  };

  String _localeDisplayName(Locale locale) {
    final tag = '${locale.languageCode}_${locale.countryCode}';
    switch (tag) {
      case 'zh_CN':
        return '简体中文';
      case 'es_ES':
        return 'Español';
      case 'ja_JP':
        return '日本語';
      default:
        return 'English';
    }
  }

  Future<void> getData() async {
    try {
      final result = await getChatDataFromJson();
      if (!mounted) return;
      solveChatData(result);
    } catch (error) {
      if (!mounted) {
        debugPrint('Failed to load chart data: $error');
        return;
      }
      setState(() {
        showLoading = false;
      });
      debugPrint('Failed to load chart data: $error');
    }
  }

  //获取火币数据，需要翻墙
  Future<String> getChatDataFromInternet(String? period) async {
    final url =
        'https://api.huobi.br.com/market/history/kline?period=${period ?? '1day'}&size=300&symbol=btcusdt';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception(
        'Failed fetching remote market data (${response.statusCode})');
  }

  // 如果你不能翻墙，可以使用这个方法加载数据
  Future<String> getChatDataFromJson() async {
    return rootBundle.loadString('assets/chatData.json');
  }

  void solveChatData(String result) {
    final Map<String, dynamic> parseJson =
        json.decode(result) as Map<String, dynamic>;
    final rawList = (parseJson['data'] as List<dynamic>)
        .map((item) => KLineEntity.fromJson(item as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
    final parsedData = rawList.cast<KLineEntity>();
    DataUtil.calculate(parsedData);
    if (!mounted) return;
    setState(() {
      datas = parsedData;
      showLoading = false;
    });
  }
}

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
  final List<SecondaryState> _secondaryStates = [SecondaryState.KDJ];
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
    _bids = [];
    _asks = [];
    double amount = 0.0;
    bids.sort((left, right) => left.price.compareTo(right.price));
    // 累加买入委托量
    for (final item in bids.reversed) {
      amount += item.vol;
      item.vol = amount;
      _bids!.insert(0, item);
    }

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    // 累加卖出委托量
    for (final item in asks) {
      amount += item.vol;
      item.vol = amount;
      _asks!.add(item);
    }
    setState(() {});
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
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: <Widget>[
        button(_localizedLabel('Time Mode', '分时', localeTag),
            onPressed: () => isLine = true),
        button(_localizedLabel('K Line Mode', 'K线模式', localeTag),
            onPressed: () => isLine = false),
        button(_localizedLabel('TrendLine', '画趋势线', localeTag),
            onPressed: () => _isTrendLine = !_isTrendLine),
        button(_localizedLabel('Line:MA', '主图:MA', localeTag),
            onPressed: () => _mainState = MainState.MA),
        button(_localizedLabel('Line:BOLL', '主图:BOLL', localeTag),
            onPressed: () => _mainState = MainState.BOLL),
        button(_localizedLabel('Hide Line', '主图:隐藏', localeTag),
            onPressed: () => _mainState = MainState.NONE),
        ...SecondaryState.values.map((state) {
          final label = state.toString().split('.').last;
          return button(label, onPressed: () {
            if (_secondaryStates.contains(state)) {
              _secondaryStates.remove(state); // 取消选中
            } else {
              _secondaryStates.add(state); // 添加选中
            }
          });
        }),
        button(_localizedLabel('Hide Secondary', '清空副图', localeTag),
            onPressed: () => _secondaryStates.clear()),
        button(
            _volHidden
                ? _localizedLabel('Show Vol', '显示成交量', localeTag)
                : _localizedLabel('Hide Vol', '隐藏成交量', localeTag),
            onPressed: () => _volHidden = !_volHidden),
        button(
            _hideGrid
                ? _localizedLabel('Show Grid', '显示网格', localeTag)
                : _localizedLabel('Hide Grid', '隐藏网格', localeTag),
            onPressed: () => _hideGrid = !_hideGrid),
        button(
            _showNowPrice
                ? _localizedLabel('Hide Now Price', '隐藏最新价', localeTag)
                : _localizedLabel('Show Now Price', '显示最新价', localeTag),
            onPressed: () => _showNowPrice = !_showNowPrice),
        button(_localizedLabel('Customize UI', '自定义样式', localeTag),
            onPressed: () {
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
            onPressed: () {
          _priceLeft = !_priceLeft;
          _verticalTextAlignment = _priceLeft
              ? VerticalTextAlignment.left
              : VerticalTextAlignment.right;
        }),
      ],
    );
  }

  Widget button(String text, {VoidCallback? onPressed}) {
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
        backgroundColor: Colors.blue,
      ),
      child: Text(text),
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
      solveChatData(result);
    } catch (error) {
      showLoading = false;
      setState(() {});
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
    final Map parseJson = json.decode(result) as Map<dynamic, dynamic>;
    final list = parseJson['data'] as List<dynamic>;
    datas = list
        .map((item) => KLineEntity.fromJson(item as Map<String, dynamic>))
        .toList()
        .reversed
        .toList()
        .cast<KLineEntity>();
    DataUtil.calculate(datas!);
    showLoading = false;
    setState(() {});
  }
}

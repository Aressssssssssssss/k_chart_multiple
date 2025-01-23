import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:k_chart_multiple/chart_translations.dart';
import 'package:k_chart_multiple/flutter_k_chart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<KLineEntity>? datas;
  bool showLoading = true;
  MainState _mainState = MainState.MA;
  bool _volHidden = false;
  List<SecondaryState> _secondaryStates = [SecondaryState.MACD];
  bool isLine = true;
  bool isChinese = true;
  bool _hideGrid = false;
  bool _showNowPrice = true;
  List<DepthEntity>? _bids, _asks;
  bool isChangeUI = false;
  bool _isTrendLine = false;
  bool _priceLeft = true;
  VerticalTextAlignment _verticalTextAlignment = VerticalTextAlignment.left;

  ChartStyle chartStyle = ChartStyle();
  ChartColors chartColors = ChartColors();

  @override
  void initState() {
    super.initState();
    getData('1day');
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
    //累加买入委托量
    bids.reversed.forEach((item) {
      amount += item.vol;
      item.vol = amount;
      _bids!.insert(0, item);
    });

    amount = 0.0;
    asks.sort((left, right) => left.price.compareTo(right.price));
    //累加卖出委托量
    asks.forEach((item) {
      amount += item.vol;
      item.vol = amount;
      _asks!.add(item);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Stack(children: <Widget>[
          Container(
            height: 450,
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
              translations: kChartTranslations,
              showNowPrice: _showNowPrice,
              //`isChinese` is Deprecated, Use `translations` instead.
              isChinese: isChinese,
              hideGrid: _hideGrid,
              isTapShowInfoDialog: false,
              verticalTextAlignment: _verticalTextAlignment,
              maDayList: [1, 100, 1000],
            ),
          ),
          if (showLoading)
            Container(
                width: double.infinity,
                height: 450,
                alignment: Alignment.center,
                child: const CircularProgressIndicator()),
        ]),
        buildButtons(),
        if (_bids != null && _asks != null)
          Container(
            height: 230,
            width: double.infinity,
            child: DepthChart(_bids!, _asks!, chartColors),
          )
      ],
    );
  }

  Widget buildButtons() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: <Widget>[
        button("Time Mode", onPressed: () => isLine = true),
        button("K Line Mode", onPressed: () => isLine = false),
        button("TrendLine", onPressed: () => _isTrendLine = !_isTrendLine),
        button("Line:MA", onPressed: () => _mainState = MainState.MA),
        button("Line:BOLL", onPressed: () => _mainState = MainState.BOLL),
        button("Hide Line", onPressed: () => _mainState = MainState.NONE),
        button("Secondary Chart:MACD", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.MACD)) {
            _secondaryStates.remove(SecondaryState.MACD); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.MACD); // 添加选中
          }
        }),
        button("KDJ", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.KDJ)) {
            _secondaryStates.remove(SecondaryState.KDJ); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.KDJ); // 添加选中
          }
        }),
        button("RSI", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.RSI)) {
            _secondaryStates.remove(SecondaryState.RSI); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.RSI); // 添加选中
          }
        }),
        button("WR", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.WR)) {
            _secondaryStates.remove(SecondaryState.WR); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.WR); // 添加选中
          }
        }),
        button("CCI", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.CCI)) {
            _secondaryStates.remove(SecondaryState.CCI); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.CCI); // 添加选中
          }
        }),
        button("DMI", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.DMI)) {
            _secondaryStates.remove(SecondaryState.DMI); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.DMI); // 添加选中
          }
        }),
        button("TRIX", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.TRIX)) {
            _secondaryStates.remove(SecondaryState.TRIX); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.TRIX); // 添加选中
          }
        }),
        button("PPO", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.PPO)) {
            _secondaryStates.remove(SecondaryState.PPO); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.PPO); // 添加选中
          }
        }),
        button("TSI", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.TSI)) {
            _secondaryStates.remove(SecondaryState.TSI); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.TSI); // 添加选中
          }
        }),
        button("ICHIMOKU", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.ICHIMOKU)) {
            _secondaryStates.remove(SecondaryState.ICHIMOKU); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.ICHIMOKU); // 添加选中
          }
        }),
        button("SAR", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.SAR)) {
            _secondaryStates.remove(SecondaryState.SAR); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.SAR); // 添加选中
          }
        }),
        button("AROON", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.AROON)) {
            _secondaryStates.remove(SecondaryState.AROON); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.AROON); // 添加选中
          }
        }),
        button("VORTEX", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.VORTEX)) {
            _secondaryStates.remove(SecondaryState.VORTEX); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.VORTEX); // 添加选中
          }
        }),
        button("ATR", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.ATR)) {
            _secondaryStates.remove(SecondaryState.ATR); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.ATR); // 添加选中
          }
        }),
        button("HV", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.HV)) {
            _secondaryStates.remove(SecondaryState.HV); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.HV); // 添加选中
          }
        }),
        button("VWAP", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.VWAP)) {
            _secondaryStates.remove(SecondaryState.VWAP); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.VWAP); // 添加选中
          }
        }),
        button("OBV", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.OBV)) {
            _secondaryStates.remove(SecondaryState.OBV); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.OBV); // 添加选中
          }
        }),
        button("ADL", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.ADL)) {
            _secondaryStates.remove(SecondaryState.ADL); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.ADL); // 添加选中
          }
        }),
        button("VIX", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.VIX)) {
            _secondaryStates.remove(SecondaryState.VIX); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.VIX); // 添加选中
          }
        }),
        button("ADX", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.ADX)) {
            _secondaryStates.remove(SecondaryState.ADX); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.ADX); // 添加选中
          }
        }),
        button("STDDEV", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.STDDEV)) {
            _secondaryStates.remove(SecondaryState.STDDEV); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.STDDEV); // 添加选中
          }
        }),
        button("STOCHASTIC", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.STOCHASTIC)) {
            _secondaryStates.remove(SecondaryState.STOCHASTIC); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.STOCHASTIC); // 添加选中
          }
        }),
        button("WPR", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.WPR)) {
            _secondaryStates.remove(SecondaryState.WPR); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.WPR); // 添加选中
          }
        }),
        button("DEMARKER", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.DEMARKER)) {
            _secondaryStates.remove(SecondaryState.DEMARKER); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.DEMARKER); // 添加选中
          }
        }),
        button("MOMENTUM", onPressed: () {
          if (_secondaryStates.contains(SecondaryState.MOMENTUM)) {
            _secondaryStates.remove(SecondaryState.MOMENTUM); // 取消选中
          } else {
            _secondaryStates.add(SecondaryState.MOMENTUM); // 添加选中
          }
        }),
        button("Secondary Chart:Hide", onPressed: () {
          _secondaryStates.clear();
        }),
        button(_volHidden ? "Show Vol" : "Hide Vol",
            onPressed: () => _volHidden = !_volHidden),
        button("Change Language", onPressed: () => isChinese = !isChinese),
        button(_hideGrid ? "Show Grid" : "Hide Grid",
            onPressed: () => _hideGrid = !_hideGrid),
        button(_showNowPrice ? "Hide Now Price" : "Show Now Price",
            onPressed: () => _showNowPrice = !_showNowPrice),
        button("Customize UI", onPressed: () {
          setState(() {
            this.isChangeUI = !this.isChangeUI;
            if (this.isChangeUI) {
              chartColors.selectBorderColor = Colors.red;
              chartColors.selectFillColor = Colors.red;
              chartColors.lineFillColor = Colors.red;
              chartColors.kLineColor = Colors.yellow;
            } else {
              chartColors.selectBorderColor = Color(0xff6C7A86);
              chartColors.selectFillColor = Color(0xff0D1722);
              chartColors.lineFillColor = Color(0x554C86CD);
              chartColors.kLineColor = Color(0xff4C86CD);
            }
          });
        }),
        button("Change PriceTextPaint",
            onPressed: () => setState(() {
                  _priceLeft = !_priceLeft;
                  if (_priceLeft) {
                    _verticalTextAlignment = VerticalTextAlignment.left;
                  } else {
                    _verticalTextAlignment = VerticalTextAlignment.right;
                  }
                })),
      ],
    );
  }

  Widget button(String text, {VoidCallback? onPressed}) {
    return TextButton(
      onPressed: () {
        if (onPressed != null) {
          onPressed();
          setState(() {});
        }
      },
      child: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(88, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void getData(String period) {
    /*
     * 可以翻墙使用方法1加载数据，不可以翻墙使用方法2加载数据，默认使用方法1加载最新数据
     */
    final Future<String> future = getChatDataFromJson();
    //final Future<String> future = getChatDataFromJson();
    future.then((String result) {
      solveChatData(result);
    }).catchError((_) {
      showLoading = false;
      setState(() {});
      print('### datas error $_');
    });
  }

  //获取火币数据，需要翻墙
  Future<String> getChatDataFromInternet(String? period) async {
    var url =
        'https://api.huobi.br.com/market/history/kline?period=${period ?? '1day'}&size=300&symbol=btcusdt';
    late String result;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      result = response.body;
    } else {
      print('Failed getting IP address');
    }
    return result;
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
